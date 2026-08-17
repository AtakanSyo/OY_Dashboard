import { createClient } from "npm:@supabase/supabase-js@2";
import {
  retrieveCheckout,
  verifyRetrieveSignature,
} from "../_shared/iyzico.ts";

type JsonMap = Record<string, unknown>;

function html(message: string, status = 200) {
  return new Response(
    `<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ödeme Sonucu</title></head><body style="font-family:Arial,sans-serif;display:grid;min-height:100vh;place-items:center;margin:0;background:#f4f7f6;color:#16302e"><main style="max-width:520px;padding:32px;text-align:center;background:white;border-radius:18px;box-shadow:0 10px 30px rgba(0,0,0,.08)"><h1>Optiyou</h1><p>${message}</p></main></body></html>`,
    { status, headers: { "Content-Type": "text/html; charset=utf-8" } },
  );
}

async function tokenFromRequest(req: Request): Promise<string | null> {
  const contentType = req.headers.get("content-type") ?? "";
  if (contentType.includes("application/json")) {
    const body = await req.json() as JsonMap;
    return body.token?.toString().trim() || null;
  }
  const form = await req.formData();
  return form.get("token")?.toString().trim() || null;
}

function decimal(value: unknown): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : Number.NaN;
}

function redirectTarget(
  returnUrl: string | null,
  status: "success" | "failure",
  token: string,
): string | null {
  if (!returnUrl) return null;
  try {
    const url = new URL(returnUrl);
    const route = url.hash.replace(/^#/, "");
    if (route.startsWith("/payment-result")) {
      const routeUrl = new URL(route, url.origin);
      routeUrl.searchParams.set("status", status);
      routeUrl.searchParams.set("token", token);
      url.hash = `#${routeUrl.pathname}${routeUrl.search}`;
    } else {
      url.searchParams.set("status", status);
      url.searchParams.set("token", token);
    }
    return url.toString();
  } catch (_) {
    return null;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return html("Geçersiz istek.", 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  let token: string | null = null;
  let returnUrl: string | null = null;

  try {
    token = await tokenFromRequest(req);
    if (!token) return html("Ödeme anahtarı bulunamadı.", 400);

    const { data: checkout, error: checkoutError } = await admin
      .from("payment_checkout_sessions")
      .select("*")
      .eq("provider_token", token)
      .maybeSingle();
    if (checkoutError) throw checkoutError;
    if (!checkout) return html("Ödeme kaydı bulunamadı.", 404);
    returnUrl = checkout.return_url;

    if (checkout.checkout_status === "paid" && checkout.order_id != null) {
      const target = redirectTarget(returnUrl, "success", token);
      return target
        ? Response.redirect(target, 303)
        : html("Ödemeniz daha önce doğrulandı. Uygulamaya dönebilirsiniz.");
    }

    const providerResponse = await retrieveCheckout(
      token,
      checkout.conversation_id,
    );
    const signatureValid = await verifyRetrieveSignature(providerResponse);
    const amountMatches =
      decimal(providerResponse.price) === decimal(checkout.gross_amount) &&
      decimal(providerResponse.paidPrice) === decimal(checkout.net_amount);
    const contextMatches =
      providerResponse.conversationId === checkout.conversation_id &&
      providerResponse.basketId === checkout.id &&
      providerResponse.currency === checkout.currency_code &&
      providerResponse.token === token;
    const paymentSucceeded =
      providerResponse.status === "success" &&
      providerResponse.paymentStatus === "SUCCESS";

    if (!signatureValid || !amountMatches || !contextMatches || !paymentSucceeded) {
      const reason = !signatureValid
        ? "Payment response signature is invalid."
        : !amountMatches || !contextMatches
        ? "Payment context does not match the checkout."
        : providerResponse.errorMessage?.toString() ?? "Payment failed.";
      await admin.from("payment_checkout_sessions").update({
        checkout_status: "failed",
        provider_response: providerResponse,
        error_code: providerResponse.errorCode?.toString(),
        error_message: reason,
      }).eq("id", checkout.id);
      const target = redirectTarget(returnUrl, "failure", token);
      return target
        ? Response.redirect(target, 303)
        : html("Ödeme tamamlanamadı. Uygulamaya dönerek ayrıntıları görebilirsiniz.", 400);
    }

    const paymentId = providerResponse.paymentId?.toString();
    if (!paymentId) throw new Error("Payment id is missing from iyzico response.");
    const { error: finalizeError } = await admin.rpc("finalize_paid_checkout", {
      p_checkout_id: checkout.id,
      p_provider_payment_id: paymentId,
      p_provider_response: providerResponse,
    });
    if (finalizeError) throw finalizeError;

    const target = redirectTarget(returnUrl, "success", token);
    return target
      ? Response.redirect(target, 303)
      : html("Ödemeniz doğrulandı ve siparişiniz oluşturuldu. Uygulamaya dönebilirsiniz.");
  } catch (error) {
    if (token) {
      await admin.from("payment_checkout_sessions").update({
        error_message: error instanceof Error ? error.message : error?.toString(),
      }).eq("provider_token", token);
    }
    const target = token ? redirectTarget(returnUrl, "failure", token) : null;
    return target
      ? Response.redirect(target, 303)
      : html("Ödeme sonucu doğrulanırken bir hata oluştu. Lütfen uygulamadan tekrar kontrol edin.", 500);
  }
});

import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import {
  getPaymentProduct,
  localizedProductName,
  type PaymentProduct,
} from "../_shared/payment_catalog.ts";
import {
  initializeCheckout,
  iyzicoBuyerIdentityNumber,
  verifyInitializeSignature,
} from "../_shared/iyzico.ts";

type JsonMap = Record<string, unknown>;

function json(body: JsonMap, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function asInteger(value: unknown): number | null {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
}

function safeReturnUrl(value: unknown): string | null {
  if (typeof value !== "string" || value.trim().length === 0) return null;
  try {
    const url = new URL(value);
    if (url.protocol !== "https:" && url.protocol !== "http:") return null;
    const allowedOrigins = (Deno.env.get("PAYMENT_ALLOWED_RETURN_ORIGINS") ?? "")
      .split(",")
      .map((origin) => origin.trim())
      .filter(Boolean);
    if (allowedOrigins.length > 0 && !allowedOrigins.includes(url.origin)) {
      return null;
    }
    return url.toString();
  } catch (_) {
    return null;
  }
}

function phoneNumber(value: unknown): string {
  const raw = value?.toString().trim() ?? "";
  const digits = raw.replace(/\D/g, "");
  if (digits.startsWith("90")) return `+${digits}`;
  if (digits.startsWith("0")) return `+9${digits}`;
  if (digits.length === 10) return `+90${digits}`;
  return raw;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ ok: false, errorMessage: "Method not allowed." }, 405);

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const accessToken = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!accessToken) return json({ ok: false, errorMessage: "Authentication required." }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: authData, error: authError } = await admin.auth.getUser(accessToken);
    if (authError || !authData.user) {
      return json({ ok: false, errorMessage: "Authentication failed." }, 401);
    }
    const authUser = authData.user;
    const body = await req.json() as JsonMap;
    const action = body.action?.toString() ?? "initialize";

    if (action === "status") {
      const token = body.token?.toString().trim();
      if (!token) return json({ ok: false, errorMessage: "Payment token is required." }, 400);
      const { data, error } = await admin
        .from("payment_checkout_sessions")
        .select("checkout_status, order_id, product_name, net_amount, currency_code, error_message, orders(order_no)")
        .eq("auth_user_id", authUser.id)
        .eq("provider_token", token)
        .maybeSingle();
      if (error) throw error;
      if (!data) return json({ ok: false, errorMessage: "Payment record was not found." }, 404);
      const linkedOrder = Array.isArray(data.orders) ? data.orders[0] : data.orders;
      return json({
        ok: true,
        status: data.checkout_status,
        orderId: data.order_id,
        orderNo: linkedOrder?.order_no ?? null,
        productName: data.product_name,
        amount: data.net_amount,
        currency: data.currency_code,
        errorMessage: data.error_message,
      });
    }

    const productId = body.productId?.toString() ?? "";
    const addressId = asInteger(body.addressId);
    const requestedSessionId = asInteger(body.sessionId);
    const locale = body.locale === "en" ? "en" : "tr";
    let product: PaymentProduct | null = getPaymentProduct(productId);
    if (!addressId) return json({ ok: false, errorMessage: "Delivery address is required." }, 400);

    const { data: patient, error: patientError } = await admin
      .from("patients")
      .select("id, clinic_id, created_by_user_id, first_name, last_name, email, phone")
      .eq("auth_user_id", authUser.id)
      .maybeSingle();
    if (patientError) throw patientError;
    if (!patient) return json({ ok: false, errorMessage: "Customer record was not found." }, 400);

    // The database catalog is authoritative. The bundled catalog remains a
    // deployment-safe fallback until migration 024 and this function are live.
    const { data: catalogProduct, error: catalogError } = await admin
      .from("store_products")
      .select("id, title, base_price, currency_code, is_add_on, is_active")
      .eq("id", productId)
      .eq("is_active", true)
      .maybeSingle();
    if (catalogError && catalogError.code !== "42P01") throw catalogError;
    if (catalogProduct) {
      const { data: clinicPrice, error: clinicPriceError } = await admin
        .from("store_product_clinic_prices")
        .select("price")
        .eq("product_id", productId)
        .eq("clinic_id", patient.clinic_id)
        .maybeSingle();
      if (clinicPriceError && clinicPriceError.code !== "42P01") throw clinicPriceError;
      product = {
        id: catalogProduct.id,
        nameTr: catalogProduct.title,
        nameEn: catalogProduct.title,
        productType: catalogProduct.id.replaceAll("-", "_"),
        price: Number(clinicPrice?.price ?? catalogProduct.base_price),
        currency: "TRY",
        category: catalogProduct.is_add_on ? "Tamamlayıcı Ürünler" : "Kişiselleştirilmiş Ürünler",
      };
    }
    if (!product) return json({ ok: false, errorMessage: "Product is not available." }, 400);

    const { data: profile } = await admin
      .from("user_profiles")
      .select("id")
      .eq("auth_id", authUser.id)
      .maybeSingle();
    const { data: address, error: addressError } = await admin
      .from("customer_addresses")
      .select("id, user_id, patient_id, title, full_name, phone, city, district, address_line")
      .eq("id", addressId)
      .maybeSingle();
    if (addressError) throw addressError;
    const ownsAddress = address && (
      address.patient_id === patient.id ||
      (profile?.id != null && address.user_id === profile.id)
    );
    if (!ownsAddress) return json({ ok: false, errorMessage: "Delivery address is invalid." }, 403);

    let sessionQuery = admin
      .from("measurement_sessions")
      .select("id, clinic_id, expert_user_id")
      .eq("patient_id", patient.id);
    if (requestedSessionId) sessionQuery = sessionQuery.eq("id", requestedSessionId);
    const { data: sessions, error: sessionError } = await sessionQuery
      .order("session_date", { ascending: false })
      .limit(1);
    if (sessionError) throw sessionError;
    const session = sessions?.[0];
    if (!session) return json({ ok: false, errorMessage: "A measurement session is required for this order." }, 400);

    const checkoutId = crypto.randomUUID();
    const conversationId = `OY-${checkoutId}`;
    const returnUrl = safeReturnUrl(body.returnUrl) ??
      safeReturnUrl(Deno.env.get("PAYMENT_RETURN_URL"));
    const addressSnapshot = {
      title: address.title,
      full_name: address.full_name,
      phone: address.phone,
      city: address.city,
      district: address.district,
      address_line: address.address_line,
    };
    const productName = localizedProductName(product, locale);
    const contactName = address.full_name?.toString().trim() ||
      `${patient.first_name} ${patient.last_name}`.trim();
    const buyerEmail = patient.email?.toString().trim() || authUser.email || "";
    const buyerPhone = phoneNumber(patient.phone || address.phone);
    if (!buyerEmail || !buyerPhone) {
      return json({
        ok: false,
        errorMessage: "Customer email and phone are required for payment.",
      }, 400);
    }
    const buyerIdentityNumber = iyzicoBuyerIdentityNumber();
    const { error: checkoutInsertError } = await admin
      .from("payment_checkout_sessions")
      .insert({
        id: checkoutId,
        auth_user_id: authUser.id,
        patient_id: patient.id,
        session_id: session.id,
        address_id: address.id,
        clinic_id: session.clinic_id ?? patient.clinic_id,
        expert_user_id: session.expert_user_id ?? patient.created_by_user_id,
        address_snapshot: addressSnapshot,
        product_id: product.id,
        product_name: productName,
        product_type: product.productType,
        currency_code: product.currency,
        gross_amount: product.price,
        discount_amount: 0,
        net_amount: product.price,
        conversation_id: conversationId,
        return_url: returnUrl,
      });
    if (checkoutInsertError) throw checkoutInsertError;

    const callbackUrl = `${supabaseUrl}/functions/v1/iyzico-callback`;
    const clientIp = (req.headers.get("x-forwarded-for") ?? "127.0.0.1")
      .split(",")[0].trim();
    const fullAddress = `${address.address_line}, ${address.district}/${address.city}`;
    const iyzicoResponse = await initializeCheckout({
      locale,
      conversationId,
      price: product.price,
      paidPrice: product.price,
      currency: product.currency,
      basketId: checkoutId,
      paymentGroup: "PRODUCT",
      callbackUrl,
      enabledInstallments: [1, 2, 3, 6, 9],
      buyer: {
        id: patient.id.toString(),
        name: patient.first_name,
        surname: patient.last_name,
        identityNumber: buyerIdentityNumber,
        email: buyerEmail,
        gsmNumber: buyerPhone,
        registrationAddress: fullAddress,
        city: address.city,
        country: "Turkey",
        ip: clientIp,
      },
      shippingAddress: {
        address: fullAddress,
        contactName,
        city: address.city,
        country: "Turkey",
      },
      billingAddress: {
        address: fullAddress,
        contactName,
        city: address.city,
        country: "Turkey",
      },
      basketItems: [{
        id: product.id,
        price: product.price,
        name: productName,
        category1: product.category,
        itemType: "PHYSICAL",
      }],
    });

    const providerToken = iyzicoResponse.token?.toString();
    const paymentPageUrl = iyzicoResponse.paymentPageUrl?.toString();
    const signatureValid = await verifyInitializeSignature(iyzicoResponse);
    if (
      iyzicoResponse.status !== "success" ||
      !providerToken ||
      !paymentPageUrl ||
      !signatureValid
    ) {
      await admin.from("payment_checkout_sessions").update({
        checkout_status: "failed",
        provider_response: iyzicoResponse,
        error_code: iyzicoResponse.errorCode?.toString(),
        error_message: !signatureValid
          ? "Payment initialization signature is invalid."
          : iyzicoResponse.errorMessage?.toString() ?? "Payment could not be initialized.",
      }).eq("id", checkoutId);
      return json({
        ok: false,
        errorCode: iyzicoResponse.errorCode,
        errorMessage: !signatureValid
          ? "Payment response could not be verified."
          : iyzicoResponse.errorMessage ?? "Payment could not be initialized.",
      }, 400);
    }

    await admin.from("payment_checkout_sessions").update({
      checkout_status: "initialized",
      provider_token: providerToken,
      provider_response: iyzicoResponse,
    }).eq("id", checkoutId);

    return json({
      ok: true,
      status: "initialized",
      checkoutId,
      conversationId,
      token: providerToken,
      paymentPageUrl,
      amount: product.price,
      currency: product.currency,
    });
  } catch (error) {
    return json({
      ok: false,
      errorMessage: error instanceof Error ? error.message : error?.toString(),
    }, 500);
  }
});

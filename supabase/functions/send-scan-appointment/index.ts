import { corsHeaders } from "../_shared/cors.ts";

// "Tarama Yap" akışının e-posta gönderimi.
//
// Bireysel randevu ve kurumsal talep için OPTIYOU gelen kutusuna (info) bilgi
// e-postası, talep sahibine ise KVKK aydınlatma + özet e-postası gider.
// send-patient-consent-email ile aynı Resend deseni kullanılır.

const OPTIYOU_INBOX = "info@optiyou.com.tr";
const FROM_ADDRESS = "Optiyou <no-reply@optiyou.fit>";
const KVKK_URL = "https://optiyou.fit/kvkk";

const LOCATION_LABELS: Record<string, string> = {
  LLT: "LiveLifeTaller — Kartal, İstanbul",
  IZTU_DML: "İZTÜ DML — Buca, İzmir",
  OPTIYOU: "Alsancak, İzmir",
};

const REQUEST_TYPE_LABELS: Record<string, string> = {
  scanner_purchase: "Tarayıcı sistem satın alma",
  b2b_service: "B2B tarama hizmeti",
};

interface IndividualPayload {
  full_name: string;
  phone: string;
  email: string;
  location: string;
  appointment_date: string;
  appointment_time: string;
  note?: string;
}

interface CorporatePayload {
  company_name: string;
  contact_name: string;
  email: string;
  phone: string;
  person_count: number;
  request_type: string;
  note?: string;
}

interface RequestBody {
  kind: "individual" | "corporate";
  payload: IndividualPayload | CorporatePayload;
}

function esc(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function shell(title: string, bodyRows: string): string {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; color: #1f2937;">
      <h2 style="color: #0f766e;">${esc(title)}</h2>
      <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
        ${bodyRows}
      </table>
    </div>
  `;
}

function row(label: string, value: string): string {
  return `
    <tr>
      <td style="padding: 8px 12px 8px 0; color: #6b7280; white-space: nowrap; vertical-align: top;">${esc(label)}</td>
      <td style="padding: 8px 0; font-weight: 600;">${esc(value)}</td>
    </tr>
  `;
}

function kvkkNotice(): string {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 24px auto 0; color: #6b7280; font-size: 13px; line-height: 1.6;">
      <p style="margin: 0 0 8px;">
        Talebiniz kapsamında paylaştığınız iletişim bilgileri yalnızca randevu
        ve tarama sürecinin yürütülmesi amacıyla işlenir. Ayrıntılar için KVKK
        Aydınlatma Metni'ni inceleyebilirsiniz:
      </p>
      <p style="margin: 0;">
        <a href="${KVKK_URL}" style="color: #0f766e;">${KVKK_URL}</a>
      </p>
    </div>
  `;
}

function buildIndividualEmails(p: IndividualPayload) {
  const locationLabel = LOCATION_LABELS[p.location] ?? p.location;
  const rows =
    row("Ad Soyad", p.full_name) +
    row("Telefon", p.phone) +
    row("E-posta", p.email) +
    row("Lokasyon", locationLabel) +
    row("Tarih", p.appointment_date) +
    row("Saat", p.appointment_time) +
    (p.note ? row("Not", p.note) : "");

  return {
    inbox: {
      subject: `Yeni tarama randevusu — ${locationLabel} · ${p.appointment_date} ${p.appointment_time}`,
      html: shell("Yeni Tarama Randevusu Talebi", rows),
    },
    applicant: {
      subject: "Tarama randevunuz alındı — Optiyou",
      html:
        shell(
          "Tarama Randevunuz Alındı",
          row("Lokasyon", locationLabel) +
            row("Tarih", p.appointment_date) +
            row("Saat", p.appointment_time),
        ) +
        `<div style="font-family: Arial, sans-serif; max-width: 560px; margin: 16px auto 0; color: #1f2937; font-size: 14px;">
           <p>Randevu talebiniz ekibimize iletildi. Lokasyon ve saat onayı için sizinle iletişime geçeceğiz.</p>
         </div>` +
        kvkkNotice(),
    },
  };
}

function buildCorporateEmails(p: CorporatePayload) {
  const typeLabel = REQUEST_TYPE_LABELS[p.request_type] ?? p.request_type;
  const rows =
    row("Şirket", p.company_name) +
    row("Yetkili", p.contact_name) +
    row("E-posta", p.email) +
    row("Telefon", p.phone) +
    row("Kişi sayısı", String(p.person_count)) +
    row("Talep türü", typeLabel) +
    (p.note ? row("Not", p.note) : "");

  return {
    inbox: {
      subject: `Kurumsal tarama talebi — ${p.company_name} (${typeLabel})`,
      html: shell("Kurumsal Tarama Talebi", rows),
    },
    applicant: {
      subject: "Kurumsal tarama talebiniz alındı — Optiyou",
      html:
        shell(
          "Talebiniz Alındı",
          row("Şirket", p.company_name) +
            row("Talep türü", typeLabel) +
            row("Kişi sayısı", String(p.person_count)),
        ) +
        `<div style="font-family: Arial, sans-serif; max-width: 560px; margin: 16px auto 0; color: #1f2937; font-size: 14px;">
           <p>Talebiniz ekibimize iletildi. En kısa sürede sizinle iletişime geçeceğiz.</p>
         </div>` +
        kvkkNotice(),
    },
  };
}

async function sendEmail(
  apiKey: string,
  to: string,
  subject: string,
  html: string,
): Promise<void> {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from: FROM_ADDRESS, to: [to], subject, html }),
  });

  if (!res.ok) {
    throw new Error(`Resend ${res.status}: ${await res.text()}`);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  try {
    const body = (await req.json()) as RequestBody;

    if (body.kind !== "individual" && body.kind !== "corporate") {
      return json({ success: false, error: "Geçersiz kind." }, 400);
    }
    if (!body.payload || typeof body.payload !== "object") {
      return json({ success: false, error: "payload zorunludur." }, 400);
    }

    const apiKey = Deno.env.get("RESEND_API_KEY");
    if (!apiKey) {
      return json({ success: false, error: "RESEND_API_KEY tanımlı değil." }, 500);
    }

    const emails =
      body.kind === "individual"
        ? buildIndividualEmails(body.payload as IndividualPayload)
        : buildCorporateEmails(body.payload as CorporatePayload);

    const applicantEmail = (body.payload as { email?: string }).email;

    await sendEmail(
      apiKey,
      OPTIYOU_INBOX,
      emails.inbox.subject,
      emails.inbox.html,
    );

    if (applicantEmail) {
      await sendEmail(
        apiKey,
        applicantEmail,
        emails.applicant.subject,
        emails.applicant.html,
      );
    }

    return json({ success: true });
  } catch (error) {
    return json({ success: false, error: String(error) }, 500);
  }
});

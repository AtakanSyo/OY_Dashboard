import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.57.4";

// Dashboard "Via Editor" dağıtımı tek dosya kullandığı için CORS başlıkları
// burada tutulur. Aynı dosya CLI ile de doğrudan deploy edilebilir.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const OPTIYOU_INBOX = Deno.env.get("OPTIYOU_INBOX") ??
  "info@optiyou.com.tr";
const FROM_ADDRESS = Deno.env.get("SCAN_FROM_ADDRESS") ??
  "Optiyou <no-reply@optiyou.fit>";
const KVKK_URL = "https://optiyou.fit/kvkk";
const RATE_LIMIT_WINDOW_MINUTES = 15;
const RATE_LIMIT_PER_SOURCE = 5;
const RATE_LIMIT_PER_EMAIL = 3;

const LOCATION_LABELS: Record<string, string> = {
  LLT: "LiveLifeTaller — Kartal, İstanbul",
  IZTU_DML: "İZTÜ DML — Buca, İzmir",
  OPTIYOU: "Alsancak, İzmir",
};

const REQUEST_TYPE_LABELS: Record<string, string> = {
  scanner_purchase: "Tarayıcı sistem satın alma",
  b2b_service: "B2B tarama hizmeti",
};

type RequestKind = "individual" | "corporate";

interface IndividualPayload {
  client_request_id: string;
  full_name: string;
  phone: string;
  email: string;
  location: string;
  appointment_date: string;
  appointment_time: string;
  privacy_notice_acknowledged: true;
  note?: string;
}

interface CorporatePayload {
  client_request_id: string;
  company_name: string;
  contact_name: string;
  email: string;
  phone: string;
  person_count: number;
  request_type: string;
  privacy_notice_acknowledged: true;
  note?: string;
}

interface RequestBody {
  kind?: unknown;
  payload?: unknown;
}

interface StoredRequest {
  id: string;
  email_dispatched: boolean;
  email_status: "pending" | "sent" | "failed";
}

class PublicError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

function json(
  body: Record<string, unknown>,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      ...extraHeaders,
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
}

function namedKeys(variable: string): string[] {
  const raw = Deno.env.get(variable);
  if (!raw) return [];
  const parsed = JSON.parse(raw) as Record<string, unknown>;
  return Object.values(parsed).filter(
    (value): value is string => typeof value === "string" && value.length > 0,
  );
}

function authorizePublicRequest(req: Request): void {
  const allowedKeys = [
    ...namedKeys("SUPABASE_PUBLISHABLE_KEYS"),
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY"),
    Deno.env.get("SUPABASE_ANON_KEY"),
  ].filter((value): value is string => Boolean(value));
  if (allowedKeys.length === 0) {
    throw new Error("Supabase public keys are not configured.");
  }

  const presentedKey = req.headers.get("apikey")?.trim();
  if (!presentedKey || !allowedKeys.includes(presentedKey)) {
    throw new PublicError(401, "Yetkisiz istek.");
  }
}

function textField(
  source: Record<string, unknown>,
  key: string,
  min: number,
  max: number,
): string {
  const value = typeof source[key] === "string" ? source[key].trim() : "";
  if (value.length < min || value.length > max) {
    throw new PublicError(400, `${key} alanı geçersiz.`);
  }
  if (
    /^[\s\S]*[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F][\s\S]*$/.test(value)
  ) {
    throw new PublicError(400, `${key} alanı geçersiz karakter içeriyor.`);
  }
  return value;
}

function optionalNote(source: Record<string, unknown>): string | undefined {
  if (source.note == null || source.note === "") return undefined;
  return textField(source, "note", 1, 1000);
}

function normalizedEmail(source: Record<string, unknown>): string {
  const email = textField(source, "email", 3, 320).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new PublicError(400, "Geçerli bir e-posta adresi girin.");
  }
  return email;
}

function normalizedPhone(source: Record<string, unknown>): string {
  const phone = textField(source, "phone", 10, 32);
  const digits = phone.replace(/\D/g, "");
  if (digits.length < 10 || digits.length > 15) {
    throw new PublicError(400, "Geçerli bir telefon numarası girin.");
  }
  return phone;
}

function requestId(source: Record<string, unknown>): string {
  const value = textField(source, "client_request_id", 36, 36).toLowerCase();
  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
      .test(
        value,
      )
  ) {
    throw new PublicError(400, "İstek kimliği geçersiz.");
  }
  return value;
}

function requirePrivacyNotice(source: Record<string, unknown>): true {
  if (source.privacy_notice_acknowledged !== true) {
    throw new PublicError(
      400,
      "KVKK Aydınlatma Metni okunmadan talep gönderilemez.",
    );
  }
  return true;
}

function todayInIstanbul(): string {
  return new Intl.DateTimeFormat("sv-SE", {
    timeZone: "Europe/Istanbul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

function validateAppointmentDate(value: unknown): string {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new PublicError(400, "Randevu tarihi geçersiz.");
  }
  const parsed = new Date(`${value}T00:00:00Z`);
  if (
    Number.isNaN(parsed.valueOf()) ||
    parsed.toISOString().slice(0, 10) !== value
  ) {
    throw new PublicError(400, "Randevu tarihi geçersiz.");
  }
  const today = todayInIstanbul();
  const latest = new Date(`${today}T00:00:00Z`);
  latest.setUTCDate(latest.getUTCDate() + 120);
  if (value < today || value > latest.toISOString().slice(0, 10)) {
    throw new PublicError(400, "Randevu tarihi izin verilen aralıkta değil.");
  }
  return value;
}

function validateAppointmentTime(value: unknown): string {
  if (typeof value !== "string") {
    throw new PublicError(400, "Randevu saati geçersiz.");
  }
  const allowed = new Set<string>();
  for (let minutes = 11 * 60; minutes <= 16 * 60 + 45; minutes += 15) {
    const hour = String(Math.floor(minutes / 60)).padStart(2, "0");
    const minute = String(minutes % 60).padStart(2, "0");
    allowed.add(`${hour}:${minute}`);
  }
  if (!allowed.has(value)) {
    throw new PublicError(400, "Randevu saati geçersiz.");
  }
  return value;
}

function validateIndividual(source: unknown): IndividualPayload {
  if (!source || typeof source !== "object" || Array.isArray(source)) {
    throw new PublicError(400, "Form verileri eksik.");
  }
  const value = source as Record<string, unknown>;
  const location = textField(value, "location", 3, 16);
  if (!(location in LOCATION_LABELS)) {
    throw new PublicError(400, "Tarama lokasyonu geçersiz.");
  }
  return {
    client_request_id: requestId(value),
    full_name: textField(value, "full_name", 2, 120),
    phone: normalizedPhone(value),
    email: normalizedEmail(value),
    location,
    appointment_date: validateAppointmentDate(value.appointment_date),
    appointment_time: validateAppointmentTime(value.appointment_time),
    privacy_notice_acknowledged: requirePrivacyNotice(value),
    note: optionalNote(value),
  };
}

function validateCorporate(source: unknown): CorporatePayload {
  if (!source || typeof source !== "object" || Array.isArray(source)) {
    throw new PublicError(400, "Form verileri eksik.");
  }
  const value = source as Record<string, unknown>;
  const requestType = textField(value, "request_type", 3, 32);
  if (!(requestType in REQUEST_TYPE_LABELS)) {
    throw new PublicError(400, "Kurumsal talep türü geçersiz.");
  }
  const personCount = Number(value.person_count);
  if (
    !Number.isInteger(personCount) || personCount < 1 || personCount > 100000
  ) {
    throw new PublicError(400, "Kişi sayısı geçersiz.");
  }
  return {
    client_request_id: requestId(value),
    company_name: textField(value, "company_name", 2, 160),
    contact_name: textField(value, "contact_name", 2, 120),
    email: normalizedEmail(value),
    phone: normalizedPhone(value),
    person_count: personCount,
    request_type: requestType,
    privacy_notice_acknowledged: requirePrivacyNotice(value),
    note: optionalNote(value),
  };
}

function esc(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
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
      <td style="padding: 8px 12px 8px 0; color: #6b7280; white-space: nowrap; vertical-align: top;">${
    esc(label)
  }</td>
      <td style="padding: 8px 0; font-weight: 600;">${esc(value)}</td>
    </tr>
  `;
}

function kvkkNotice(): string {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 24px auto 0; color: #6b7280; font-size: 13px; line-height: 1.6;">
      <p style="margin: 0 0 8px;">
        Talebiniz kapsamında paylaştığınız iletişim bilgileri randevu ve tarama
        sürecinin yürütülmesi amacıyla işlenir. Ayrıntılar için KVKK
        Aydınlatma Metni'ni inceleyebilirsiniz:
      </p>
      <p style="margin: 0;"><a href="${KVKK_URL}" style="color: #0f766e;">${KVKK_URL}</a></p>
    </div>
  `;
}

function buildIndividualEmails(payload: IndividualPayload) {
  const locationLabel = LOCATION_LABELS[payload.location];
  const rows = row("Ad Soyad", payload.full_name) +
    row("Telefon", payload.phone) +
    row("E-posta", payload.email) +
    row("Lokasyon", locationLabel) +
    row("Tarih", payload.appointment_date) +
    row("Saat", payload.appointment_time) +
    (payload.note ? row("Not", payload.note) : "");

  return {
    inbox: {
      subject:
        `Yeni tarama randevusu — ${locationLabel} · ${payload.appointment_date} ${payload.appointment_time}`,
      html: shell("Yeni Tarama Randevusu Talebi", rows),
    },
    applicant: {
      subject: "Tarama randevunuz alındı — Optiyou",
      html: shell(
        "Tarama Randevunuz Alındı",
        row("Lokasyon", locationLabel) +
          row("Tarih", payload.appointment_date) +
          row("Saat", payload.appointment_time),
      ) +
        `<div style="font-family: Arial, sans-serif; max-width: 560px; margin: 16px auto 0; color: #1f2937; font-size: 14px;">
           <p>Randevu talebiniz ekibimize iletildi. Lokasyon ve saat onayı için sizinle iletişime geçeceğiz.</p>
         </div>` +
        kvkkNotice(),
    },
  };
}

function buildCorporateEmails(payload: CorporatePayload) {
  const typeLabel = REQUEST_TYPE_LABELS[payload.request_type];
  const rows = row("Şirket", payload.company_name) +
    row("Yetkili", payload.contact_name) +
    row("E-posta", payload.email) +
    row("Telefon", payload.phone) +
    row("Kişi sayısı", String(payload.person_count)) +
    row("Talep türü", typeLabel) +
    (payload.note ? row("Not", payload.note) : "");

  return {
    inbox: {
      subject:
        `Kurumsal tarama talebi — ${payload.company_name} (${typeLabel})`,
      html: shell("Kurumsal Tarama Talebi", rows),
    },
    applicant: {
      subject: "Kurumsal tarama talebiniz alındı — Optiyou",
      html: shell(
        "Talebiniz Alındı",
        row("Şirket", payload.company_name) +
          row("Talep türü", typeLabel) +
          row("Kişi sayısı", String(payload.person_count)),
      ) +
        `<div style="font-family: Arial, sans-serif; max-width: 560px; margin: 16px auto 0; color: #1f2937; font-size: 14px;">
           <p>Talebiniz ekibimize iletildi. En kısa sürede sizinle iletişime geçeceğiz.</p>
         </div>` +
        kvkkNotice(),
    },
  };
}

function adminKey(): string {
  const currentKeys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (currentKeys) {
    try {
      const parsed = JSON.parse(currentKeys) as Record<string, string>;
      const key = parsed.default ?? Object.values(parsed)[0];
      if (key) return key;
    } catch {
      // Legacy key fallback below.
    }
  }
  const legacyKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!legacyKey) throw new Error("Supabase server key is not configured.");
  return legacyKey;
}

function adminClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  if (!url) throw new Error("SUPABASE_URL is not configured.");
  return createClient(url, adminKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function clientAddress(req: Request): string {
  const cloudflare = req.headers.get("cf-connecting-ip")?.trim();
  if (cloudflare) return cloudflare;
  const forwarded = req.headers.get("x-forwarded-for")
    ?.split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  return forwarded?.at(-1) ?? "unknown";
}

async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((item) => item.toString(16).padStart(2, "0"))
    .join("");
}

async function sourceHash(req: Request): Promise<string> {
  const salt = Deno.env.get("SCAN_RATE_LIMIT_SALT");
  if (!salt || salt.length < 32) {
    throw new Error(
      "SCAN_RATE_LIMIT_SALT must contain at least 32 characters.",
    );
  }
  return sha256(`${salt}:${clientAddress(req)}`);
}

async function findExisting(
  client: SupabaseClient,
  table: string,
  clientRequestId: string,
): Promise<StoredRequest | null> {
  const { data, error } = await client
    .from(table)
    .select("id,email_dispatched,email_status")
    .eq("client_request_id", clientRequestId)
    .maybeSingle();
  if (error) throw error;
  return data as StoredRequest | null;
}

async function enforceRateLimit(
  client: SupabaseClient,
  table: string,
  hash: string,
  email: string,
): Promise<void> {
  const since = new Date(
    Date.now() - RATE_LIMIT_WINDOW_MINUTES * 60 * 1000,
  ).toISOString();
  const [sourceResult, emailResult] = await Promise.all([
    client
      .from(table)
      .select("id", { count: "exact", head: true })
      .eq("request_source_hash", hash)
      .gte("created_at", since),
    client
      .from(table)
      .select("id", { count: "exact", head: true })
      .eq("email", email)
      .gte("created_at", since),
  ]);
  if (sourceResult.error) throw sourceResult.error;
  if (emailResult.error) throw emailResult.error;
  if (
    (sourceResult.count ?? 0) >= RATE_LIMIT_PER_SOURCE ||
    (emailResult.count ?? 0) >= RATE_LIMIT_PER_EMAIL
  ) {
    throw new PublicError(
      429,
      "Çok kısa sürede çok sayıda talep gönderildi. Lütfen 15 dakika sonra tekrar deneyin.",
    );
  }
}

async function sendEmail(
  apiKey: string,
  to: string,
  subject: string,
  html: string,
): Promise<void> {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from: FROM_ADDRESS, to: [to], subject, html }),
  });
  if (!response.ok) {
    throw new Error(`Resend ${response.status}: ${await response.text()}`);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ success: false, message: "Yöntem desteklenmiyor." }, 405);
  }

  try {
    authorizePublicRequest(req);
    const body = (await req.json()) as RequestBody;
    if (body.kind !== "individual" && body.kind !== "corporate") {
      throw new PublicError(400, "Talep türü geçersiz.");
    }

    const kind = body.kind as RequestKind;
    const payload = kind === "individual"
      ? validateIndividual(body.payload)
      : validateCorporate(body.payload);
    const table = kind === "individual"
      ? "scan_appointment_requests"
      : "corporate_scan_requests";
    const client = adminClient();

    const existing = await findExisting(
      client,
      table,
      payload.client_request_id,
    );
    if (existing) {
      return json({
        success: true,
        request_id: existing.id,
        email_dispatched: existing.email_dispatched,
        duplicate: true,
      });
    }

    const hash = await sourceHash(req);
    await enforceRateLimit(client, table, hash, payload.email);

    const { data: inserted, error: insertError } = await client
      .from(table)
      .insert({
        ...payload,
        request_source_hash: hash,
        email_status: "pending",
      })
      .select("id")
      .single();

    if (insertError) {
      if (insertError.code === "23505") {
        const duplicate = await findExisting(
          client,
          table,
          payload.client_request_id,
        );
        if (duplicate) {
          return json({
            success: true,
            request_id: duplicate.id,
            email_dispatched: duplicate.email_dispatched,
            duplicate: true,
          });
        }
      }
      throw insertError;
    }

    const requestId = inserted.id as string;
    const emails = kind === "individual"
      ? buildIndividualEmails(payload as IndividualPayload)
      : buildCorporateEmails(payload as CorporatePayload);

    try {
      const apiKey = Deno.env.get("RESEND_API_KEY");
      if (!apiKey) throw new Error("RESEND_API_KEY is not configured.");
      await sendEmail(
        apiKey,
        OPTIYOU_INBOX,
        emails.inbox.subject,
        emails.inbox.html,
      );
      await sendEmail(
        apiKey,
        payload.email,
        emails.applicant.subject,
        emails.applicant.html,
      );
      const { error: updateError } = await client
        .from(table)
        .update({
          email_dispatched: true,
          email_status: "sent",
          email_attempted_at: new Date().toISOString(),
          email_dispatch_error: null,
        })
        .eq("id", requestId);
      if (updateError) throw updateError;
      return json({
        success: true,
        request_id: requestId,
        email_dispatched: true,
        duplicate: false,
      });
    } catch (emailError) {
      const message = String(emailError).slice(0, 500);
      const { error: updateError } = await client
        .from(table)
        .update({
          email_dispatched: false,
          email_status: "failed",
          email_attempted_at: new Date().toISOString(),
          email_dispatch_error: message,
        })
        .eq("id", requestId);
      if (updateError) console.error("scan-request-status-update-failed");
      console.error("scan-request-email-failed");
      return json({
        success: true,
        request_id: requestId,
        email_dispatched: false,
        duplicate: false,
      });
    }
  } catch (error) {
    if (error instanceof PublicError) {
      return json(
        { success: false, message: error.message },
        error.status,
        error.status === 429 ? { "Retry-After": "900" } : {},
      );
    }
    console.error("scan-request-unexpected-error");
    return json(
      {
        success: false,
        message: "Talep servisi geçici olarak kullanılamıyor.",
      },
      500,
    );
  }
});

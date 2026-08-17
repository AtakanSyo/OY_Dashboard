const initializePath = "/payment/iyzipos/checkoutform/initialize/auth/ecom";
const retrievePath = "/payment/iyzipos/checkoutform/auth/ecom/detail";

function environment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`${name} is not configured.`);
  return value;
}

function iyzicoBaseUrl(): string {
  return (Deno.env.get("IYZICO_BASE_URL") ?? "https://sandbox-api.iyzipay.com")
    .replace(/\/$/, "");
}

async function hmacHex(value: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(value));
  return Array.from(new Uint8Array(signature))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function base64(value: string): string {
  const bytes = new TextEncoder().encode(value);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

async function authorization(path: string, body: string) {
  const apiKey = environment("IYZICO_API_KEY");
  const secretKey = environment("IYZICO_SECRET_KEY");
  const randomKey = `${Date.now()}${crypto.randomUUID().replaceAll("-", "")}`;
  const signature = await hmacHex(`${randomKey}${path}${body}`, secretKey);
  const encoded = base64(
    `apiKey:${apiKey}&randomKey:${randomKey}&signature:${signature}`,
  );
  return {
    authorization: `IYZWSv2 ${encoded}`,
    randomKey,
  };
}

async function post(path: string, payload: Record<string, unknown>) {
  const body = JSON.stringify(payload);
  const auth = await authorization(path, body);
  const response = await fetch(`${iyzicoBaseUrl()}${path}`, {
    method: "POST",
    headers: {
      Authorization: auth.authorization,
      "x-iyzi-rnd": auth.randomKey,
      "Content-Type": "application/json",
    },
    body,
  });
  const text = await response.text();
  let data: Record<string, unknown>;
  try {
    data = JSON.parse(text);
  } catch (_) {
    throw new Error(`iyzico returned an invalid response (${response.status}).`);
  }
  if (!response.ok) {
    throw new Error(
      data.errorMessage?.toString() ?? `iyzico request failed (${response.status}).`,
    );
  }
  return data;
}

export function isIyzicoSandbox(): boolean {
  return iyzicoBaseUrl().includes("sandbox");
}

export function iyzicoBuyerIdentityNumber(): string {
  const configured = Deno.env.get("IYZICO_BUYER_IDENTITY_NUMBER")?.trim();
  if (configured) return configured;
  if (isIyzicoSandbox()) return "11111111111";
  throw new Error("IYZICO_BUYER_IDENTITY_NUMBER is required in production.");
}

export function initializeCheckout(payload: Record<string, unknown>) {
  return post(initializePath, payload);
}

export async function verifyInitializeSignature(
  response: Record<string, unknown>,
): Promise<boolean> {
  return verifyResponseSignature(response, [
    response.conversationId,
    response.token,
  ]);
}

export function retrieveCheckout(token: string, conversationId: string) {
  return post(retrievePath, {
    locale: "tr",
    conversationId,
    token,
  });
}

function normalizedDecimal(value: unknown): string {
  const raw = value?.toString() ?? "";
  if (!raw.includes(".")) return raw;
  return raw.replace(/0+$/, "").replace(/\.$/, "");
}

export async function verifyRetrieveSignature(
  response: Record<string, unknown>,
): Promise<boolean> {
  const values = [
    response.paymentStatus,
    response.paymentId,
    response.currency,
    response.basketId,
    response.conversationId,
    normalizedDecimal(response.paidPrice),
    normalizedDecimal(response.price),
    response.token,
  ];
  return verifyResponseSignature(response, values);
}

async function verifyResponseSignature(
  response: Record<string, unknown>,
  values: unknown[],
): Promise<boolean> {
  const signature = response.signature?.toString().toLowerCase();
  if (!signature) return false;
  const expected = await hmacHex(
    values.map((value) => value?.toString() ?? "").join(":"),
    environment("IYZICO_SECRET_KEY"),
  );
  if (expected.length !== signature.length) return false;
  let difference = 0;
  for (let index = 0; index < expected.length; index += 1) {
    difference |= expected.charCodeAt(index) ^ signature.charCodeAt(index);
  }
  return difference === 0;
}

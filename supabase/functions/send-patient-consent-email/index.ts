import { corsHeaders } from "../_shared/cors.ts";

interface RequestBody {
  email: string;
  patient_name?: string;
  consent_link: string;
  token: string;
  request_id?: number;
}

function buildEmailHtml(patientName: string, consentLink: string): string {
  const greetingName = patientName.trim().length > 0 ? patientName : "Merhaba";

  return `
    <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; color: #1f2937;">
      <h2 style="color: #0f766e;">Optiyou KVKK Onayı</h2>
      <p>${greetingName},</p>
      <p>
        Optiyou tarafından sizin adınıza oluşturulan kayıt kapsamında kişisel verilerinizin
        işlenmesine ilişkin Aydınlatma Metni'ni incelemenizi ve onaylamanızı rica ederiz.
      </p>
      <p style="text-align: center; margin: 32px 0;">
        <a
          href="${consentLink}"
          style="background-color: #0f766e; color: #ffffff; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600;"
        >
          Aydınlatma Metnini Görüntüle ve Onayla
        </a>
      </p>
      <p style="font-size: 13px; color: #6b7280;">
        Bu bağlantı 14 gün süreyle geçerlidir. Bağlantı çalışmıyorsa aşağıdaki adresi
        tarayıcınıza yapıştırabilirsiniz:<br />
        <a href="${consentLink}" style="color: #0f766e;">${consentLink}</a>
      </p>
    </div>
  `;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body: RequestBody = await req.json();
    const { email, patient_name, consent_link } = body;

    if (!email || !consent_link) {
      return new Response(
        JSON.stringify({ success: false, error: "email ve consent_link zorunludur." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const resendApiKey = Deno.env.get("RESEND_API_KEY");

    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ success: false, error: "RESEND_API_KEY tanımlı değil." }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Optiyou <no-reply@optiyou.fit>",
        to: [email],
        subject: "Optiyou KVKK Onayı Bekliyor",
        html: buildEmailHtml(patient_name ?? "", consent_link),
      }),
    });

    if (!resendResponse.ok) {
      const errorText = await resendResponse.text();
      return new Response(
        JSON.stringify({ success: false, error: errorText }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: String(error) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

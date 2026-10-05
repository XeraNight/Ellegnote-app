import {
  corsHeaders,
  getAuthenticatedUser,
  jsonResponse,
  errorResponse,
} from "../_shared/supabase-client.ts";

interface SendEmailPayload {
  to: string;
  type: "partner_invite" | "welcome" | "notification" | "custom";
  subject?: string;
  partnerName?: string;
  inviteCode?: string;
  customMessage?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      return errorResponse("invalid_input", "Server configuration error: RESEND_API_KEY is not set.", 500);
    }

    // Authenticate user via Supabase JWT
    const user = await getAuthenticatedUser(req);
    if (!user) {
      return errorResponse("unauthorized", "Vyžaduje sa prihlásenie používateľa.", 401);
    }

    const payload: SendEmailPayload = await req.json();
    if (!payload.to || !payload.to.includes("@")) {
      return errorResponse("invalid_input", "Zadaj platnú e-mailovú adresu príjemcu.", 400);
    }

    // Configure sender address (can be your custom verified domain or Resend testing domain)
    const fromAddress = Deno.env.get("RESEND_FROM_EMAIL") || "Encore App <onboarding@resend.dev>";

    let emailSubject = payload.subject || "Správa z aplikácie Encore";
    let emailHtml = "";

    if (payload.type === "partner_invite") {
      const inviterName = payload.partnerName || "Tvoj tanečný partner";
      const code = payload.inviteCode || "";
      const inviteUrl = `encore://invite?code=${encodeURIComponent(code)}`;

      emailSubject = `${inviterName} ťa pozýva do aplikácie Encore`;
      emailHtml = `
<!DOCTYPE html>
<html lang="sk">
<head><meta charset="utf-8"><title>Pozvánka do Encore</title></head>
<body style="margin: 0; padding: 0; background-color: #0b0b0e; color: #ffffff; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding: 40px 20px; background-color: #0b0b0e;">
    <tr><td align="center">
      <table width="100%" style="max-width: 520px; background-color: #141418; border-radius: 20px; border: 1px solid rgba(212,175,55,0.3); overflow: hidden;">
        <tr><td style="padding: 36px 32px 20px 32px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.06);">
          <h1 style="margin: 0; font-size: 28px; color: #e6c875; letter-spacing: 3px; text-transform: uppercase;">ENCORE</h1>
          <p style="margin: 4px 0 0; font-size: 13px; color: rgba(255,255,255,0.5);">Tanečný denník a párový tréning</p>
        </td></tr>
        <tr><td style="padding: 32px; text-align: center;">
          <h2 style="font-size: 22px; color: #ffffff; margin-top: 0;">Tanečná pozvánka pre teba</h2>
          <p style="font-size: 15px; line-height: 24px; color: rgba(255,255,255,0.8); text-align: left;">
            Ahoj,<br><br>
            <strong>${inviterName}</strong> ťa pozýva spojiť sa ako tanečný partner v aplikácii <strong>Encore</strong>. Budete môcť spoločne zdieľať tréningové záznamy, figúry a choreografie.
          </p>
          <div style="background: rgba(212,175,55,0.1); border: 1px dashed rgba(212,175,55,0.4); border-radius: 12px; padding: 16px; margin: 24px 0;">
            <span style="font-size: 12px; color: rgba(255,255,255,0.6); text-transform: uppercase; letter-spacing: 1px;">Kód tvojej pozvánky:</span>
            <div style="font-size: 24px; font-weight: 800; color: #e6c875; letter-spacing: 3px; margin-top: 6px;">${code}</div>
          </div>
          <a href="${inviteUrl}" style="display: inline-block; background: linear-gradient(135deg, #e6c875, #b89130); color: #0b0b0e; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px; margin: 16px 0; text-transform: uppercase;">
            Otvoriť v aplikácii Encore
          </a>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
      `;
    } else {
      emailHtml = `
<!DOCTYPE html>
<html>
<body style="background-color: #0b0b0e; color: #ffffff; padding: 30px; font-family: sans-serif;">
  <div style="max-width: 500px; margin: 0 auto; background: #141418; padding: 24px; border-radius: 16px; border: 1px solid rgba(212,175,55,0.3);">
    <h1 style="color: #e6c875; letter-spacing: 2px;">ENCORE</h1>
    <p style="color: rgba(255,255,255,0.85);">${payload.customMessage || "Správa z aplikácie Encore."}</p>
  </div>
</body>
</html>
      `;
    }

    // Call Resend REST API
    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromAddress,
        to: [payload.to],
        subject: emailSubject,
        html: emailHtml,
      }),
    });

    const resendData = await resendResponse.json();

    if (!resendResponse.ok) {
      return jsonResponse({ error: "Resend API error", details: resendData }, resendResponse.status);
    }

    return jsonResponse({ success: true, id: resendData.id }, 200);
  } catch (err: any) {
    return errorResponse("invalid_input", err?.message || "Internal server error", 500);
  }
});

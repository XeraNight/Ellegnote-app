// send-email: sends ONE kind of e-mail, the partner invitation, from the signed-in user.
//
// It used to accept any subject/HTML/recipient from the client, which made it a spam and
// phishing relay under your own domain. Now:
//   - the only type is `partner_invite`
//   - subject and body are built here; names are HTML-escaped
//   - the invite code comes from the caller's own profile, never from the request
//   - 5 invitations per user per day, and one per recipient per week (log table stores a hash)
//
// Required secrets: RESEND_API_KEY. Optional: RESEND_FROM_EMAIL (verified domain).
// Requires the migration 20261006_auth_account_lifecycle.sql (table email_send_log).

import {
  corsHeaders,
  errorResponse,
  getAuthenticatedUser,
  getSupabaseAdmin,
  jsonResponse,
} from "../_shared/supabase-client.ts";

const DAILY_LIMIT = 5;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

async function sha256Hex(input: string): Promise<string> {
  const bytes = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("invalid_input", "Použi POST.", 405);

  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  if (!resendApiKey) return errorResponse("invalid_input", "E-mail služba nie je nastavená.", 500);

  const user = await getAuthenticatedUser(req);
  if (!user) return errorResponse("unauthorized", "Vyžaduje sa prihlásenie.", 401);

  let payload: { type?: string; to?: string };
  try {
    payload = await req.json();
  } catch {
    return errorResponse("invalid_input", "Neplatné dáta.", 400);
  }

  if (payload.type !== "partner_invite") {
    return errorResponse("invalid_input", "Tento typ e-mailu nie je povolený.", 400);
  }

  const to = (payload.to ?? "").trim().toLowerCase();
  if (to.length > 254 || !EMAIL_RE.test(to)) {
    return errorResponse("invalid_input", "Zadaj platnú e-mailovú adresu.", 400);
  }
  if (user.email && to === user.email.toLowerCase()) {
    return errorResponse("invalid_input", "Pozvánku nemôžeš poslať sám sebe.", 400);
  }

  try {
    const admin = getSupabaseAdmin();

    // The invite code and display name come from the server, not from the client
    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("name, invite_code, account_status")
      .eq("id", user.id)
      .single();
    if (profileError || !profile?.invite_code) {
      return errorResponse("not_found", "Profil nemá kód pozvánky.", 404);
    }
    if (profile.account_status === "banned" || profile.account_status === "suspended") {
      return errorResponse("blocked", "Účet je zablokovaný.", 403);
    }

    // Rate limits
    const toHash = await sha256Hex(to);
    const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const { count: sentToday } = await admin
      .from("email_send_log")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .gte("created_at", dayAgo);
    if ((sentToday ?? 0) >= DAILY_LIMIT) {
      return errorResponse("rate_limited", "Dnes si už poslal maximum pozvánok. Skús to zajtra.", 429);
    }

    const { count: sameRecipient } = await admin
      .from("email_send_log")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("to_hash", toHash)
      .gte("created_at", weekAgo);
    if ((sameRecipient ?? 0) > 0) {
      return errorResponse("rate_limited", "Tomuto človeku si pozvánku nedávno poslal.", 429);
    }

    const inviterName = escapeHtml((profile.name ?? "Tvoj tanečný partner").toString().slice(0, 60));
    const code = escapeHtml(profile.invite_code.toString());
    const inviteUrl = `encore://invite?code=${encodeURIComponent(profile.invite_code.toString())}`;
    const subject = `${(profile.name ?? "Tvoj tanečný partner").toString().slice(0, 60)} ťa pozýva do aplikácie Encore`
      .replace(/[\r\n]+/g, " ");

    const html = `<!DOCTYPE html>
<html lang="sk"><head><meta charset="utf-8"><title>Pozvánka do Encore</title></head>
<body style="margin:0;padding:0;background-color:#0b0b0e;color:#ffffff;font-family:-apple-system,BlinkMacSystemFont,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 20px;background-color:#0b0b0e;"><tr><td align="center">
    <table width="100%" style="max-width:520px;background-color:#141418;border-radius:20px;border:1px solid rgba(212,175,55,0.3);">
      <tr><td style="padding:36px 32px 20px 32px;text-align:center;">
        <h1 style="margin:0;font-size:28px;color:#e6c875;letter-spacing:3px;text-transform:uppercase;">ENCORE</h1>
      </td></tr>
      <tr><td style="padding:12px 32px 32px 32px;text-align:center;">
        <p style="font-size:15px;line-height:24px;color:rgba(255,255,255,0.8);text-align:left;">
          <strong>${inviterName}</strong> ťa pozýva spojiť sa ako tanečný partner v aplikácii <strong>Encore</strong>.
          Budete môcť zdieľať tréningové záznamy, figúry a choreografie.
        </p>
        <div style="background:rgba(212,175,55,0.1);border:1px dashed rgba(212,175,55,0.4);border-radius:12px;padding:16px;margin:24px 0;">
          <span style="font-size:12px;color:rgba(255,255,255,0.6);text-transform:uppercase;letter-spacing:1px;">Kód pozvánky</span>
          <div style="font-size:24px;font-weight:800;color:#e6c875;letter-spacing:3px;margin-top:6px;">${code}</div>
        </div>
        <a href="${inviteUrl}" style="display:inline-block;background:#e6c875;color:#0b0b0e;font-size:15px;font-weight:700;text-decoration:none;padding:14px 32px;border-radius:12px;">Otvoriť v Encore</a>
        <p style="font-size:11px;color:rgba(255,255,255,0.4);margin-top:24px;">Ak nepoznáš odosielateľa, e-mail ignoruj.</p>
      </td></tr>
    </table>
  </td></tr></table>
</body></html>`;

    // Record first so a crash after sending cannot be used to bypass the limit
    const { error: logError } = await admin
      .from("email_send_log")
      .insert({ user_id: user.id, kind: "partner_invite", to_hash: toHash });
    if (logError) throw logError;

    const fromAddress = Deno.env.get("RESEND_FROM_EMAIL") || "Encore <onboarding@resend.dev>";
    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { "Authorization": `Bearer ${resendApiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ from: fromAddress, to: [to], subject, html }),
    });

    if (!resendResponse.ok) {
      console.error("send-email: provider error", resendResponse.status);
      return jsonResponse({ error: "send_failed", message: "E-mail sa nepodarilo odoslať." }, 502);
    }

    return jsonResponse({ ok: true });
  } catch (err) {
    console.error("send-email failed:", err instanceof Error ? err.message : err);
    return jsonResponse({ error: "send_failed", message: "E-mail sa nepodarilo odoslať." }, 500);
  }
});

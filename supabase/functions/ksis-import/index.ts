import {
  corsHeaders,
  getAuthenticatedUser,
  getSupabaseAdmin,
  jsonResponse,
  errorResponse,
} from "../_shared/supabase-client.ts";
import { parseKSISHtml, normalizeDancerName } from "../_shared/ksis-parser.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return errorResponse("invalid_input", "Povolená je výhradne metóda POST.", 405);
  }

  // 1. Authenticate user via JWT
  const user = await getAuthenticatedUser(req);
  if (!user) {
    return errorResponse("unauthorized", "Vyžaduje sa prihlásenie používateľa.", 401);
  }

  // 2. Parse and validate JSON input
  let body: any;
  try {
    body = await req.json();
  } catch {
    return errorResponse("invalid_input", "Neplatný formát JSON požiadavky.", 400);
  }

  const { sutaz_id, couple_id, preview_only } = body || {};

  const parsedSutazId = Number(sutaz_id);
  const parsedCoupleId = Number(couple_id);

  if (!Number.isInteger(parsedSutazId) || parsedSutazId <= 0) {
    return errorResponse("invalid_input", "sutaz_id musí byť kladné celé číslo.", 400);
  }

  if (!Number.isInteger(parsedCoupleId) || parsedCoupleId <= 0) {
    return errorResponse("invalid_input", "couple_id musí byť kladné celé číslo.", 400);
  }

  const supabase = getSupabaseAdmin();

  // 3. Security check: couple_id MUST belong to user_couples
  const { data: userCouple, error: coupleCheckErr } = await supabase
    .from("user_couples")
    .select("id, couple_id")
    .eq("user_id", user.id)
    .eq("couple_id", parsedCoupleId)
    .maybeSingle();

  if (coupleCheckErr) {
    return errorResponse("invalid_input", `Chyba pri kontrole páru: ${coupleCheckErr.message}`, 400);
  }

  if (!userCouple) {
    return errorResponse(
      "forbidden",
      `ID páru ${parsedCoupleId} nie je priradené k vášmu účtu. Najprv si pár zaregistrujte v profile.`,
      403
    );
  }

  // 4. Atomic Rate Limit Check (60s user limit, 30s competition fetch limit)
  const { data: retryAfterSec, error: rateErr } = await supabase.rpc(
    "check_and_acquire_import_cooldown",
    {
      p_user_id: user.id,
      p_sutaz_id: parsedSutazId,
    }
  );

  if (rateErr) {
    return errorResponse("invalid_input", `Chyba rate limiteru: ${rateErr.message}`, 500);
  }

  if (typeof retryAfterSec === "number" && retryAfterSec > 0) {
    return errorResponse(
      "rate_limited",
      `Príliš veľa požiadaviek na import výsledkov. Skúste to znova o ${retryAfterSec} sekúnd.`,
      429,
      { retry_after: retryAfterSec },
      { "Retry-After": String(retryAfterSec) }
    );
  }

  // 5. Soft name check against user's profile
  let nameWarning: string | null = null;
  const { data: profile } = await supabase
    .from("profiles")
    .select("name")
    .eq("id", user.id)
    .maybeSingle();

  const profileName = profile?.name ? normalizeDancerName(profile.name) : "";

  // 6. Fetch KSIS page with honest User-Agent (10 s timeout)
  const contactEmail = Deno.env.get("KSIS_CONTACT_EMAIL") || "jakubkalina05@gmail.com";
  const userAgent = `EncoreApp/1.0 (contact: ${contactEmail})`;
  const ksisUrl = `https://szts.ksis.eu/sutaz.php?sutaz_id=${parsedSutazId}`;

  let rawHtml = "";
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000);

    const response = await fetch(ksisUrl, {
      method: "GET",
      headers: {
        "User-Agent": userAgent,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "sk,cs,en;q=0.8",
      },
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    if (response.status === 403 || response.status === 503) {
      return errorResponse("blocked", "Prístup k stránke KSIS bol dočasne zablokovaný ochranou Cloudflare.", 503);
    }

    if (response.status === 404) {
      return errorResponse("not_found", `Súťaž ID ${parsedSutazId} sa na portáli KSIS nenašla.`, 404);
    }

    if (response.status !== 200) {
      return errorResponse("parse_failed", `KSIS vrátil neočakávaný stav: ${response.status}`, 502);
    }

    const arrayBuffer = await response.arrayBuffer();
    try {
      rawHtml = new TextDecoder("utf-8").decode(arrayBuffer);
    } catch {
      rawHtml = new TextDecoder("windows-1250").decode(arrayBuffer);
    }
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return errorResponse("parse_failed", `Zlyhalo spojenie so serverom KSIS: ${msg}`, 504);
  }

  // 7. Parse HTML via shared parser
  const parseResult = await parseKSISHtml(rawHtml, parsedCoupleId, parsedSutazId);

  if (parseResult.status === "blocked") {
    return errorResponse("blocked", `Cloudflare blokovanie: ${parseResult.reason}`, 503);
  }

  if (parseResult.status === "not_found") {
    return errorResponse(
      "not_found",
      `Pár s ID ${parsedCoupleId} sa nenachádza vo výsledkoch súťaže ID ${parsedSutazId} (nájdených ${parseResult.totalCouplesOnPage} párov).`,
      404
    );
  }

  if (parseResult.status !== "ok") {
    return errorResponse("parse_failed", "Nepodarilo sa spracovať výsledky súťaže.", 422);
  }

  const { meta, couple, stateHash } = parseResult.data;

  // Verify Official status
  if (!couple.isOfficial && !meta.isOfficial) {
    return errorResponse(
      "not_official",
      "Výsledky tejto súťaže ešte nie sú oficiálne potvrdené hlavným rozhodcom.",
      422,
      { is_official: false }
    );
  }

  // Perform soft name comparison (advisory only)
  if (profileName && profileName !== "tanecnik" && profileName !== "jakub") {
    const normCouple = normalizeDancerName(couple.coupleName);
    const profileParts = profileName.split(" ").filter((p: string) => p.length >= 3);
    const hasMatch = profileParts.some((part: string) => normCouple.includes(part));
    if (!hasMatch && profileParts.length > 0) {
      nameWarning = `Meno v profile (${profile?.name}) sa priamo nezhoduje s menom páru v KSIS (${couple.coupleName}).`;
    }
  }

  // 8. Soft-deleted row conflict check
  const { data: existingRow, error: checkRowErr } = await supabase
    .from("competition_results")
    .select("id, is_deleted")
    .eq("user_id", user.id)
    .eq("sutaz_id", parsedSutazId)
    .eq("couple_id", parsedCoupleId)
    .maybeSingle();

  if (checkRowErr) {
    return errorResponse("invalid_input", `Chyba pri kontrole existujúcich výsledkov: ${checkRowErr.message}`, 400);
  }

  if (existingRow && existingRow.is_deleted === true) {
    return errorResponse(
      "conflict_deleted",
      "Tento výsledok bol v minulosti vymazaný. Môžete ho obnoviť namiesto opätovného importu.",
      409,
      {
        can_restore: true,
        existing_result_id: existingRow.id,
      }
    );
  }

  // If preview requested, return parsed data without saving to DB
  if (preview_only === true) {
    return jsonResponse({
      success: true,
      preview: {
        meta,
        couple,
        stateHash,
      },
      name_warning: nameWarning,
    });
  }

  // 9. UPSERT into competition_results using service role
  const { data: savedResult, error: saveErr } = await supabase
    .from("competition_results")
    .upsert(
      {
        user_id: user.id,
        sutaz_id: parsedSutazId,
        couple_id: parsedCoupleId,
        event_name: meta.eventName,
        category_name: meta.categoryName,
        discipline: meta.discipline,
        date: meta.date,
        place: meta.place,
        couple_count: meta.coupleCount,
        placement_text: couple.placementText,
        placement: couple.placement,
        points_earned: couple.pointsEarned,
        cumulative_stats: couple.cumulativeStats,
        cumulative_points: couple.cumulativePoints,
        cumulative_finals: couple.cumulativeFinals,
        crosses_count: null,
        is_official: couple.isOfficial,
        season: meta.season,
        is_deleted: false,
        deleted_at: null,
        imported_at: new Date().toISOString(),
      },
      { onConflict: "user_id, sutaz_id, couple_id" }
    )
    .select()
    .single();

  if (saveErr) {
    return errorResponse("invalid_input", `Chyba pri ukladaní výsledku do denníka: ${saveErr.message}`, 400);
  }

  return jsonResponse({
    success: true,
    result: savedResult,
    name_warning: nameWarning,
  });
});

import {
  corsHeaders,
  getAuthenticatedUser,
  getSupabaseAdmin,
  jsonResponse,
  errorResponse,
} from "../_shared/supabase-client.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  // 1. Authenticate user via JWT
  const user = await getAuthenticatedUser(req);
  if (!user) {
    return errorResponse("unauthorized", "Vyžaduje sa prihlásenie používateľa.", 401);
  }

  const supabase = getSupabaseAdmin();

  // 2. GET: List user's registered couples
  if (req.method === "GET") {
    const { data, error } = await supabase
      .from("user_couples")
      .select("id, couple_id, discipline, partner_name, partner_consent, created_at, updated_at")
      .eq("user_id", user.id)
      .order("created_at", { ascending: true });

    if (error) {
      return errorResponse("invalid_input", `Chyba pri načítaní párov: ${error.message}`, 400);
    }

    return jsonResponse({
      success: true,
      couples: data || [],
    });
  }

  // 3. POST: Add or Remove a couple
  if (req.method === "POST") {
    let body: any;
    try {
      body = await req.json();
    } catch {
      return errorResponse("invalid_input", "Neplatný formát JSON požiadavky.", 400);
    }

    const { action, couple_id, discipline, partner_name, partner_consent } = body || {};

    // 3a. POST action: "list" -> Return user's couples
    if (action === "list") {
      const { data, error } = await supabase
        .from("user_couples")
        .select("id, couple_id, discipline, partner_name, partner_consent, created_at, updated_at")
        .eq("user_id", user.id)
        .order("created_at", { ascending: true });

      if (error) {
        return errorResponse("invalid_input", `Chyba pri načítaní párov: ${error.message}`, 400);
      }

      return jsonResponse({
        success: true,
        couples: data || [],
      });
    }

    // Strict numeric validation for action: "add" or "remove"
    const parsedCoupleId = Number(couple_id);
    if (!Number.isInteger(parsedCoupleId) || parsedCoupleId <= 0) {
      return errorResponse("invalid_input", "couple_id musí byť kladné celé číslo.", 400);
    }

    if (action === "add") {
      const trimmedPartnerName = typeof partner_name === "string" ? partner_name.trim() : null;

      // Privacy rule: partner_consent = true required if partner_name is stored
      if (trimmedPartnerName && partner_consent !== true) {
        return errorResponse(
          "invalid_input",
          "Pri uložení mena tanečného partnera je vyžadovaný súhlas partnera (partner_consent = true).",
          400
        );
      }

      // Check max 2 couples limit per user
      const { count, error: countErr } = await supabase
        .from("user_couples")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user.id);

      if (countErr) {
        return errorResponse("invalid_input", `Chyba pri overení limitu párov: ${countErr.message}`, 400);
      }

      // Allow updating existing couple_id, but reject adding a 3rd unique couple
      const { data: existingCouple } = await supabase
        .from("user_couples")
        .select("id")
        .eq("user_id", user.id)
        .eq("couple_id", parsedCoupleId)
        .maybeSingle();

      if (!existingCouple && (count ?? 0) >= 2) {
        return errorResponse("invalid_input", "Môžete mať zaregistrované maximálne 2 páry.", 400);
      }

      const validDisciplines = ["STT", "LAT", "10T", "ALL"];
      const resolvedDiscipline = validDisciplines.includes(discipline) ? discipline : "ALL";

      const { data, error } = await supabase
        .from("user_couples")
        .upsert(
          {
            user_id: user.id,
            couple_id: parsedCoupleId,
            discipline: resolvedDiscipline,
            partner_name: trimmedPartnerName,
            partner_consent: Boolean(partner_consent),
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id, couple_id" }
        )
        .select()
        .single();

      if (error) {
        return errorResponse("invalid_input", `Chyba pri ukladaní páru: ${error.message}`, 400);
      }

      return jsonResponse({
        success: true,
        couple: data,
      });
    }

    if (action === "remove") {
      const { error } = await supabase
        .from("user_couples")
        .delete()
        .eq("user_id", user.id)
        .eq("couple_id", parsedCoupleId);

      if (error) {
        return errorResponse("invalid_input", `Chyba pri odstraňovaní páru: ${error.message}`, 400);
      }

      return jsonResponse({
        success: true,
        message: `Pár ID ${parsedCoupleId} bol úspešne odstránený.`,
      });
    }

    return errorResponse("invalid_input", "Neplatná akcia. Podporované akcie: 'add', 'remove'.", 400);
  }

  return errorResponse("invalid_input", "Nepodporovaná HTTP metóda.", 405);
});

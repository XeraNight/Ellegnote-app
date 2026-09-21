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

  if (req.method !== "POST") {
    return errorResponse("invalid_input", "Povolená je výhradne metóda POST.", 405);
  }

  // 1. Authenticate user via JWT
  const user = await getAuthenticatedUser(req);
  if (!user) {
    return errorResponse("unauthorized", "Vyžaduje sa prihlásenie používateľa.", 401);
  }

  // 2. Parse JSON body
  let body: any;
  try {
    body = await req.json();
  } catch {
    return errorResponse("invalid_input", "Neplatný formát JSON požiadavky.", 400);
  }

  const { action, result_id } = body || {};

  if (!result_id || typeof result_id !== "string" || result_id.trim().length === 0) {
    return errorResponse("invalid_input", "result_id je povinný reťazec (UUID výsledku).", 400);
  }

  const cleanResultId = result_id.trim();
  const supabase = getSupabaseAdmin();

  // 3. Soft Delete action
  if (action === "soft_delete") {
    const { data, error } = await supabase
      .from("competition_results")
      .update({
        is_deleted: true,
        deleted_at: new Date().toISOString(),
      })
      .eq("id", cleanResultId)
      .eq("user_id", user.id)
      .select("id, is_deleted, deleted_at, event_name, placement_text")
      .maybeSingle();

    if (error) {
      return errorResponse("invalid_input", `Chyba pri archivácii: ${error.message}`, 400);
    }

    if (!data) {
      return errorResponse(
        "not_found",
        "Výsledok s daným ID neexistuje alebo nepatrí vášmu používateľskému účtu.",
        404
      );
    }

    return jsonResponse({
      success: true,
      action: "soft_delete",
      result: data,
    });
  }

  // 4. Restore action
  if (action === "restore") {
    const { data, error } = await supabase
      .from("competition_results")
      .update({
        is_deleted: false,
        deleted_at: null,
      })
      .eq("id", cleanResultId)
      .eq("user_id", user.id)
      .select("id, is_deleted, deleted_at, event_name, placement_text")
      .maybeSingle();

    if (error) {
      return errorResponse("invalid_input", `Chyba pri obnove výsledku: ${error.message}`, 400);
    }

    if (!data) {
      return errorResponse(
        "not_found",
        "Výsledok s daným ID neexistuje alebo nepatrí vášmu používateľskému účtu.",
        404
      );
    }

    return jsonResponse({
      success: true,
      action: "restore",
      result: data,
    });
  }

  return errorResponse(
    "invalid_input",
    "Neplatná akcia. Podporované sú výhradne akcie 'soft_delete' a 'restore'.",
    400
  );
});

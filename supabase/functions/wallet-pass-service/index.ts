import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// MARK: - Official Apple PassKit Web Service
// Conforms to Apple Wallet Pass Web Service Reference:
// - Registering a device for push updates
// - Getting updated passes
// - Unregistering a device
serve(async (req: Request) => {
  const url = new URL(req.url);
  const path = url.pathname.replace(/^\/functions\/v1\/wallet-pass-service/, "");

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // 1. Device Registration: POST /v1/devices/{deviceLibraryIdentifier}/registrations/{passTypeIdentifier}/{serialNumber}
  const regMatch = path.match(/^\/v1\/devices\/([^\/]+)\/registrations\/([^\/]+)\/([^\/]+)$/);
  if (regMatch) {
    const [_, deviceId, passTypeId, serialNum] = regMatch;
    const authHeader = req.headers.get("Authorization");
    const authToken = authHeader ? authHeader.replace(/^ApplePass\s+/i, "") : null;

    if (req.method === "POST") {
      try {
        const body = await req.json();
        const pushToken = body.pushToken;

        if (!pushToken) {
          return new Response("Chýba pushToken", { status: 400 });
        }

        const { error } = await supabase.from("pass_registrations").upsert({
          device_library_identifier: deviceId,
          pass_type_identifier: passTypeId,
          serial_number: serialNum,
          push_token: pushToken,
          authorization_token: authToken || "",
          updated_at: new Date().toISOString(),
        });

        if (error) {
          return new Response(JSON.stringify({ error: error.message }), { status: 500 });
        }

        return new Response(null, { status: 201 }); // 201 Created per Apple spec
      } catch (e: any) {
        return new Response(e.message, { status: 400 });
      }
    }

    // Unregister Device: DELETE
    if (req.method === "DELETE") {
      await supabase
        .from("pass_registrations")
        .delete()
        .match({
          device_library_identifier: deviceId,
          pass_type_identifier: passTypeId,
          serial_number: serialNum,
        });

      return new Response(null, { status: 200 });
    }
  }

  // 2. Getting Serial Numbers: GET /v1/devices/{deviceLibraryIdentifier}/registrations/{passTypeIdentifier}
  const getSerialsMatch = path.match(/^\/v1\/devices\/([^\/]+)\/registrations\/([^\/]+)$/);
  if (getSerialsMatch && req.method === "GET") {
    const [_, deviceId, passTypeId] = getSerialsMatch;
    const passesUpdatedSince = url.searchParams.get("passesUpdatedSince");

    let query = supabase
      .from("pass_registrations")
      .select("serial_number, updated_at")
      .eq("device_library_identifier", deviceId)
      .eq("pass_type_identifier", passTypeId);

    if (passesUpdatedSince) {
      query = query.gt("updated_at", passesUpdatedSince);
    }

    const { data, error } = await query;
    if (error || !data || data.length === 0) {
      return new Response(null, { status: 204 }); // 204 No Content
    }

    const serialNumbers = data.map((d: any) => d.serial_number);
    const lastUpdated = data[0]?.updated_at || new Date().toISOString();

    return new Response(
      JSON.stringify({ serialNumbers, lastUpdated }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  }

  // 3. Apple Logging Endpoint: POST /v1/log
  if (path === "/v1/log" && req.method === "POST") {
    try {
      const logs = await req.json();
      console.log("[ApplePassKit Log]:", JSON.stringify(logs));
      return new Response(null, { status: 200 });
    } catch {
      return new Response(null, { status: 200 });
    }
  }

  return new Response("Not found", { status: 404 });
});

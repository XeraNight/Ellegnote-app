import * as cheerio from "npm:cheerio@1.0.0";
import type { 
  KSISCompetitionMeta, 
  KSISCoupleResult, 
  KSISCoupleState, 
  KSISParseResult, 
  DisciplineType, 
  CoupleCompetitionState 
} from "./ksis-types.ts";

/**
 * Normalizes dancer or club names for diacritics-insensitive comparisons.
 * Converts to NFD, strips combining diacritical marks, and lowercases.
 */
export function normalizeDancerName(name: string): string {
  if (!name) return "";
  return name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Calculates SHA-256 hex digest of the canonical couple state.
 * Uses Web Crypto API (supported natively in Deno, Node 18+, and browsers).
 */
export async function computeStateHash(data: {
  coupleId: number;
  placementText: string;
  pointsEarned: number;
  cumulativeStats: string | null;
  isOfficial: boolean;
  state: CoupleCompetitionState;
  roundName: string;
}): Promise<string> {
  const canonical = JSON.stringify({
    coupleId: data.coupleId,
    placementText: data.placementText,
    pointsEarned: data.pointsEarned,
    cumulativeStats: data.cumulativeStats ?? null,
    isOfficial: data.isOfficial,
    state: data.state,
    roundName: data.roundName,
  });

  const encoder = new TextEncoder();
  const buffer = await crypto.subtle.digest("SHA-256", encoder.encode(canonical));
  return Array.from(new Uint8Array(buffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Parses raw KSIS HTML and extracts the specific couple's result row
 * plus anonymous competition metadata.
 * 
 * GDPR: Extracts ONLY the requested couple row. Does not store or return
 * other dancers' rows or full HTML.
 */
export async function parseKSISHtml(
  html: string,
  targetCoupleId: number,
  overrideSutazId?: number
): Promise<KSISParseResult> {
  if (!html || typeof html !== "string") {
    return { status: "blocked", reason: "Empty HTML payload provided." };
  }

  // 1. Cloudflare challenge detection
  const lowerHtml = html.toLowerCase();
  if (
    lowerHtml.includes("just a moment") ||
    lowerHtml.includes("cf-wrapper") ||
    lowerHtml.includes("challenges.cloudflare.com") ||
    lowerHtml.includes("attention required! | cloudflare")
  ) {
    return { status: "blocked", reason: "Cloudflare challenge page detected." };
  }

  const $ = cheerio.load(html);

  // 2. Extract competition ID
  let sutazId = overrideSutazId ?? 0;
  if (!sutazId) {
    const title = $("title").text();
    const match = title.match(/sutaz_id=(\d+)/i) || html.match(/sutaz_id=(\d+)/i);
    if (match) {
      sutazId = parseInt(match[1], 10);
    }
  }

  // 3. Extract Heading & Event info
  const h3Text = $("div.jumbotron h3, h3").first().text().trim();
  let eventName = "Neznáma súťaž";
  let categoryName = "Neurčená kategória";

  if (h3Text) {
    // e.g. "Košice Grand Prix 2026 - Parket B - Dospelí D ŠTT 12.09.2026"
    const parts = h3Text.split("-").map((p: string) => p.trim());
    if (parts.length >= 2) {
      eventName = parts[0];
      categoryName = parts.slice(1).join(" - ").replace(/\d{1,2}\.\d{1,2}\.\d{4}/, "").trim();
    } else {
      eventName = h3Text.replace(/\d{1,2}\.\d{1,2}\.\d{4}/, "").trim();
    }
  }

  // Determine discipline
  let discipline: DisciplineType = "STT";
  const fullHeaderText = (h3Text + " " + $("body").text().slice(0, 1000)).toUpperCase();
  if (fullHeaderText.includes("LAT") || fullHeaderText.includes("LATINA")) {
    discipline = "LAT";
  } else if (fullHeaderText.includes("10T") || fullHeaderText.includes("DESAŤ")) {
    discipline = "10T";
  } else {
    discipline = "STT";
  }

  // Extract Date
  let dateIso = new Date().toISOString().split("T")[0];
  const dateMatch = html.match(/\b(\d{1,2})\.(\d{1,2})\.(\d{4})\b/);
  if (dateMatch) {
    const day = dateMatch[1].padStart(2, "0");
    const month = dateMatch[2].padStart(2, "0");
    const year = dateMatch[3];
    dateIso = `${year}-${month}-${day}`;
  }

  // Calculate Dance Sport season (September 1 - August 31)
  const [dYearStr, dMonthStr] = dateIso.split("-");
  const dYear = parseInt(dYearStr, 10);
  const dMonth = parseInt(dMonthStr, 10);
  const season = dMonth >= 9 ? `${dYear}/${dYear + 1}` : `${dYear - 1}/${dYear}`;

  // Extract Place
  let place: string | null = null;
  $("h5").each((_i: number, el: any) => {
    const text = $(el).text();
    if (text.includes("Miesto:")) {
      place = text.replace(/Miesto:\s*/i, "").trim();
    }
  });

  // Extract Couple Count
  let coupleCount = 0;
  $("h5").each((_i: number, el: any) => {
    const text = $(el).text();
    if (text.includes("Počet párov")) {
      const cMatch = text.match(/Počet párov\s*(\d+)/i);
      if (cMatch) coupleCount = parseInt(cMatch[1], 10);
    }
  });

  // 4. Iterate table rows to locate target couple
  let targetRowData: KSISCoupleResult | null = null;
  let currentRound = "Finále";
  let totalCouplesFound = 0;
  let hasAnyGreenCheck = false;

  for (const tr of $("table.table tr").toArray()) {
    const $tr = $(tr);

    // Check for round divider row: <TD colspan=...><i><b>Semifinále</b></i></TD>
    if ($tr.find("td[colspan]").length > 0) {
      const bText = $tr.find("b, i").first().text().trim();
      if (bText) {
        currentRound = bText;
      }
      continue;
    }

    const tds = $tr.find("td");
    if (tds.length < 5) continue; // Header or empty row

    const coupleLink = $tr.find("a[href*='par.php?id=']");
    if (coupleLink.length === 0) continue;

    totalCouplesFound++;

    // Check for official green checkmark
    const hasCheck = $tr.find(".glyphicon-ok, [style*='color: green']").length > 0;
    if (hasCheck) {
      hasAnyGreenCheck = true;
    }

    const href = coupleLink.attr("href") || "";
    const idMatch = href.match(/par\.php\?id=(\d+)/i);
    if (!idMatch) continue;

    const rowCoupleId = parseInt(idMatch[1], 10);

    // Is this our requested couple?
    if (rowCoupleId === targetCoupleId) {
      const placementText = $(tds[0]).text().trim();
      const placeMatch = placementText.match(/^(\d+)/);
      const placementNumeric = placeMatch ? parseInt(placeMatch[1], 10) : null;
      const bib = $(tds[1]).text().trim() || null;
      const coupleName = coupleLink.text().trim();
      const club = $(tds[3]).text().trim();
      const pointsEarned = parseInt($(tds[4]).text().trim(), 10) || 0;

      // Cumulative stats: e.g. "89/5F" or empty
      const rawCumulative = tds.length >= 6 ? $(tds[5]).text().trim() : "";
      let cumulativeStats: string | null = null;
      let cumulativePoints = 0;
      let cumulativeFinals = 0;

      if (rawCumulative && rawCumulative !== "-" && rawCumulative !== "&nbsp;") {
        cumulativeStats = rawCumulative;
        const cumMatch = rawCumulative.match(/(\d+)\s*\/\s*(\d+)/);
        if (cumMatch) {
          cumulativePoints = parseInt(cumMatch[1], 10);
          cumulativeFinals = parseInt(cumMatch[2], 10);
        }
      }

      // Determine state based on round (Note: "semifinále" contains "finále", so explicitly exclude "semi")
      let state: CoupleCompetitionState = "eliminated";
      const normRound = currentRound.toLowerCase();
      const isFinalRound = (normRound.includes("finále") || normRound.includes("finale")) && !normRound.includes("semi");

      if (isFinalRound) {
        state = "final_placement";
      } else {
        state = "eliminated";
      }

      targetRowData = {
        coupleId: rowCoupleId,
        coupleName,
        club,
        bib,
        roundName: currentRound,
        placementText,
        placement: placementNumeric,
        pointsEarned,
        cumulativeStats,
        cumulativePoints,
        cumulativeFinals,
        isOfficial: hasCheck,
        state,
      };
    }
  }

  if (coupleCount === 0) {
    coupleCount = totalCouplesFound;
  }

  const meta: KSISCompetitionMeta = {
    sutazId,
    eventName,
    categoryName,
    discipline,
    date: dateIso,
    place,
    coupleCount,
    season,
    isOfficial: hasAnyGreenCheck,
  };

  const coupleResult: KSISCoupleResult | null = targetRowData;
  if (!coupleResult) {
    return {
      status: "not_found",
      coupleId: targetCoupleId,
      totalCouplesOnPage: totalCouplesFound,
    };
  }

  // Official verification check: if target couple row has no official checkmark
  const isTargetOfficial = coupleResult.isOfficial || hasAnyGreenCheck;
  coupleResult.isOfficial = isTargetOfficial;

  const stateHash = await computeStateHash(coupleResult);

  const coupleState: KSISCoupleState = {
    meta,
    couple: coupleResult,
    stateHash,
  };

  return {
    status: "ok",
    data: coupleState,
  };
}

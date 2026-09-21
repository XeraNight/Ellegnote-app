import { assertEquals, assertNotEquals, assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseKSISHtml, normalizeDancerName, computeStateHash } from "./ksis-parser.ts";

const FIXTURE_PATH = decodeURIComponent(new URL("../../../fixtures/ksis_12094_anonymized.html", import.meta.url).pathname);

Deno.test("Name Normalization: Strips accents, lowers case, normalizes spaces", () => {
  assertEquals(normalizeDancerName("Jakub Kalina"), "jakub kalina");
  assertEquals(normalizeDancerName("Júlia Bartošová"), "julia bartosova");
  assertEquals(normalizeDancerName("Kundrát Ondrej"), "kundrat ondrej");
  assertEquals(normalizeDancerName("   NÉMETH   MATEJ   PETER  "), "nemeth matej peter");
  assertEquals(normalizeDancerName("Eliška Kozáčiková"), "eliska kozacikova");
});

Deno.test("State Hash: Deterministic and tamper-evident", async () => {
  const state1 = {
    coupleId: 18978,
    placementText: "3.",
    pointsEarned: 18,
    cumulativeStats: "89/5F",
    isOfficial: true,
    state: "final_placement" as const,
    roundName: "Finále",
  };

  const hash1 = await computeStateHash(state1);
  const hash2 = await computeStateHash(state1);
  assertEquals(hash1, hash2);
  assertEquals(hash1.length, 64); // Valid SHA-256 hex string

  // Tamper points
  const hashTampered = await computeStateHash({ ...state1, pointsEarned: 19 });
  assertNotEquals(hash1, hashTampered);
});

Deno.test("Cloudflare Challenge Detection: Returns blocked status", async () => {
  const cfHtml = `<!DOCTYPE html><html><head><title>Just a moment...</title></head><body><div class="cf-wrapper">Verification</div></body></html>`;
  const result = await parseKSISHtml(cfHtml, 18978);
  assertEquals(result.status, "blocked");
  if (result.status === "blocked") {
    assert(result.reason.includes("Cloudflare"));
  }
});

Deno.test("Real KSIS HTML Fixture: Extracts couple 18978 in Finále (3rd place, 18 pts, 89/5F)", async () => {
  const html = await Deno.readTextFile(FIXTURE_PATH);
  const result = await parseKSISHtml(html, 18978);

  assertEquals(result.status, "ok");
  if (result.status !== "ok") return;

  // Metadata verification
  assertEquals(result.data.meta.sutazId, 12094);
  assertEquals(result.data.meta.eventName, "Košice Grand Prix 2026");
  assertEquals(result.data.meta.discipline, "STT");
  assertEquals(result.data.meta.date, "2026-09-12");
  assertEquals(result.data.meta.season, "2026/2027");
  assertEquals(result.data.meta.coupleCount, 13);
  assertEquals(result.data.meta.isOfficial, true);

  // Couple row verification
  assertEquals(result.data.couple.coupleId, 18978);
  assertEquals(result.data.couple.bib, "61");
  assertEquals(result.data.couple.placementText, "3.");
  assertEquals(result.data.couple.placement, 3);
  assertEquals(result.data.couple.pointsEarned, 18);
  assertEquals(result.data.couple.cumulativeStats, "89/5F");
  assertEquals(result.data.couple.cumulativePoints, 89);
  assertEquals(result.data.couple.cumulativeFinals, 5);
  assertEquals(result.data.couple.roundName, "Finále");
  assertEquals(result.data.couple.state, "final_placement");
  assertEquals(result.data.couple.isOfficial, true);
  assertEquals(result.data.stateHash.length, 64);
});

Deno.test("Real KSIS HTML Fixture: Extracts couple 17787 in Semifinále (7th place, eliminated)", async () => {
  const html = await Deno.readTextFile(FIXTURE_PATH);
  const result = await parseKSISHtml(html, 17787);

  assertEquals(result.status, "ok");
  if (result.status !== "ok") return;

  assertEquals(result.data.couple.coupleId, 17787);
  assertEquals(result.data.couple.bib, "30");
  assertEquals(result.data.couple.placementText, "7.");
  assertEquals(result.data.couple.placement, 7);
  assertEquals(result.data.couple.pointsEarned, 6);
  assertEquals(result.data.couple.cumulativeStats, "108/5F");
  assertEquals(result.data.couple.cumulativePoints, 108);
  assertEquals(result.data.couple.cumulativeFinals, 5);
  assertEquals(result.data.couple.roundName, "Semifinále");
  assertEquals(result.data.couple.state, "eliminated");
});

Deno.test("Real KSIS HTML Fixture: Non-existent couple returns not_found with total count", async () => {
  const html = await Deno.readTextFile(FIXTURE_PATH);
  const result = await parseKSISHtml(html, 999999);

  assertEquals(result.status, "not_found");
  if (result.status === "not_found") {
    assertEquals(result.coupleId, 999999);
    assertEquals(result.totalCouplesOnPage, 13);
  }
});

Deno.test("Edge Case: Range placement ('7.-9.') parses numeric placement as 7", async () => {
  const sampleTable = `
    <html><body>
      <div class="jumbotron"><h3>Test Súťaž - Dospelí D ŠTT 12.09.2026</h3></div>
      <table class="table">
        <tr><td>7.-9.</td><td>42</td><td><a href='par.php?id=5555'>Tanečník A - Tanečnica B</a></td><td>Klub</td><td>3</td><td>10/1F</td><td><span class='glyphicon glyphicon-ok' style='color: green;'></span></td></tr>
      </table>
    </body></html>
  `;
  const result = await parseKSISHtml(sampleTable, 5555, 999);
  assertEquals(result.status, "ok");
  if (result.status === "ok") {
    assertEquals(result.data.couple.placementText, "7.-9.");
    assertEquals(result.data.couple.placement, 7);
    assertEquals(result.data.couple.pointsEarned, 3);
    assertEquals(result.data.couple.cumulativeStats, "10/1F");
  }
});

Deno.test("Edge Case: Non-scoring competition with null cumulative stats", async () => {
  const sampleNonScoring = `
    <html><body>
      <div class="jumbotron"><h3>Pohár Mesta - Hobby ŠTT 12.09.2026</h3></div>
      <table class="table">
        <tr><td>1.</td><td>10</td><td><a href='par.php?id=7777'>Tanečník C - Tanečnica D</a></td><td>Klub</td><td>0</td><td>-</td><td><span class='glyphicon glyphicon-ok' style='color: green;'></span></td></tr>
      </table>
    </body></html>
  `;
  const result = await parseKSISHtml(sampleNonScoring, 7777, 888);
  assertEquals(result.status, "ok");
  if (result.status === "ok") {
    assertEquals(result.data.couple.cumulativeStats, null);
    assertEquals(result.data.couple.cumulativePoints, 0);
    assertEquals(result.data.couple.cumulativeFinals, 0);
  }
});

Deno.test("Edge Case: Unofficial competition (no green checkmark anywhere)", async () => {
  const sampleUnofficial = `
    <html><body>
      <div class="jumbotron"><h3>Prebiehajúca Súťaž - Dospelí C LAT 12.09.2026</h3></div>
      <table class="table">
        <tr><td>1.</td><td>10</td><td><a href='par.php?id=8888'>Tanečník E - Tanečnica F</a></td><td>Klub</td><td>15</td><td>50/2F</td><td></td></tr>
      </table>
    </body></html>
  `;
  const result = await parseKSISHtml(sampleUnofficial, 8888, 777);
  assertEquals(result.status, "ok");
  if (result.status === "ok") {
    assertEquals(result.data.meta.isOfficial, false);
    assertEquals(result.data.couple.isOfficial, false);
  }
});

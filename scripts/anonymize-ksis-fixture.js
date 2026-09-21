#!/usr/bin/env node

/**
 * KSIS HTML Fixture Anonymizer
 * 
 * Usage:
 *   node scripts/anonymize-ksis-fixture.js <input.html> [output.html] [--keep-couple=ID]
 * 
 * Replaces dancer names, club names, and judge names with synthetic anonymous labels
 * while preserving 100% of HTML table structures, points, placement strings,
 * cumulative stats ("89/5F"), round headers (<b>Finále</b>), and bib numbers.
 */

import fs from "node:fs";
import path from "node:path";

const args = process.argv.slice(2);
if (args.length === 0) {
  console.log("Usage: node scripts/anonymize-ksis-fixture.js <input.html> [output.html] [--keep-couple=ID]");
  process.exit(1);
}

let inputFile = "";
let outputFile = "";
let keepCoupleId = null;

for (const arg of args) {
  if (arg.startsWith("--keep-couple=")) {
    keepCoupleId = arg.split("=")[1].trim();
  } else if (!inputFile) {
    inputFile = arg;
  } else if (!outputFile) {
    outputFile = arg;
  }
}

if (!outputFile) {
  const parsed = path.parse(inputFile);
  outputFile = path.join(parsed.dir, `${parsed.name}_anonymized${parsed.ext || ".html"}`);
}

if (!fs.existsSync(inputFile)) {
  console.error(`Error: File not found: ${inputFile}`);
  process.exit(1);
}

let html = fs.readFileSync(inputFile, "utf8");

// 1. Anonymize couple links: <a href=['"]par.php?id=(\d+)['"]>(.*?)</a>
const coupleMap = new Map();
let coupleCounter = 1;

html = html.replace(/<a\s+([^>]*?)href=['"]par\.php\?id=(\d+)['"]([^>]*?)>(.*?)<\/a>/gi, (match, before, coupleId, after, innerText) => {
  if (keepCoupleId && coupleId === keepCoupleId) {
    return `<a ${before}href='par.php?id=${coupleId}'${after}>${innerText}</a>`;
  }
  
  if (!coupleMap.has(coupleId)) {
    coupleMap.set(coupleId, `Tanečník ${coupleCounter} - Tanečnica ${coupleCounter}`);
    coupleCounter++;
  }
  
  const anonName = coupleMap.get(coupleId);
  return `<a ${before}href='par.php?id=${coupleId}'${after}>${anonName}</a>`;
});

// 2. Anonymize judge links / judge names: <a href=['"]porotca.php?id=(\d+)['"]>(.*?)</a>
let judgeCounter = 1;
const judgeMap = new Map();
html = html.replace(/<a\s+([^>]*?)href=['"]porotca\.php\?id=(\d+)['"]([^>]*?)>(.*?)<\/a>/gi, (match, before, judgeId, after, innerText) => {
  if (!judgeMap.has(judgeId)) {
    judgeMap.set(judgeId, `Rozhodca ${judgeCounter}`);
    judgeCounter++;
  }
  const anonJudge = judgeMap.get(judgeId);
  return `<a ${before}href='porotca.php?id=${judgeId}'${after}>${anonJudge}</a>`;
});

// 3. Anonymize club names in table cells if present
// e.g. <a href='klub.php?id=...'>Club Name</a> or inside 4th column <TD>Club Name</TD>
let clubCounter = 1;
const clubMap = new Map();
html = html.replace(/<a\s+([^>]*?)href=['"]klub\.php\?id=(\d+)['"]([^>]*?)>(.*?)<\/a>/gi, (match, before, clubId, after, innerText) => {
  if (!clubMap.has(clubId)) {
    clubMap.set(clubId, `Tanečný Klub ${clubCounter}`);
    clubCounter++;
  }
  const anonClub = clubMap.get(clubId);
  return `<a ${before}href='klub.php?id=${clubId}'${after}>${anonClub}</a>`;
});

// Also match the 4th cell in results table row: <TR ><TD>X.</TD><TD>Bib</TD><TD><a ...>...</a></TD><TD>(.*?)</TD>
html = html.replace(/(<TR\s*><TD>\d+\.<\/TD><TD>\d+\s*<\/TD><TD><a\s+[^>]*>.*?<\/a><\/TD><TD>)(.*?)(<\/TD>)/gi, (match, p1, clubText, p3) => {
  const trimmed = clubText.trim();
  if (!clubMap.has(trimmed)) {
    clubMap.set(trimmed, `Tanečný Klub ${clubCounter}`);
    clubCounter++;
  }
  return `${p1}${clubMap.get(trimmed)}${p3}`;
});

// Ensure output directory exists
const outDir = path.dirname(outputFile);
if (outDir && !fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

fs.writeFileSync(outputFile, html, "utf8");

console.log(`\nAnonymization complete!`);
console.log(`Input:       ${inputFile}`);
console.log(`Output:      ${outputFile}`);
console.log(`Couples:     ${coupleMap.size} anonymized`);
console.log(`Judges:      ${judgeMap.size} anonymized`);
console.log(`Clubs:       ${clubMap.size} anonymized`);
if (keepCoupleId) {
  console.log(`Kept couple: ID ${keepCoupleId}`);
}

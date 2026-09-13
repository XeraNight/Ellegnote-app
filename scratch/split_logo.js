const fs = require('fs');

const svgContent = fs.readFileSync('/Users/jakub/Documents/New project/EncoreLogo_Mark.svg', 'utf8');
const match = svgContent.match(/d="([^"]+)"/);
if (!match) {
  console.log("No path found");
  process.exit(1);
}

const fullD = match[1];
const parts = fullD.split(' Z M ');
console.log(`Found ${parts.length} subpaths!`);

if (parts.length === 2) {
  let path1 = parts[0] + " Z";
  let path2 = "M " + parts[1];
  // Ensure path2 ends with Z
  if (!path2.trim().endsWith("Z") && !path2.trim().endsWith("z")) {
    path2 += " Z";
  }

  console.log("Path 1 length:", path1.length);
  console.log("Path 2 length:", path2.length);

  // Let's create an HTML visualizer to see them in red and gold!
  const html = `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Logo Halves Inspector</title>
<style>
body { background: #1a0a0f; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; margin: 0; color: white; font-family: sans-serif; }
svg { width: 440px; height: 440px; background: radial-gradient(circle at 30% 25%, #9b1828, #580a14); border-radius: 64px; box-shadow: 0 30px 60px rgba(0,0,0,0.8); }
.controls { margin-top: 24px; display: flex; gap: 12px; }
button { padding: 12px 24px; background: #D4AF37; color: black; font-weight: bold; border: none; border-radius: 20px; cursor: pointer; }
</style>
</head>
<body>
<h2>Encore Logo - 2 Skutočné Pod-Cesty</h2>
<svg viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="goldGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fff3c4"/>
      <stop offset="25%" stop-color="#dfb974"/>
      <stop offset="50%" stop-color="#b88437"/>
      <stop offset="75%" stop-color="#f5dfa0"/>
      <stop offset="100%" stop-color="#93641e"/>
    </linearGradient>
  </defs>
  <path id="part1" d="${path1}" fill="#FFE088" opacity="0.9" />
  <path id="part2" d="${path2}" fill="#E11D48" opacity="0.9" />
</svg>
<p style="margin-top: 16px; font-size: 14px; color: #ddd;">
  <span style="color: #FFE088; font-weight: bold;">Zlatá (Časť 1)</span> a 
  <span style="color: #E11D48; font-weight: bold;">Červená (Časť 2)</span>
</p>
</body>
</html>`;

  fs.writeFileSync('/Users/jakub/Documents/New project/scratch/logo_inspector.html', html);
  console.log("Wrote logo_inspector.html successfully!");
}

// src/file-portal.tpl.html + thumbs/*.jpg → index.html（GitHub Pages 用の単独HTML）を生成する
// 使い方: node build.js
const fs = require("fs");
const path = require("path");

const dir  = __dirname;
const tpl  = fs.readFileSync(path.join(dir, "src", "file-portal.tpl.html"), "utf8");
const tdir = path.join(dir, "thumbs");

// --- サムネイルを data URI で埋め込む -------------------------------------
// 外部画像は CSP や Drive の認証で表示できないため、base64 で本文に埋め込む
const thumbs = {};
for (const row of [33, 34, 35, 36, 37, 38, 39, 40, 41, 14, 15, 19, 25, 26]) {
  const p = path.join(tdir, row + ".jpg");
  if (!fs.existsSync(p)) { console.log("missing thumb:", row); continue; }
  thumbs[row] = "data:image/jpeg;base64," + fs.readFileSync(p).toString("base64");
}

if (!tpl.includes("__THUMBS_JSON__")) throw new Error("placeholder __THUMBS_JSON__ not found");
// 未確定の閲覧URLが残ったまま公開しないための見張り
if (tpl.includes("__H19_URL__")) console.log("⚠️  未設定の閲覧URL（__H19_URL__）が残っています。push 前に必ず差し替えてください");
const filled = tpl.replace("__THUMBS_JSON__", JSON.stringify(thumbs));

// --- head / body に分割 ----------------------------------------------------
// テンプレートは Artifact 用に「<title>〜</style>」＋「本文」の順で書かれている。
// GitHub Pages では自前で <!doctype html> の骨組みが要るので、</style> で切り分ける。
const marker = "</style>";
const cut = filled.indexOf(marker);
if (cut === -1) throw new Error("</style> not found");
const headPart = filled.slice(0, cut + marker.length);
const bodyPart = filled.slice(cut + marker.length);

const out = `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27%3E%3Crect width=%2724%27 height=%2724%27 rx=%276%27 fill=%27%23e28ba7%27/%3E%3Cpath d=%27M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z%27 fill=%27none%27 stroke=%27%23fff%27 stroke-width=%271.8%27 stroke-linejoin=%27round%27/%3E%3Cpath d=%27M14 3v5h5%27 fill=%27none%27 stroke=%27%23fff%27 stroke-width=%271.8%27 stroke-linejoin=%27round%27/%3E%3C/svg%3E">
<style>
  :root{ color-scheme: light dark; }
  img{ max-width:100%; }
  [hidden]{ display:none !important; }
</style>
${headPart}
</head>
<body>
${bodyPart}
</body>
</html>
`;

const dest = path.join(dir, "index.html");
fs.writeFileSync(dest, out, "utf8");

console.log("thumbs embedded:", Object.keys(thumbs).length);
console.log("output:", dest);
console.log("size:", (fs.statSync(dest).size / 1024 / 1024).toFixed(2), "MB");

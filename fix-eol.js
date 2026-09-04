// LF normalization for docker-related files (run from traffic-hacker root)
const fs = require("fs");
const path = require("path");
const root = __dirname;
const files = [
  "deploy/modelscope/start.sh",
  "deploy/modelscope/seed.sql.tpl",
  "deploy/modelscope/tinybird-stub.js",
  "Dockerfile",
  ".dockerignore",
];
for (const f of files) {
  const p = path.join(root, f);
  let t = fs.readFileSync(p, "utf8");
  const had = t.includes("\r\n");
  t = t.replace(/\r\n/g, "\n");
  fs.writeFileSync(p, t);
  console.log(`${f}: ${had ? "CRLF->LF fixed" : "already LF"}`);
}

const fs = require("fs");
const b = fs.readFileSync(process.argv[2] || "list.log");
let s = b.toString("utf8");
if (s.indexOf("\u0000") >= 0) s = b.toString("utf16le");
const i = s.indexOf("{");
if (i < 0) { console.log(s.slice(0, 800)); process.exit(1); }
let j = null;
try { j = JSON.parse(s.slice(i)); } catch {}
if (!j) {
  // encoding-mangled JSON: fall back to regex field extraction
  const g = (k) => { const m = s.match(new RegExp('"' + k + '"\\s*:\\s*"([^"]*)"')); return m ? m[1] : ""; };
  console.log("uid:", g("uid"));
  console.log("state:", g("state") || g("readyState"));
  console.log("readySubstate:", g("readySubstate"));
  console.log("sha:", g("githubCommitSha").slice(0, 7));
  console.log("url:", g("url"));
  console.log("errorCode:", g("errorCode"));
  console.log("errorMessage:", g("errorMessage"));
  process.exit(0);
}
if (j.deployments) {
  const d = j.deployments[0];
  console.log("uid:", d.uid);
  console.log("state:", d.state);
  console.log("readySubstate:", d.readySubstate || "");
  console.log("sha:", (d.meta && d.meta.githubCommitSha || "").slice(0, 7));
  console.log("url:", d.url);
} else {
  console.log("readyState:", j.readyState);
  console.log("errorCode:", j.errorCode);
  console.log("errorMessage:", j.errorMessage);
  console.log("errorStep:", j.errorStep);
}

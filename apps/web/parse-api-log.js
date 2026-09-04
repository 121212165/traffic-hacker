const fs = require("fs");
const buf = fs.readFileSync(process.argv[2] || "api.log");
let s = buf.toString("utf8");
if (s.indexOf("\u0000") >= 0 || (buf[0] === 0xff && buf[1] === 0xfe)) s = buf.toString("utf16le");
s = s.replace(/^\uFEFF/, "");
const i = s.indexOf("{");
if (i < 0) { console.log(s.slice(0, 1500)); process.exit(0); }
// find the JSON body (last balanced object starting at first '{')
let j;
try { j = JSON.parse(s.slice(i)); }
catch (e) {
  // try line-by-line for a parseable JSON blob
  const lines = s.split(/\r?\n/);
  for (const line of lines) {
    const t = line.trim();
    if (t.startsWith("{")) { try { j = JSON.parse(t); break; } catch {} }
  }
}
if (!j) { console.log("could not parse JSON; raw head:"); console.log(s.slice(0, 1500)); process.exit(0); }
console.log("readyState:", j.readyState);
console.log("errorCode:", j.errorCode);
console.log("errorMessage:", j.errorMessage);
console.log("errorStep:", j.errorStep);
console.log("errorLink:", j.errorLink);
console.log("readySubstate:", j.readySubstate);
if (j.error) console.log("error obj:", JSON.stringify(j.error));

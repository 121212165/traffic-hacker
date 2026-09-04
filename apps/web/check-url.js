const https = require("https");
const url = process.argv[2] || "https://traffic-hacker-l-jhs-projects.vercel.app/login";
https.get(url, { headers: { "user-agent": "Mozilla/5.0" } }, (res) => {
  console.log("status:", res.statusCode);
  console.log("location:", res.headers.location || "");
  let body = "";
  res.on("data", (c) => (body += c));
  res.on("end", () => {
    console.log("body head:", body.slice(0, 300).replace(/\s+/g, " "));
    const t = body.match(/<title>([^<]*)<\/title>/);
    if (t) console.log("title:", t[1]);
  });
}).on("error", (e) => console.log("ERR", e.message));

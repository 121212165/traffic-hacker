/**
 * Minimal local Tinybird stub for the self-contained ModelScope deploy.
 *
 * The app treats Tinybird as a soft dependency: click events are POSTed to
 * /v0/events inside Promise.allSettled, and analytics pages query
 * /v0/pipes/<pipe>.json. This stub accepts both so analytics features render
 * empty datasets instead of erroring against a missing SaaS.
 */
const http = require("http");

const PORT = process.env.TINYBIRD_STUB_PORT || 7423;

const server = http.createServer((req, res) => {
  // Drain the request body (click event ingestion posts NDJSON payloads)
  req.on("data", () => {});
  req.on("end", () => {
    res.setHeader("Content-Type", "application/json");
    if (req.method === "POST" && req.url.startsWith("/v0/events")) {
      res.end(JSON.stringify({ successful_rows: 1, quarantined_rows: 0 }));
      return;
    }
    // Pipe queries (analytics reads) -> empty result set
    res.end(
      JSON.stringify({
        meta: [],
        data: [],
        rows: 0,
        statistics: { elapsed: 0, rows_read: 0, bytes_read: 0 },
      }),
    );
  });
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`[tinybird-stub] listening on 127.0.0.1:${PORT}`);
});

import { Index } from "@upstash/vector";

// White-label fork deploy: fall back to non-empty placeholders so this
// module-level client never throws "UPSTASH_VECTOR_REST_TOKEN is missing!"
// during `next build` page-data collection when the vector store is unused.
export const vectorIndex = new Index({
  url: process.env.UPSTASH_VECTOR_REST_URL || "https://placeholder.upstash.io",
  token: process.env.UPSTASH_VECTOR_REST_TOKEN || "placeholder_build_only",
});

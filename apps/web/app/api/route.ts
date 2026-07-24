import { document } from "@/lib/openapi";
import { NextResponse } from "next/server";

export const runtime = "nodejs";

export function GET() {
  return NextResponse.json(document);
}

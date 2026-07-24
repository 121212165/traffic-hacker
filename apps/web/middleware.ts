/**
 * White-label fork deploy: minimal middleware to keep Edge bundle under
 * Hobby plan's 1 MB limit. Full routing logic can be restored once
 * deployed on a Pro plan or after verifying the initial deploy works.
 */
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export const config = {
  matcher: [
    "/((?!api/|_next/|_proxy/|favicon.ico|sitemap.xml|robots.txt|manifest.webmanifest).*)",
  ],
};

export default function middleware(_req: NextRequest) {
  return NextResponse.next();
}

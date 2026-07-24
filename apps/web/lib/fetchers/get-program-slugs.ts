import { prisma } from "@/lib/prisma";
import { cache } from "react";

export const getProgramSlugs = cache(async () => {
  try {
    return await prisma.program.findMany({
      select: {
        slug: true,
      },
      orderBy: {
        applications: {
          _count: "desc",
        },
      },
      take: 250,
    });
  } catch {
    // White-label fork deploy: the database may be unreachable during
    // `next build` generateStaticParams. Fall back to no pre-rendered
    // slugs so the build doesn't crash; pages render on-demand at runtime.
    return [];
  }
});

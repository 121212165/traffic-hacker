import { MarketplaceRouter } from "@/ui/program-marketplace/marketplace-router";
import {
  generateMarketplaceProgramStaticParams,
  revalidate,
} from "@/ui/program-marketplace/pages/marketplace-program-page";

export { revalidate };

// White-label fork deploy: render on-demand so the build does not prerender
// marketplace pages that read from a (possibly unreachable) database.
export const dynamic = "force-dynamic";

export async function generateStaticParams() {
  return [];
}

export default async function MarketplacePage(props: {
  params: Promise<{ segments?: string[] }>;
}) {
  const { segments } = await props.params;

  return <MarketplaceRouter segments={segments} />;
}

import type { Metadata } from "next";
import { notFound } from "next/navigation";
import MenuClient from "@/components/MenuClient";
import { getMenu, menus } from "@/lib/menu";

export function generateStaticParams() {
  return menus.map((m) => ({ slug: m.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const menu = getMenu(slug);
  if (!menu) return {};
  return {
    title: menu.label,
    description: `${menu.label} — ${menu.tagline}. Carta de PANISSE, cocina italiana en Pereira.`,
  };
}

export default async function MenuPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const menu = getMenu(slug);
  if (!menu) notFound();
  return <MenuClient menu={menu} />;
}

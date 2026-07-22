import data from "@/data/menu.json";

export interface PriceEntry {
  label: string;
  price: number;
  discounted: number | null;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  prices: PriceEntry[];
  hidePrice: boolean;
  image: string | null;
  isNew: boolean;
  veg: boolean;
  order: number;
}

export type Layout = "cards" | "list";

export interface Subsection {
  id: string;
  slug: string;
  name: string;
  description: string;
  layout: Layout;
  products: Product[];
}

export interface Section {
  id: string;
  slug: string;
  name: string;
  description: string;
  image: string | null;
  layout: Layout;
  products: Product[];
  subsections: Subsection[];
}

export interface Menu {
  slug: string;
  label: string;
  tagline: string;
  name: string;
  // Sedes donde aparece esta carta. null/vacío = todas las sedes.
  // (Roka solo en "pilares"; las cartas de Panisse en todas.)
  locations?: string[] | null;
  sections: Section[];
  totalProducts: number;
}

export interface Restaurant {
  name: string;
  logo: string;
  instagram: string;
  whatsapp: string;
  address: string;
  city: string;
  currency: string;
}

// Copia estática generada en el build: sirve de esqueleto instantáneo.
// La fuente de verdad vive en Supabase y se consulta al montar la página.
export const restaurant: Restaurant = data.restaurant;
export const menus: Menu[] = data.menus as Menu[];

export function getMenu(slug: string): Menu | undefined {
  return menus.find((m) => m.slug === slug);
}

export interface MenuData {
  restaurant: Restaurant;
  menus: Menu[];
}

/** Menú fresco directamente desde la base de datos (Supabase). */
export async function fetchMenuData(): Promise<MenuData> {
  const { rpc } = await import("./supabase");
  return rpc<MenuData>("get_menu_data");
}

// Solo los títulos y frases de cada carta (ligero), en vivo desde la base.
export interface MenuTitle {
  slug: string;
  label: string;
  tagline: string;
  name: string;
}

export async function fetchMenuTitles(): Promise<MenuTitle[]> {
  const { rpc } = await import("./supabase");
  return rpc<MenuTitle[]>("public_menu_titles");
}

export function formatCOP(value: number): string {
  return "$" + value.toLocaleString("es-CO");
}

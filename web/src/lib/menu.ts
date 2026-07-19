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

export interface Subsection {
  id: string;
  slug: string;
  name: string;
  description: string;
  products: Product[];
}

export interface Section {
  id: string;
  slug: string;
  name: string;
  description: string;
  image: string | null;
  products: Product[];
  subsections: Subsection[];
}

export interface Menu {
  slug: string;
  label: string;
  tagline: string;
  name: string;
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

export const restaurant: Restaurant = data.restaurant;
export const menus: Menu[] = data.menus as Menu[];

export function getMenu(slug: string): Menu | undefined {
  return menus.find((m) => m.slug === slug);
}

export function formatCOP(value: number): string {
  return "$" + value.toLocaleString("es-CO");
}

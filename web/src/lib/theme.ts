// Apariencia editable de la portada del cliente (textos, letra, tamaño, color).
import { rpc } from "./supabase";

export interface ThemeText {
  text: string;
  font: FontKey;
  size: number;
  color: string;
}

export interface HomeTheme {
  eyebrow: ThemeText;
  brand: ThemeText & { mode: "logo" | "text" };
  tagline: ThemeText;
  bgColor: string;
  showMarble: boolean;
}

export type FontKey = "playfair" | "outfit" | "cormorant" | "montserrat" | "dancing";

// Cada tipo de letra → su pila de fuentes (usa las variables cargadas en layout).
export const FONT_STACK: Record<FontKey, string> = {
  playfair: 'var(--font-playfair), "Playfair Display", Georgia, serif',
  outfit: 'var(--font-outfit), "Outfit", system-ui, sans-serif',
  cormorant: 'var(--font-cormorant), "Cormorant Garamond", Georgia, serif',
  montserrat: 'var(--font-montserrat), "Montserrat", system-ui, sans-serif',
  dancing: 'var(--font-dancing), "Dancing Script", cursive',
};

// Opciones para el selector del panel (nombre amigable).
export const FONT_OPTIONS: { key: FontKey; label: string }[] = [
  { key: "playfair", label: "Playfair (serif elegante)" },
  { key: "cormorant", label: "Cormorant (serif fina)" },
  { key: "outfit", label: "Outfit (moderna)" },
  { key: "montserrat", label: "Montserrat (redonda)" },
  { key: "dancing", label: "Dancing (cursiva)" },
];

export const fontStack = (f: string): string => FONT_STACK[(f as FontKey)] ?? FONT_STACK.playfair;

// Tema por defecto (idéntico al aspecto actual): se usa mientras carga el real.
export const DEFAULT_HOME_THEME: HomeTheme = {
  eyebrow: { text: "Ristorante · Caffè", font: "outfit", size: 11, color: "#8f7434" },
  brand: { mode: "logo", text: "PANISSE", font: "playfair", size: 46, color: "#041b31" },
  tagline: { text: "Cocina italiana en Pereira", font: "playfair", size: 15, color: "#47535e" },
  bgColor: "#f6f6f5",
  showMarble: true,
};

export const publicHomeTheme = () => rpc<HomeTheme>("public_home_theme");

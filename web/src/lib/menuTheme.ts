// Apariencia de las cartas (Panisse / Roka), editable desde el panel.
//
// Todo se aplica con variables CSS sobre el envoltorio de la carta: como
// las utilidades del sitio (text-navy, bg-card, border-gold-soft…) apuntan
// a esas variables, cambiar una repinta la carta entera sin tocar cada
// componente.
import { rpc } from "./supabase";
import { fontStack, type FontKey } from "./theme";

export type Background = "marble" | "plain" | "image";
export type SectionStyle = "ornament" | "boxed";

export interface MenuTheme {
  bgColor: string; // fondo de la carta
  cardColor: string; // tarjetas y barra de arriba
  titleColor: string; // títulos y botones oscuros
  textColor: string; // texto corrido
  goldColor: string; // detalles dorados
  titleFont: FontKey;
  bodyFont: FontKey;
  scale: number; // 0.9 … 1.3 — tamaño general de la letra
  background: Background;
  bgImage: string | null; // foto de fondo (solo si background = "image")
  sectionStyle: SectionStyle; // adorno clásico o recuadro
}

export const DEFAULT_MENU_THEME: Record<string, MenuTheme> = {
  panisse: {
    bgColor: "#f6f6f5",
    cardColor: "#ffffff",
    titleColor: "#041b31",
    textColor: "#10202f",
    goldColor: "#b28f4c",
    titleFont: "playfair",
    bodyFont: "outfit",
    scale: 1,
    background: "marble",
    bgImage: null,
    sectionStyle: "ornament",
  },
  roka: {
    bgColor: "#f2ecdd",
    cardColor: "#f8f3e6",
    titleColor: "#2f2415",
    textColor: "#352c1e",
    goldColor: "#a3894f",
    titleFont: "playfair",
    bodyFont: "outfit",
    scale: 1,
    background: "plain",
    bgImage: null,
    sectionStyle: "boxed",
  },
};

export const menuThemeFor = (brand: string | undefined | null): MenuTheme =>
  DEFAULT_MENU_THEME[brand === "roka" ? "roka" : "panisse"];

export const publicMenuThemes = () =>
  rpc<Record<string, Partial<MenuTheme>>>("public_menu_themes");

// ── Colores derivados ──
// De un color base se sacan sus variantes (más claro / más oscuro) para no
// pedirle al usuario diez colores: con cinco decisiones queda todo armado.

function hexToRgb(hex: string): [number, number, number] {
  const h = hex.replace("#", "");
  const full = h.length === 3 ? h.split("").map((c) => c + c).join("") : h;
  const n = parseInt(full, 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

const clamp = (n: number) => Math.max(0, Math.min(255, Math.round(n)));
const toHex = (r: number, g: number, b: number) =>
  `#${[r, g, b].map((v) => clamp(v).toString(16).padStart(2, "0")).join("")}`;

/** Mezcla un color con blanco (t>0) o con negro (t<0). */
export function shade(hex: string, t: number): string {
  const [r, g, b] = hexToRgb(hex);
  const target = t >= 0 ? 255 : 0;
  const k = Math.abs(t);
  return toHex(r + (target - r) * k, g + (target - g) * k, b + (target - b) * k);
}

/** Las variables CSS que hay que poner en el envoltorio de la carta. */
export function menuThemeVars(t: MenuTheme): React.CSSProperties {
  return {
    "--color-paper": t.bgColor,
    "--color-paper-deep": shade(t.bgColor, -0.06),
    "--color-card": t.cardColor,
    "--color-ink": t.textColor,
    "--color-ink-soft": shade(t.textColor, 0.28),
    "--color-ink-faint": shade(t.textColor, 0.48),
    "--color-navy": t.titleColor,
    "--color-gold": t.goldColor,
    "--color-gold-deep": shade(t.goldColor, -0.22),
    "--color-gold-soft": shade(t.goldColor, 0.32),
    "--color-gold-faint": shade(t.goldColor, 0.62),
    "--font-display": fontStack(t.titleFont),
    "--font-body": fontStack(t.bodyFont),
    "--menu-scale": String(t.scale),
  } as React.CSSProperties;
}

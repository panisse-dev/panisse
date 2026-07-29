// ══════════════════════════════════════════════════════════════════
// ISHIRO — la marca nueva que reemplaza a ROKA.
//
// Todo lo de la marca nueva vive aquí, en un solo archivo, y se enciende
// o se apaga con PREVIEW_ISHIRO. Mientras esté encendido:
//   · la carta de esa marca se ve con la paleta y la letra nuevas,
//     sin importar lo que haya guardado en el panel de apariencia;
//   · donde decía "Roka" dice "ISHIRO";
//   · aparece el logo circular.
//
// Se hace así, y no cambiando la base de datos, para que la versión de
// prueba no toque nada de lo que ven los clientes hoy. Cuando la marca
// quede aprobada, esto se apaga y los mismos valores se guardan desde
// el panel de apariencia (Ajustes → Apariencia de las cartas).
//
// El identificador interno sigue siendo "roka" a propósito: cambiarlo
// obligaría a tocar pedidos, estadísticas y cocina ya guardados. Lo que
// cambia es el nombre que ve la gente.
// ══════════════════════════════════════════════════════════════════
import type { MenuTheme } from "./menuTheme";

/** Enciende la versión de prueba de la marca nueva. */
export const PREVIEW_ISHIRO = true;

/** Identificador interno de la marca (no cambia). */
export const ISHIRO_BRAND = "roka";

/** El nombre que ve el cliente. */
export const ISHIRO_NAME = "ISHIRO";

export const ISHIRO_LOGO = "/marca/ishiro-logo.png";

/** ¿Esta marca es la nueva? */
export const isIshiro = (brand?: string | null) => brand === ISHIRO_BRAND;

/** El nombre visible de una marca, ya con la marca nueva aplicada. */
export const brandName = (brand?: string | null) =>
  isIshiro(brand) ? (PREVIEW_ISHIRO ? ISHIRO_NAME : "Roka") : "Panisse";

/**
 * Igual que en Panisse: la comida se muestra en fichas con foto y las
 * bebidas en lista, porque una carta de vinos en fichas es una pared de
 * cuadros repetidos que no aporta nada.
 */
const BEBIDAS = /vino|c[oó]ctel|cerveza|soda|limonada|agua|t[óo]nica|gaseosa|caf[eé]|bebida|licor|whisk|ron|gin|tequila|aguardiente/i;

/** Qué disposición usar en una sección de la carta de ISHIRO. */
export const ishiroLayout = <T,>(sectionName: string, layout: T): T | "cards" =>
  BEBIDAS.test(sectionName) ? layout : "cards";

/**
 * Cambia "Roka" por "ISHIRO" en cualquier texto que venga de la base
 * (títulos de carta, nombres de decoración, salones…). Así la versión de
 * prueba se ve completa sin tocar los datos de producción.
 */
export const sinRoka = (text: string | null | undefined): string =>
  PREVIEW_ISHIRO ? (text ?? "").replace(/roka/gi, ISHIRO_NAME) : (text ?? "");

/**
 * Paleta y letra de ISHIRO, tomadas de la propuesta de marca:
 * arena #eae8dc, tinta gris cálida #3e3f3b, tierra #745a52.
 */
export const ISHIRO_THEME: MenuTheme = {
  bgColor: "#e2dfd0",
  cardColor: "#f7f5ed",
  titleColor: "#33342f",
  textColor: "#3f4039",
  goldColor: "#7d6154",
  titleFont: "mono",
  bodyFont: "outfit",
  scale: 1,
  background: "sand",
  bgImage: null,
  sectionStyle: "boxed",
};

/** Aplica la marca nueva sobre lo que venga del panel. */
export const ishiroSkin = (brand: string | null | undefined, saved: MenuTheme): MenuTheme =>
  PREVIEW_ISHIRO && isIshiro(brand) ? ISHIRO_THEME : saved;

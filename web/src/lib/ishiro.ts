// ══════════════════════════════════════════════════════════════════
// El aspecto nuevo de la carta de ROKA, y más adelante su marca nueva.
//
// Son DOS cosas separadas, con su propio interruptor:
//
//   ASPECTO_NUEVO — el fondo de arena, la letra de máquina, la paleta y
//     los platos en fichas. Es solo diseño: la marca se sigue llamando
//     ROKA en todas partes.
//
//   MARCA_ISHIRO — el cambio de nombre a ISHIRO y su logo circular. Va
//     apagado: eso se enciende el día del lanzamiento, no antes.
//
// Se hace desde el código y no desde la base de datos para que la
// versión de prueba no toque nada de lo que ven los clientes hoy.
// Cuando quede aprobado, esto se apaga y los mismos valores se guardan
// desde el panel (Ajustes → Apariencia de las cartas).
//
// El identificador interno de la marca es "roka" y no cambia nunca:
// cambiarlo obligaría a tocar pedidos, estadísticas y cocina ya
// guardados. Lo único que cambiaría algún día es el nombre visible.
// ══════════════════════════════════════════════════════════════════
import type { MenuTheme } from "./menuTheme";

/** El aspecto nuevo de la carta (fondo, letra, fichas). */
export const ASPECTO_NUEVO = true;

/** El nombre y el logo de ISHIRO. Se enciende el día del lanzamiento. */
export const MARCA_ISHIRO = false;

/** Identificador interno de la marca (no cambia). */
export const ISHIRO_BRAND = "roka";

/** El nombre que verá el cliente cuando se lance la marca. */
export const ISHIRO_NAME = "ISHIRO";

export const ISHIRO_LOGO = "/marca/ishiro-logo.png";

/** ¿Es la carta de esta marca? */
export const isIshiro = (brand?: string | null) => brand === ISHIRO_BRAND;

/** El nombre visible de una marca. */
export const brandName = (brand?: string | null) =>
  isIshiro(brand) ? (MARCA_ISHIRO ? ISHIRO_NAME : "Roka") : "Panisse";

/** ¿Se muestra el logo circular? Solo con la marca lanzada. */
export const muestraLogo = (brand?: string | null) => MARCA_ISHIRO && isIshiro(brand);

/**
 * Cambia "Roka" por "ISHIRO" en los textos que vienen de la base
 * (títulos de carta, nombres de decoración…). Mientras la marca no esté
 * lanzada, devuelve el texto tal cual.
 */
export const sinRoka = (text: string | null | undefined): string =>
  MARCA_ISHIRO ? (text ?? "").replace(/roka/gi, ISHIRO_NAME) : (text ?? "");

/**
 * Igual que en Panisse: la comida se muestra en fichas con foto y las
 * bebidas en lista, porque una carta de vinos en fichas es una pared de
 * cuadros repetidos que no aporta nada.
 */
const BEBIDAS = /vino|c[oó]ctel|cerveza|soda|limonada|agua|t[óo]nica|gaseosa|caf[eé]|bebida|licor|whisk|ron|gin|tequila|aguardiente/i;

/** Qué disposición usar en una sección de esta carta. */
export const ishiroLayout = <T,>(sectionName: string, layout: T): T | "cards" =>
  BEBIDAS.test(sectionName) ? layout : "cards";

/**
 * Paleta y letra de la propuesta: arena #eae8dc, tinta gris cálida
 * #3e3f3b, tierra #745a52.
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

/** Aplica el aspecto nuevo sobre lo que venga del panel. */
export const ishiroSkin = (brand: string | null | undefined, saved: MenuTheme): MenuTheme =>
  ASPECTO_NUEVO && isIshiro(brand) ? ISHIRO_THEME : saved;

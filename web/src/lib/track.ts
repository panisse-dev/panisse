// Eventos de analítica: visitas al menú y vistas de producto.
// Se insertan directo en Supabase (la política RLS sólo permite insertar).
import { supabase } from "./supabase";

const SESSION_KEY = "panisse-session";

export function sessionId(): string {
  try {
    let id = sessionStorage.getItem(SESSION_KEY);
    if (!id) {
      id = crypto.randomUUID();
      sessionStorage.setItem(SESSION_KEY, id);
    }
    return id;
  } catch {
    return "sin-sesion";
  }
}

function device(): "movil" | "escritorio" {
  return /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent) ? "movil" : "escritorio";
}

export function track(
  type: "menu_view" | "product_view",
  data: { menuSlug?: string; productId?: string } = {},
): void {
  // Nunca bloquea la interfaz; los fallos se ignoran en silencio.
  void supabase
    .from("events")
    .insert({
      type,
      menu_slug: data.menuSlug ?? null,
      product_id: data.productId ?? null,
      session_id: sessionId(),
      device: device(),
    })
    .then(() => {});
}

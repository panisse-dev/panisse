// API del panel de administración. Todas las operaciones van a RPCs
// de Supabase que verifican la clave del personal (p_code).
import type { PriceEntry } from "./menu";
import type { Order } from "./orders";
import { FUNCTIONS_URL, rpc } from "./supabase";

export const CODE_KEY = "panisse-staff-code";

// ── Menú (árbol completo, incluye ocultos) ──
export interface AdminProduct {
  id: string;
  name: string;
  description: string;
  prices: PriceEntry[];
  hidePrice: boolean;
  image: string | null;
  isNew: boolean;
  veg: boolean;
  visible: boolean;
  order: number;
}

export interface AdminSection {
  id: string;
  name: string;
  description: string;
  layout: string;
  products: AdminProduct[];
  subsections?: AdminSection[];
}

export interface AdminMenu {
  slug: string;
  label: string;
  name: string;
  sections: AdminSection[];
}

// ── Clientes ──
export interface ClientRow {
  id: string;
  name: string;
  phone: string;
  email: string | null;
  birthday: string | null;
  notes: string;
  createdAt: string;
  lastActivityAt: string;
  ordersCount: number;
  totalSpent: number;
  lastOrderAt: string | null;
}

// ── Analítica ──
export interface Analytics {
  kpis: {
    menuVisits: number;
    sessions: number;
    productViews: number;
    orders: number;
    revenue: number;
  };
  visitsByDay: { day: string; visits: number; orders: number; revenue: number }[];
  visitsByDow: { dow: number; visits: number }[];
  visitsByHour: { hour: number; visits: number }[];
  menuVisits: { menu: string; visits: number }[];
  topProductsViews: { id: string; name: string; views: number }[];
  topProductsOrders: { id: string; name: string; qty: number; revenue: number }[];
  topCategories: { name: string; views: number }[];
  devices: { device: string; sessions: number }[];
}

export const staffVerify = (code: string) =>
  rpc<boolean>("staff_verify", { p_code: code });

export const staffOrders = (code: string, day?: string | null) =>
  rpc<Order[]>("staff_orders", { p_code: code, p_day: day ?? null });

// Pedidos pendientes de confirmar pago (no entran a la cocina hasta confirmar)
export const staffPendingOrders = (code: string) =>
  rpc<Order[]>("staff_pending_orders", { p_code: code });

export const staffConfirmPayment = (code: string, id: string) =>
  rpc<void>("staff_confirm_payment", { p_code: code, p_id: id });

export const staffDiscardOrder = (code: string, id: string) =>
  rpc<void>("staff_discard_order", { p_code: code, p_id: id });

export const staffSetStatus = (code: string, id: string, status: string) =>
  rpc<void>("staff_set_status", { p_code: code, p_id: id, p_status: status });

export const staffSetNote = (code: string, id: string, note: string) =>
  rpc<void>("staff_set_note", { p_code: code, p_id: id, p_note: note });

export const staffMenuTree = (code: string) =>
  rpc<AdminMenu[]>("staff_menu_tree", { p_code: code });

export const staffUpdateProduct = (
  code: string,
  id: string,
  patch: Partial<Omit<AdminProduct, "id" | "order">>,
) => rpc<void>("staff_update_product", { p_code: code, p_id: id, p: patch });

export const staffUpdateSection = (
  code: string,
  id: string,
  patch: { name?: string; description?: string },
) => rpc<void>("staff_update_section", { p_code: code, p_id: id, p: patch });

export const staffClients = (code: string) =>
  rpc<ClientRow[]>("staff_clients", { p_code: code });

export const staffUpsertClient = (
  code: string,
  client: {
    id?: string;
    name: string;
    phone?: string;
    email?: string;
    birthday?: string;
    notes?: string;
  },
) => rpc<string>("staff_upsert_client", { p_code: code, p: client });

export const staffDeleteClient = (code: string, id: string) =>
  rpc<void>("staff_delete_client", { p_code: code, p_id: id });

export const staffAnalytics = (code: string, from: string, to: string) =>
  rpc<Analytics>("staff_analytics", { p_code: code, p_from: from, p_to: to });

/** Sube una foto de producto vía Edge Function y devuelve la URL pública. */
export async function uploadImage(code: string, file: File): Promise<string> {
  const res = await fetch(`${FUNCTIONS_URL}/admin-upload`, {
    method: "POST",
    headers: {
      "content-type": file.type || "image/jpeg",
      "x-staff-code": code,
    },
    body: file,
  });
  const data = await res.json().catch(() => null);
  if (!res.ok) throw new Error(data?.error || "No se pudo subir la imagen");
  return data.url as string;
}

/** true si el error de una RPC significa clave inválida/revocada. */
export function isAuthError(e: unknown): boolean {
  return e instanceof Error && /no autorizado/i.test(e.message);
}

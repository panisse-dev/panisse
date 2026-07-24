// API del panel de administración. Todas las operaciones van a RPCs
// de Supabase que verifican la clave del personal (p_code).
import type { PriceEntry } from "./menu";
import type { Order } from "./orders";
import type { HomeTheme } from "./theme";
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
  vip: boolean;
  blacklisted: boolean;
  createdAt: string;
  lastActivityAt: string;
  ordersCount: number;
  totalSpent: number;
  lastOrderAt: string | null;
  reservationsCount: number;
  lastReservationAt: string | null;
}

// ── Reservas ──
export type ReservationStatusAdmin =
  | "pendiente"
  | "confirmada"
  | "cancelada"
  | "cumplida"
  | "no_show";

export interface Reservation {
  id: string;
  code: string;
  date: string; // YYYY-MM-DD
  time: string; // "HH:MM"
  party: number;
  status: ReservationStatusAdmin;
  createdAt: string;
  customer: { name: string; phone: string; email: string };
  note: string;
  staffNote: string;
  depositRequired: number;
  depositPaid: boolean;
  isWalkIn: boolean;
  source: string; // 'web' | 'telefono' | 'google' | 'walkin' | 'otro'
  petFriendly: boolean;
  reducedMobility: boolean;
  decoration: {
    id: string;
    name: string;
    description: string;
    price: number;
    image?: string | null;
  } | null;
  tableId: string | null;
  tableName: string | null;
  tables: { id: string; name: string }[];
}

// ── Decoraciones (editables en el panel) ──
export interface DecorationRow {
  id: string;
  name: string;
  description: string;
  price: number;
  active: boolean;
  image: string | null;
}

export const staffDecorations = (code: string) =>
  rpc<DecorationRow[]>("staff_decorations", { p_code: code });

export const staffUpdateDecoration = (code: string, id: string, patch: Partial<DecorationRow>) =>
  rpc<void>("staff_update_decoration", { p_code: code, p_id: id, p: patch });

export type ReservationSource = "web" | "telefono" | "google" | "walkin" | "otro";

export const SOURCE_LABEL: Record<string, string> = {
  web: "Página web",
  telefono: "Teléfono",
  google: "Google",
  walkin: "Presencial",
  otro: "Otro",
};

// ── Plano del salón (zonas y mesas) ──
export interface FloorTableReservation {
  id: string;
  time: string;
  party: number;
  name: string;
  status: ReservationStatusAdmin;
  isWalkIn: boolean;
}
export interface FloorTable {
  id: string;
  name: string;
  seats: number;
  posX: number;
  posY: number;
  width: number;
  height: number;
  shape: "rect" | "round";
  reservations: FloorTableReservation[];
}
export interface FloorZone {
  id: string;
  name: string;
  sort: number;
  tables: FloorTable[];
}
export interface Floor {
  locationId: string;
  zones: FloorZone[];
}

export interface ReservationDay {
  day: string;
  total: number;
  pendientes: number;
}

export interface ReservationSettings {
  enabled: boolean;
  openDays: number[];
  startTime: string;
  endTime: string;
  slotMinutes: number;
  turnMinutes: number;
  capacity: number;
  maxParty: number;
  advanceDays: number;
  minHours: number;
  depositPerPerson: number;
  allowTableChoice: boolean;
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
  reservations?: {
    total: number;
    confirmed: number; // confirmadas + cumplidas
    fulfilled: number; // cumplidas (el cliente vino)
    cancelled: number;
    noShow: number; // reservó y no llegó
    guests: number; // personas (sin contar canceladas)
    deposits: number; // abonos cobrados (COP)
    byDay: { day: string; total: number; guests: number }[];
    byDow: { dow: number; total: number }[];
    byHour: { hour: number; total: number }[];
  };
}

export const staffVerify = (code: string) =>
  rpc<boolean>("staff_verify", { p_code: code });

// Contexto del personal: qué sede maneja este código (o todas, si es el dueño).
export interface StaffContext {
  locationId: string | null;
  locationName: string;
  allLocations: boolean;
}

export const staffContext = (code: string) =>
  rpc<StaffContext>("staff_context", { p_code: code });

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
    vip?: boolean;
    blacklisted?: boolean;
  },
) => rpc<string>("staff_upsert_client", { p_code: code, p: client });

export const staffDeleteClient = (code: string, id: string) =>
  rpc<void>("staff_delete_client", { p_code: code, p_id: id });

// Marca rápida VIP / lista negra sin abrir el formulario.
export const staffSetClientFlag = (
  code: string,
  id: string,
  flag: "vip" | "blacklisted",
  value: boolean,
) => rpc<void>("staff_set_client_flag", { p_code: code, p_id: id, p_flag: flag, p_value: value });

// Nombre neutro ("resumen") a propósito: los bloqueadores de anuncios
// bloquean las URLs que contienen "analytics", y eso tumbaba esta pantalla
// en equipos con bloqueador. Por dentro es la misma consulta.
export const staffAnalytics = (code: string, from: string, to: string) =>
  rpc<Analytics>("staff_resumen", { p_code: code, p_from: from, p_to: to });

// ── Reservas ──
export const staffReservations = (code: string, day?: string | null) =>
  rpc<Reservation[]>("staff_reservations", { p_code: code, p_day: day ?? null });

export const staffReservationsUpcoming = (code: string) =>
  rpc<ReservationDay[]>("staff_reservations_upcoming", { p_code: code });

// ── Plano del salón + Walk-In ──
export const staffFloor = (code: string, day?: string | null, location?: string | null) =>
  rpc<Floor>("staff_floor", { p_code: code, p_day: day ?? null, p_location: location ?? null });

export const staffAssignTable = (code: string, reservationId: string, tableId: string | null) =>
  rpc<void>("staff_assign_table", { p_code: code, p_reservation: reservationId, p_table: tableId });

// Reemplaza el conjunto de mesas de una reserva (una o varias, para grupos grandes).
export const staffSetReservationTables = (code: string, reservationId: string, tableIds: string[]) =>
  rpc<void>("staff_set_reservation_tables", {
    p_code: code,
    p_reservation: reservationId,
    p_tables: tableIds,
  });

// ── Editar el plano (zonas y mesas) ──
export const staffSaveZone = (
  code: string,
  zone: { id?: string; locationId?: string; name: string; sort?: number },
) => rpc<string>("staff_save_zone", { p_code: code, p: zone });

export const staffDeleteZone = (code: string, id: string) =>
  rpc<void>("staff_delete_zone", { p_code: code, p_id: id });

// Mover un salón en el orden de las pestañas (dir < 0 izquierda, > 0 derecha).
export const staffMoveZone = (code: string, id: string, dir: number) =>
  rpc<void>("staff_move_zone", { p_code: code, p_id: id, p_dir: dir });

export const staffSaveTable = (
  code: string,
  table: {
    id?: string;
    zoneId?: string;
    name: string;
    seats: number;
    shape?: "rect" | "round";
    width?: number;
    height?: number;
    posX?: number;
    posY?: number;
  },
) => rpc<string>("staff_save_table", { p_code: code, p: table });

export const staffMoveTable = (code: string, id: string, x: number, y: number) =>
  rpc<void>("staff_move_table", { p_code: code, p_id: id, p_x: Math.round(x), p_y: Math.round(y) });

export const staffDeleteTable = (code: string, id: string) =>
  rpc<void>("staff_delete_table", { p_code: code, p_id: id });

export const staffWalkin = (
  code: string,
  data: { name?: string; phone?: string; party: number; note?: string; table?: string | null; tables?: string[]; location?: string | null },
) => rpc<{ id: string; code: string; status: string }>("staff_walkin", { p_code: code, p: data });

// Crear una reserva a mano (teléfono, Google, web, otro).
export const staffCreateReservation = (
  code: string,
  data: {
    name: string;
    phone?: string;
    email?: string;
    party: number;
    date: string; // YYYY-MM-DD
    time: string; // HH:MM
    note?: string;
    source: ReservationSource;
    table?: string | null;
    tables?: string[];
    location?: string | null;
  },
) => rpc<{ id: string; code: string; status: string }>("staff_create_reservation", { p_code: code, p: data });

export const staffSetReservationSource = (code: string, id: string, source: ReservationSource) =>
  rpc<void>("staff_set_reservation_source", { p_code: code, p_id: id, p_source: source });

export const staffSetReservationStatus = (code: string, id: string, status: string) =>
  rpc<void>("staff_set_reservation_status", { p_code: code, p_id: id, p_status: status });

// ── Ficha completa de una reserva (ver + editar) ──
export interface ReservationDetail {
  id: string;
  code: string;
  date: string;
  time: string;
  party: number;
  status: ReservationStatusAdmin;
  createdAt: string;
  source: string;
  isWalkIn: boolean;
  petFriendly: boolean;
  reducedMobility: boolean;
  note: string;
  staffNote: string;
  depositRequired: number;
  depositPaid: boolean;
  customer: { name: string; phone: string; email: string };
  tables: { id: string; name: string; zone: string }[];
  client: {
    id: string;
    name: string;
    phone: string;
    email: string | null;
    birthday: string | null;
    vip: boolean;
    blacklisted: boolean;
  } | null;
  clientStats: { total: number; arrived: number; noShow: number; cancelled: number };
}

export const staffReservationDetail = (code: string, id: string) =>
  rpc<ReservationDetail>("staff_reservation_detail", { p_code: code, p_id: id });

// Enviar (o reenviar) a mano el correo de confirmación de una reserva.
export const staffSendReservationEmail = (code: string, id: string) =>
  rpc<boolean>("staff_send_reservation_email", { p_code: code, p_id: id });

export const staffUpdateReservation = (
  code: string,
  id: string,
  patch: {
    party?: number;
    date?: string;
    time?: string;
    petFriendly?: boolean;
    reducedMobility?: boolean;
    staffNote?: string;
    name?: string;
    phone?: string;
    email?: string;
    birthday?: string | null;
  },
) => rpc<void>("staff_update_reservation", { p_code: code, p_id: id, p: patch });

export const staffSetReservationNote = (code: string, id: string, note: string) =>
  rpc<void>("staff_set_reservation_note", { p_code: code, p_id: id, p_note: note });

export const staffSetReservationDeposit = (code: string, id: string, paid: boolean) =>
  rpc<void>("staff_set_reservation_deposit", { p_code: code, p_id: id, p_paid: paid });

// ── Bloqueos de días/horas ──
export interface ReservationBlock {
  id: string;
  date: string; // YYYY-MM-DD
  allDay: boolean;
  startTime: string | null; // "HH:MM"
  endTime: string | null;
  reason: string;
  locationId: string | null;
  locationName: string;
}

// ── Estadísticas de reservas ──
export interface ReservationStats {
  kpis: {
    total: number;
    totalPeople: number;
    effective: number;
    effectivePeople: number;
    pending: number;
    noShow: number;
    cancelled: number;
    avgParty: number | null;
  };
  byDay: { day: string; count: number; people: number }[];
  byMonth: { month: string; count: number; people: number }[];
  byHour: { hour: number; count: number }[];
  byMeal: { desayuno: number; almuerzo: number; cena: number };
  byOrigin: { source: string; count: number; people: number }[];
  byStatus: Record<ReservationStatusAdmin, number>;
  byLocation: { id: string; name: string; count: number }[];
}

export const staffReservationStats = (code: string, from: string, to: string) =>
  rpc<ReservationStats>("staff_reservation_stats", { p_code: code, p_from: from, p_to: to });

export const staffReservationBlocks = (code: string, from?: string, to?: string) =>
  rpc<ReservationBlock[]>("staff_reservation_blocks", {
    p_code: code,
    p_from: from ?? null,
    p_to: to ?? null,
  });

export const staffAddReservationBlock = (
  code: string,
  block: {
    date: string;
    allDay: boolean;
    startTime?: string;
    endTime?: string;
    reason?: string;
    location?: string | null;
  },
) => rpc<string>("staff_add_reservation_block", { p_code: code, p: block });

export const staffRemoveReservationBlock = (code: string, id: string) =>
  rpc<void>("staff_remove_reservation_block", { p_code: code, p_id: id });

export const staffReservationSettings = (code: string) =>
  rpc<ReservationSettings>("staff_reservation_settings", { p_code: code });

export const staffUpdateReservationSettings = (
  code: string,
  patch: Partial<ReservationSettings>,
) => rpc<void>("staff_update_reservation_settings", { p_code: code, p: patch });

// ── Ajustes: sedes y títulos de menús ──
export interface LocationRow {
  id: string;
  name: string;
  address: string;
  phone: string;
  whatsapp: string;
  active: boolean;
}

export interface MenuRow {
  slug: string;
  label: string;
  tagline: string;
  name: string;
}

export const staffLocations = (code: string) =>
  rpc<LocationRow[]>("staff_locations", { p_code: code });

export const staffUpdateLocation = (code: string, id: string, patch: Partial<LocationRow>) =>
  rpc<void>("staff_update_location", { p_code: code, p_id: id, p: patch });

// ── Domicilios (config por sede) ──
export interface DeliverySettings {
  locationId: string;
  locationName: string;
  enabled: boolean;
  fee: number;
  minOrder: number;
  scheduling: boolean;
  leadMinutes: number;
  daysAhead: number;
  startTime: string; // "HH:MM"
  endTime: string; // "HH:MM"
  note: string;
}

export const staffDeliverySettings = (code: string) =>
  rpc<DeliverySettings[]>("staff_delivery_settings", { p_code: code });

export const staffUpdateDeliverySettings = (
  code: string,
  locationId: string,
  patch: Partial<Omit<DeliverySettings, "locationId" | "locationName">>,
) =>
  rpc<void>("staff_update_delivery_settings", {
    p_code: code,
    p_location: locationId,
    p: patch,
  });

// ── Apariencia de la portada del cliente ──
export const staffHomeTheme = (code: string) =>
  rpc<HomeTheme>("staff_home_theme", { p_code: code });

export const staffUpdateHomeTheme = (code: string, theme: HomeTheme) =>
  rpc<void>("staff_update_home_theme", { p_code: code, p: theme });

export const staffMenus = (code: string) => rpc<MenuRow[]>("staff_menus", { p_code: code });

export const staffUpdateMenu = (code: string, slug: string, patch: Partial<MenuRow>) =>
  rpc<void>("staff_update_menu", { p_code: code, p_slug: slug, p: patch });

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

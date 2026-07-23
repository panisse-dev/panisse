// Reservas de mesa contra Supabase (RPCs reservation_*).
import { rpc } from "./supabase";

// Configuración pública que necesita el flujo del cliente.
export interface ReservationConfig {
  enabled: boolean;
  openDays: number[]; // ISO: 1=lunes … 7=domingo
  startTime: string; // "HH:MM"
  endTime: string; // "HH:MM"
  slotMinutes: number;
  maxParty: number;
  advanceDays: number;
  minHours: number;
  depositPerPerson: number; // 0 = sin abono
  allowTableChoice: boolean; // el cliente puede escoger su mesa en el mapa
}

export interface Slot {
  time: string; // "HH:MM" (24h)
  available: boolean;
}

export interface DayAvailability {
  open: boolean;
  reason: string;
  slots: Slot[];
}

export interface CreatedReservation {
  id: string;
  code: string;
  status: string;
  depositRequired: number;
}

export type ReservationStatus =
  | "pendiente"
  | "confirmada"
  | "cancelada"
  | "cumplida"
  | "no_show";

export interface PublicReservation {
  code: string;
  status: ReservationStatus;
  date: string;
  time: string;
  party: number;
  depositPaid: boolean;
}

export interface NewReservation {
  name: string;
  email: string;
  phone: string;
  party: number;
  date: string; // YYYY-MM-DD
  time: string; // HH:MM
  note: string;
  location: string; // sede (id)
  table?: string | null; // mesa elegida (opcional)
  petFriendly?: boolean; // viene con mascota
  reducedMobility?: boolean; // viene con persona de movilidad reducida
}

// ── Mapa del salón que ve el cliente para elegir mesa ──
export interface PublicTable {
  id: string;
  name: string;
  seats: number;
  posX: number;
  posY: number;
  width: number;
  height: number;
  shape: "rect" | "round";
  available: boolean;
}
export interface PublicZone {
  id: string;
  name: string;
  tables: PublicTable[];
}
export interface PublicFloor {
  zones: PublicZone[];
}

export const publicFloor = (location: string, date: string, time: string) =>
  rpc<PublicFloor>("public_floor", { p_location: location, p_date: date, p_time: time });

export const reservationConfig = () =>
  rpc<ReservationConfig>("reservation_config");

export const reservationAvailability = (date: string, party: number, location: string) =>
  rpc<DayAvailability>("reservation_availability", {
    p_date: date,
    p_party: party,
    p_location: location,
  });

export const createReservation = (data: NewReservation) =>
  rpc<CreatedReservation>("create_reservation", { p: data });

export const getReservationStatus = (id: string) =>
  rpc<PublicReservation | null>("get_reservation_public", { p_id: id });

// ── Ayudas de presentación ──

export const RES_STATUS_LABEL: Record<ReservationStatus, string> = {
  pendiente: "Pendiente de confirmar",
  confirmada: "Confirmada",
  cancelada: "Cancelada",
  cumplida: "Cumplida",
  no_show: "No llegó",
};

const DOW_LABEL = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]; // ISO 1..7 → índice 0..6

/** Convierte "HH:MM" (24h) a "h:MM am/pm". */
export function formatTime(hhmm: string): string {
  const [h, m] = hhmm.split(":").map(Number);
  const period = h < 12 ? "am" : "pm";
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return `${h12}:${m.toString().padStart(2, "0")} ${period}`;
}

/** ISO date (YYYY-MM-DD) → "Vie 24 jul" en español, sin líos de zona horaria. */
export function formatDateLabel(iso: string): string {
  const [y, mo, d] = iso.split("-").map(Number);
  const dt = new Date(y, mo - 1, d);
  const iso_dow = ((dt.getDay() + 6) % 7) + 1; // JS 0=dom → ISO 1=lun..7=dom
  const meses = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
  return `${DOW_LABEL[iso_dow - 1]} ${d} ${meses[mo - 1]}`;
}

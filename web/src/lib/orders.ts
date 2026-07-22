// Tipos y helpers compartidos del sistema de pedidos (lado cliente).
// El formato JSON es el contrato con las funciones serverless de Netlify.

export type OrderStatus = "recibido" | "preparacion" | "listo" | "recogido";

export const STATUS_FLOW: OrderStatus[] = ["recibido", "preparacion", "listo", "recogido"];

export const STATUS_LABEL: Record<OrderStatus, string> = {
  recibido: "Recibido",
  preparacion: "En preparación",
  listo: "Listo para recoger",
  recogido: "Recogido",
};

// ── Facturación electrónica (opcional: sólo si el cliente la pide) ──
export type DocType = "CC" | "NIT" | "CE" | "PP";

export const DOC_TYPES: { value: DocType; label: string }[] = [
  { value: "CC", label: "Cédula de ciudadanía" },
  { value: "NIT", label: "NIT (empresa)" },
  { value: "CE", label: "Cédula de extranjería" },
  { value: "PP", label: "Pasaporte" },
];

export const DOC_TYPE_SHORT: Record<DocType, string> = {
  CC: "C.C.",
  NIT: "NIT",
  CE: "C.E.",
  PP: "Pasaporte",
};

export interface Billing {
  docType: DocType;
  docNumber: string;
  name: string; // nombre o razón social
  email: string;
  address: string;
  phone: string;
}

export interface OrderItem {
  productId: string;
  name: string;
  variant: string; // etiqueta de la variante (vacío si no aplica)
  unitPrice: number;
  qty: number;
  note?: string; // nota/descripción que el cliente escribe para este plato
}

export interface Order {
  id: string;
  code: string; // número corto para el cliente/mostrador, ej. "12"
  createdAt: string; // ISO
  status: OrderStatus;
  statusAt: string; // ISO
  customer: { name: string; phone: string; note: string };
  billing: Billing | null; // null cuando el cliente no pidió factura
  paid: boolean; // false = pendiente de confirmar pago (no entra a la cocina)
  items: OrderItem[];
  total: number;
  staffNote?: string; // nota interna que agrega el restaurante desde el panel
  orderType?: "pickup" | "delivery"; // recoger o domicilio
  deliveryAddress?: string; // dirección de entrega (domicilio)
  deliveryFee?: number; // costo del domicilio
  scheduledAt?: string | null; // ISO; hora programada (null = para ya)
}

// El cliente sólo ve un subconjunto público del pedido (sin datos de otros).
export interface PublicOrder {
  code: string;
  status: OrderStatus;
  createdAt: string;
  paid: boolean; // false mientras el restaurante no confirme el pago
}

export function itemsSummary(items: OrderItem[]): string {
  return items
    .map((i) => `${i.qty}× ${i.name}${i.variant ? ` (${i.variant})` : ""}`)
    .join(", ");
}

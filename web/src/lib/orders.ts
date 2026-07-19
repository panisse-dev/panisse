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

export interface OrderItem {
  productId: string;
  name: string;
  variant: string; // etiqueta de la variante (vacío si no aplica)
  unitPrice: number;
  qty: number;
}

export interface Order {
  id: string;
  code: string; // número corto para el cliente/mostrador, ej. "12"
  createdAt: string; // ISO
  status: OrderStatus;
  statusAt: string; // ISO
  customer: { name: string; phone: string; note: string };
  items: OrderItem[];
  total: number;
}

// El cliente sólo ve un subconjunto público del pedido (sin datos de otros).
export interface PublicOrder {
  code: string;
  status: OrderStatus;
  createdAt: string;
}

export function itemsSummary(items: OrderItem[]): string {
  return items
    .map((i) => `${i.qty}× ${i.name}${i.variant ? ` (${i.variant})` : ""}`)
    .join(", ");
}

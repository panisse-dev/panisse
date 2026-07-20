// Pedidos contra Supabase (RPCs create_order / get_order_public).
import type { CartLine } from "./cart";
import type { Billing, PublicOrder } from "./orders";
import { rpc } from "./supabase";
import { sessionId } from "./track";

export interface CreatedOrder {
  id: string;
  code: string;
  status: string;
}

export interface CustomerInfo {
  email: string; // identifica al cliente; si ya existe, el servidor completa el resto
  note: string;
  name?: string;
  phone?: string;
  birthday?: string; // YYYY-MM-DD (obligatorio sólo para clientes nuevos)
  wantsBilling?: boolean; // el cliente pidió factura electrónica
  billing?: Billing; // se omite si ya tenemos los datos guardados del cliente
}

export interface ClientCheck {
  known: boolean;
  name?: string;
  hasBilling?: boolean; // ya tiene datos de facturación guardados
}

/** ¿Ya conocemos este correo? Devuelve el nombre sólo para saludar. */
export async function checkClient(email: string): Promise<ClientCheck> {
  return rpc<ClientCheck>("check_client", { p_email: email });
}

export const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export async function createOrder(
  customer: CustomerInfo,
  lines: CartLine[],
): Promise<CreatedOrder> {
  return rpc<CreatedOrder>("create_order", {
    p: {
      customer,
      items: lines.map((l) => ({
        productId: l.productId,
        variant: l.variant,
        note: l.note,
        qty: l.qty,
      })),
      session_id: sessionId(),
    },
  });
}

// Devuelve null cuando el pedido ya no existe en el servidor (borrado o
// expirado). Un error de red se propaga como excepción para reintentar.
export async function getOrderStatus(id: string): Promise<PublicOrder | null> {
  return rpc<PublicOrder | null>("get_order_public", { p_id: id });
}

// Pedidos contra Supabase (RPCs create_order / get_order_public).
import type { CartLine } from "./cart";
import type { PublicOrder } from "./orders";
import { rpc } from "./supabase";
import { sessionId } from "./track";

export interface CreatedOrder {
  id: string;
  code: string;
  status: string;
}

export interface CustomerInfo {
  name: string;
  phone: string;
  note: string;
  email?: string;
  birthday?: string; // YYYY-MM-DD
}

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

export async function getOrderStatus(id: string): Promise<PublicOrder> {
  const data = await rpc<PublicOrder | null>("get_order_public", { p_id: id });
  if (!data) throw new Error("No se pudo consultar el pedido");
  return data;
}

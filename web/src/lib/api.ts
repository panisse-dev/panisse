import type { CartLine } from "./cart";
import type { PublicOrder } from "./orders";

export interface CreatedOrder {
  id: string;
  code: string;
  status: string;
}

export async function createOrder(
  customer: { name: string; phone: string; note: string },
  lines: CartLine[],
): Promise<CreatedOrder> {
  const res = await fetch("/api/orders", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      customer,
      items: lines.map((l) => ({
        productId: l.productId,
        name: l.name,
        variant: l.variant,
        note: l.note,
        unitPrice: l.unitPrice,
        qty: l.qty,
      })),
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data?.error || "No se pudo enviar el pedido");
  return data as CreatedOrder;
}

export async function getOrderStatus(id: string): Promise<PublicOrder> {
  const res = await fetch(`/api/order?id=${encodeURIComponent(id)}`);
  const data = await res.json();
  if (!res.ok) throw new Error(data?.error || "No se pudo consultar el pedido");
  return data as PublicOrder;
}

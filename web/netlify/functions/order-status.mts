import { getStore } from "@netlify/blobs";
import type { Context } from "@netlify/functions";

type OrderStatus = "recibido" | "preparacion" | "listo" | "recogido";
const VALID: OrderStatus[] = ["recibido", "preparacion", "listo", "recogido"];

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });

const STAFF_CODE = process.env.STAFF_ACCESS_CODE || "";

export default async (req: Request, context: Context) => {
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);
  if (!STAFF_CODE || req.headers.get("x-staff-code") !== STAFF_CODE)
    return json({ error: "No autorizado" }, 401);

  let body: { id?: string; status?: OrderStatus };
  try {
    body = await req.json();
  } catch {
    return json({ error: "JSON inválido" }, 400);
  }

  const id = String(body.id || "");
  const status = body.status as OrderStatus;
  if (!id || !VALID.includes(status)) return json({ error: "Datos inválidos" }, 400);

  const store = getStore("orders");
  const order = (await store.get(`order:${id}`, { type: "json" })) as {
    status: OrderStatus;
    statusAt: string;
  } | null;
  if (!order) return json({ error: "Pedido no encontrado" }, 404);

  order.status = status;
  order.statusAt = new Date().toISOString();
  await store.setJSON(`order:${id}`, order);
  return json({ ok: true, id, status });
};

export const config = {
  path: "/api/orders/status",
};

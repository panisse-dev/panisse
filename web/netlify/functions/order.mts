import { getStore } from "@netlify/blobs";
import type { Context } from "@netlify/functions";

// Consulta pública del estado de UN pedido por su id (para que el cliente
// siga su pedido). Sólo devuelve código y estado, nunca datos de otros.
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });

export default async (req: Request, context: Context) => {
  const id = new URL(req.url).searchParams.get("id") || "";
  if (!id) return json({ error: "Falta id" }, 400);

  const store = getStore("orders");
  const order = (await store.get(`order:${id}`, { type: "json" })) as {
    code: string;
    status: string;
    createdAt: string;
  } | null;
  if (!order) return json({ error: "Pedido no encontrado" }, 404);

  return json({ code: order.code, status: order.status, createdAt: order.createdAt });
};

export const config = {
  path: "/api/order",
};

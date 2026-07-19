import { getStore } from "@netlify/blobs";
import type { Context } from "@netlify/functions";

// Guarda la nota interna que el restaurante agrega a un pedido desde el panel.
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

  let body: { id?: string; note?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "JSON inválido" }, 400);
  }

  const id = String(body.id || "");
  const note = String(body.note ?? "").replace(/\s+/g, " ").trim().slice(0, 300);
  if (!id) return json({ error: "Falta id" }, 400);

  const store = getStore("orders");
  const order = (await store.get(`order:${id}`, { type: "json" })) as { staffNote?: string } | null;
  if (!order) return json({ error: "Pedido no encontrado" }, 404);

  order.staffNote = note;
  await store.setJSON(`order:${id}`, order);
  return json({ ok: true, id, note });
};

export const config = {
  path: "/api/orders/note",
};

import { getStore } from "@netlify/blobs";
import type { Context } from "@netlify/functions";

// ── Tipos (contrato JSON con el frontend) ──
type OrderStatus = "recibido" | "preparacion" | "listo" | "recogido";
interface OrderItem {
  productId: string;
  name: string;
  variant: string;
  note: string;
  unitPrice: number;
  qty: number;
}
interface Order {
  id: string;
  code: string;
  createdAt: string;
  status: OrderStatus;
  statusAt: string;
  customer: { name: string; phone: string; note: string };
  items: OrderItem[];
  total: number;
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });

const STAFF_CODE = process.env.STAFF_ACCESS_CODE || "";
function staffOk(req: Request): boolean {
  const code = req.headers.get("x-staff-code") || "";
  return STAFF_CODE.length > 0 && code === STAFF_CODE;
}

// Genera un número de pedido corto que se reinicia cada día (America/Bogota).
async function nextCode(store: ReturnType<typeof getStore>): Promise<string> {
  const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/Bogota" });
  const counter = ((await store.get("meta:counter", { type: "json" })) as {
    date: string;
    n: number;
  } | null) || { date: today, n: 0 };
  const n = counter.date === today ? counter.n + 1 : 1;
  await store.setJSON("meta:counter", { date: today, n });
  return String(n);
}

function sanitize(s: unknown, max: number): string {
  return String(s ?? "")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, max);
}

export default async (req: Request, context: Context) => {
  const store = getStore("orders");

  // ── Crear pedido (público) ──
  if (req.method === "POST") {
    let body: {
      customer?: { name?: string; phone?: string; note?: string };
      items?: OrderItem[];
    };
    try {
      body = await req.json();
    } catch {
      return json({ error: "JSON inválido" }, 400);
    }

    const rawItems = Array.isArray(body.items) ? body.items : [];
    const items: OrderItem[] = rawItems
      .map((i) => ({
        productId: sanitize(i.productId, 64),
        name: sanitize(i.name, 120),
        variant: sanitize(i.variant, 80),
        note: sanitize(i.note, 200),
        unitPrice: Math.max(0, Math.round(Number(i.unitPrice) || 0)),
        qty: Math.min(50, Math.max(1, Math.round(Number(i.qty) || 1))),
      }))
      .filter((i) => i.name && i.unitPrice > 0);

    const name = sanitize(body.customer?.name, 80);
    if (!name) return json({ error: "Falta el nombre" }, 400);
    if (items.length === 0) return json({ error: "El pedido está vacío" }, 400);

    const total = items.reduce((s, i) => s + i.unitPrice * i.qty, 0);
    const now = new Date().toISOString();
    const id = (globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.round(Math.random() * 1e9)}`);
    const code = await nextCode(store);

    const order: Order = {
      id,
      code,
      createdAt: now,
      status: "recibido",
      statusAt: now,
      customer: {
        name,
        phone: sanitize(body.customer?.phone, 40),
        note: sanitize(body.customer?.note, 300),
      },
      items,
      total,
    };
    await store.setJSON(`order:${id}`, order);
    return json({ id: order.id, code: order.code, status: order.status });
  }

  // ── Listar pedidos (empleado) ──
  if (req.method === "GET") {
    if (!staffOk(req)) return json({ error: "No autorizado" }, 401);
    const { blobs } = await store.list({ prefix: "order:" });
    const orders = (
      await Promise.all(
        blobs.map((b) => store.get(b.key, { type: "json" }) as Promise<Order | null>),
      )
    ).filter((o): o is Order => !!o);

    // Ocultar "recogidos" de hace más de 6 horas para no llenar el panel.
    const cutoff = Date.now() - 6 * 60 * 60 * 1000;
    const visible = orders.filter(
      (o) => o.status !== "recogido" || new Date(o.statusAt).getTime() > cutoff,
    );
    visible.sort((a, b) => a.createdAt.localeCompare(b.createdAt));
    return json({ orders: visible });
  }

  return json({ error: "Método no permitido" }, 405);
};

export const config = {
  path: "/api/orders",
};

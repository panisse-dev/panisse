"use client";

// Pedidos: vista en vivo (con sonido para nuevos) + historial por día.
// En escritorio se muestra como tablero por estado (columnas); en móvil,
// como una sola lista ordenada por hora.
import { useCallback, useEffect, useRef, useState } from "react";
import { formatCOP } from "@/lib/format";
import { DOC_TYPE_SHORT, STATUS_LABEL, type Billing, type Order, type OrderStatus } from "@/lib/orders";
import {
  isAuthError,
  staffConfirmPayment,
  staffDiscardOrder,
  staffOrders,
  staffPendingOrders,
  staffSetNote,
  staffSetStatus,
} from "@/lib/admin";
import { useStaff } from "@/components/admin/AdminShell";

const POLL_MS = 8000;

const NEXT: Record<OrderStatus, OrderStatus | null> = {
  recibido: "preparacion",
  preparacion: "listo",
  listo: "recogido",
  recogido: null,
};
const NEXT_LABEL: Record<OrderStatus, string> = {
  recibido: "Empezar a preparar",
  preparacion: "Marcar listo para recoger",
  listo: "Marcar como recogido",
  recogido: "",
};
const STATUS_STYLE: Record<OrderStatus, string> = {
  recibido: "bg-[#b3261e] text-white",
  preparacion: "bg-gold-deep text-white",
  listo: "bg-verde text-white",
  recogido: "bg-ink-faint/25 text-ink-soft",
};

// Columnas del tablero (escritorio), en orden del flujo de trabajo.
const COLUMNS: { status: OrderStatus; title: string; dot: string }[] = [
  { status: "recibido", title: "Nuevos", dot: "bg-[#b3261e]" },
  { status: "preparacion", title: "En preparación", dot: "bg-gold-deep" },
  { status: "listo", title: "Listos para recoger", dot: "bg-verde" },
];

function timeAgo(iso: string): string {
  const mins = Math.floor((Date.now() - new Date(iso).getTime()) / 60000);
  if (mins < 1) return "ahora";
  if (mins < 60) return `hace ${mins} min`;
  const h = Math.floor(mins / 60);
  return `hace ${h} h ${mins % 60} min`;
}

// ── Aviso por WhatsApp (semiautomático: abre WhatsApp con el mensaje escrito) ──
function waPhone(raw: string): string {
  let d = (raw || "").replace(/\D/g, "");
  if (d.startsWith("00")) d = d.slice(2);
  if (d.length === 10 && d.startsWith("3")) d = "57" + d; // móvil colombiano sin indicativo
  return d;
}
function waMessage(o: Order): string {
  const name = (o.customer.name || "").trim().split(" ")[0];
  const hola = name ? `¡Hola ${name}!` : "¡Hola!";
  // Sin número de pedido: el cliente no debe verlo por WhatsApp.
  const msg: Record<OrderStatus, string> = {
    recibido: `${hola} Recibimos tu pedido en PANISSE. ✅ Te avisamos cuando esté listo.`,
    preparacion: `${hola} Tu pedido en PANISSE ya está en preparación. 👨‍🍳`,
    listo: `${hola} Tu pedido en PANISSE ya está listo para recoger. 🎉 ¡Te esperamos!`,
    recogido: `¡Gracias por tu compra${name ? `, ${name}` : ""}! 🙌 Te esperamos pronto en PANISSE.`,
  };
  return msg[o.status];
}
function waLink(o: Order): string | null {
  const phone = waPhone(o.customer.phone);
  if (!phone) return null;
  return `https://wa.me/${phone}?text=${encodeURIComponent(waMessage(o))}`;
}

// Texto listo para pegar en el programa de facturación.
function billingText(b: Billing): string {
  const lines = [
    `${DOC_TYPE_SHORT[b.docType] ?? b.docType} ${b.docNumber}`,
    b.name,
    b.email,
    b.address,
    b.phone,
  ];
  return lines.filter(Boolean).join("\n");
}

function todayBogota(): string {
  return new Date().toLocaleDateString("en-CA", { timeZone: "America/Bogota" });
}

export default function PedidosPage() {
  const { code, logout } = useStaff();
  const [orders, setOrders] = useState<Order[]>([]);
  const [pending, setPending] = useState<Order[]>([]); // por confirmar pago
  const [day, setDay] = useState<string | null>(null); // null = en vivo
  const [connError, setConnError] = useState(false);
  const [flash, setFlash] = useState(false);
  const [soundOn, setSoundOn] = useState(true);
  const [noteEditId, setNoteEditId] = useState<string | null>(null);
  const [noteDraft, setNoteDraft] = useState("");
  const [copiedBillId, setCopiedBillId] = useState<string | null>(null);

  const seenIds = useRef<Set<string>>(new Set());
  const seenPendingIds = useRef<Set<string>>(new Set());
  const audioCtx = useRef<AudioContext | null>(null);
  const firstLoad = useRef(true);
  const dayRef = useRef(day);
  dayRef.current = day;

  const beep = useCallback(() => {
    if (!soundOn) return;
    try {
      let ctx = audioCtx.current;
      if (!ctx) {
        ctx = new (window.AudioContext ||
          (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
        audioCtx.current = ctx;
      }
      const play = (freq: number, start: number) => {
        const o = ctx!.createOscillator();
        const g = ctx!.createGain();
        o.connect(g);
        g.connect(ctx!.destination);
        o.frequency.value = freq;
        o.type = "sine";
        g.gain.setValueAtTime(0.0001, ctx!.currentTime + start);
        g.gain.exponentialRampToValueAtTime(0.35, ctx!.currentTime + start + 0.02);
        g.gain.exponentialRampToValueAtTime(0.0001, ctx!.currentTime + start + 0.35);
        o.start(ctx!.currentTime + start);
        o.stop(ctx!.currentTime + start + 0.36);
      };
      play(880, 0);
      play(1174, 0.18);
    } catch {
      /* ignore */
    }
  }, [soundOn]);

  const poll = useCallback(async () => {
    try {
      const live = dayRef.current === null;
      const [list, pend] = await Promise.all([
        staffOrders(code, dayRef.current),
        live ? staffPendingOrders(code) : Promise.resolve([] as Order[]),
      ]);
      setConnError(false);

      // Detecta llegadas nuevas (sólo en vivo, no en la primera carga): un
      // pago recién confirmado que entra a la cocina, o un pendiente nuevo.
      const currentIds = new Set(list.map((o) => o.id));
      const currentPendingIds = new Set(pend.map((o) => o.id));
      if (!firstLoad.current && live) {
        const newPaid = list.some((o) => !seenIds.current.has(o.id) && o.status === "recibido");
        const newPending = pend.some((o) => !seenPendingIds.current.has(o.id));
        if (newPaid || newPending) {
          beep();
          setFlash(true);
          setTimeout(() => setFlash(false), 2500);
        }
      }
      seenIds.current = currentIds;
      seenPendingIds.current = currentPendingIds;
      firstLoad.current = false;
      setOrders(list);
      setPending(live ? pend : []);
    } catch (e) {
      if (isAuthError(e)) {
        logout();
        return;
      }
      setConnError(true);
    }
  }, [code, beep, logout]);

  // Polling — pausa cuando el panel no está visible para no gastar recursos.
  useEffect(() => {
    firstLoad.current = true;
    seenIds.current = new Set();
    poll();
    const iv = setInterval(() => {
      if (!document.hidden) poll();
    }, POLL_MS);
    const onVisible = () => {
      if (!document.hidden) poll();
    };
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      clearInterval(iv);
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, [poll, day]);

  const setStatus = async (order: Order, status: OrderStatus) => {
    setOrders((prev) => prev.map((o) => (o.id === order.id ? { ...o, status } : o)));
    try {
      await staffSetStatus(code, order.id, status);
    } catch (e) {
      if (isAuthError(e)) logout();
      else poll();
    }
  };

  const advance = (order: Order) => {
    const next = NEXT[order.status];
    if (next) setStatus(order, next);
  };

  // Confirmar el pago: el pedido sale de "por confirmar" y entra a la cocina.
  const confirmPayment = async (order: Order) => {
    setPending((prev) => prev.filter((o) => o.id !== order.id));
    setOrders((prev) => [
      { ...order, paid: true, status: "preparacion", statusAt: new Date().toISOString() },
      ...prev.filter((o) => o.id !== order.id),
    ]);
    seenIds.current.add(order.id); // ya lo mostramos: que no vuelva a sonar
    try {
      await staffConfirmPayment(code, order.id);
    } catch (e) {
      if (isAuthError(e)) logout();
      else poll();
    }
  };

  // Descartar un pendiente que nunca pagó (lo borra).
  const discardOrder = async (order: Order) => {
    if (!window.confirm(`¿Descartar el pedido de ${order.customer.name || "este cliente"}? No se puede deshacer.`))
      return;
    setPending((prev) => prev.filter((o) => o.id !== order.id));
    try {
      await staffDiscardOrder(code, order.id);
    } catch (e) {
      if (isAuthError(e)) logout();
      else poll();
    }
  };

  const revert = (order: Order) => {
    const flow: OrderStatus[] = ["recibido", "preparacion", "listo", "recogido"];
    const idx = flow.indexOf(order.status);
    if (idx > 0) setStatus(order, flow[idx - 1]);
  };

  const startEditNote = (order: Order) => {
    setNoteEditId(order.id);
    setNoteDraft(order.staffNote || "");
  };

  const saveNote = async (order: Order) => {
    const note = noteDraft.trim();
    setNoteEditId(null);
    setOrders((prev) => prev.map((o) => (o.id === order.id ? { ...o, staffNote: note } : o)));
    try {
      await staffSetNote(code, order.id, note);
    } catch (e) {
      if (isAuthError(e)) logout();
      else poll();
    }
  };

  const live = day === null;
  const active = orders.filter((o) => o.status !== "recogido");
  const done = orders.filter((o) => o.status === "recogido");
  const dayTotal = orders.reduce((s, o) => s + o.total, 0);
  const byStatus = (s: OrderStatus) =>
    active.filter((o) => o.status === s).sort((a, b) => b.createdAt.localeCompare(a.createdAt));

  // Bloque con los datos fiscales, sólo cuando el cliente pidió factura.
  const billingCard = (o: Order, b: Billing | null) =>
    b && (
      <div className="mx-4 mb-1 border border-gold-soft/60 bg-paper px-3 py-2">
        <div className="flex items-start justify-between gap-2">
          <p className="smallcaps text-[9.5px] text-gold-deep">Pidió factura electrónica</p>
          <button
            type="button"
            onClick={() =>
              navigator.clipboard?.writeText(billingText(b)).then(() => {
                setCopiedBillId(o.id);
                window.setTimeout(() => setCopiedBillId(null), 2500);
              })
            }
            className="shrink-0 text-[11.5px] font-medium text-gold-deep underline underline-offset-2"
          >
            {copiedBillId === o.id ? "¡Copiado!" : "Copiar datos"}
          </button>
        </div>
        <p className="mt-1 text-[12.5px] font-medium text-navy">{b.name}</p>
        <p className="text-[12px] text-ink-soft">
          {DOC_TYPE_SHORT[b.docType] ?? b.docType} {b.docNumber}
        </p>
        <p className="text-[12px] text-ink-soft">{b.email}</p>
        {b.address && <p className="text-[12px] text-ink-soft">{b.address}</p>}
        {b.phone && <p className="text-[12px] text-ink-soft">{b.phone}</p>}
      </div>
    );

  // Lista de platos de un pedido (misma en cocina y en pendientes).
  const itemsList = (o: Order) => (
    <ul className="mt-3 border-t border-gold-soft/25 px-4 py-2.5 text-[13.5px] text-ink">
      {o.items.map((it, i) => (
        <li key={i} className="py-0.5">
          <div className="flex justify-between gap-2">
            <span>
              <span className="font-semibold text-navy">{it.qty}×</span> {it.name}
              {it.variant && <span className="text-ink-faint"> · {it.variant}</span>}
            </span>
            <span className="shrink-0 text-ink-soft">{formatCOP(it.unitPrice * it.qty)}</span>
          </div>
          {it.note && (
            <p className="border-l-2 border-gold pl-1.5 text-[12px] italic text-gold-deep">↳ {it.note}</p>
          )}
        </li>
      ))}
    </ul>
  );

  // Bloque de domicilio: badge + dirección + hora programada (si aplica).
  const deliveryBlock = (o: Order) => {
    if (o.orderType !== "delivery") return null;
    const sched = o.scheduledAt
      ? new Date(o.scheduledAt).toLocaleString("es-CO", {
          timeZone: "America/Bogota",
          day: "2-digit",
          month: "short",
          hour: "2-digit",
          minute: "2-digit",
        })
      : null;
    return (
      <div className="mx-4 mt-2 border border-verde/40 bg-verde/8 px-3 py-2">
        <div className="flex items-center justify-between gap-2">
          <span className="smallcaps text-[10px] font-semibold text-verde">
            Domicilio{o.deliveryFee ? ` · ${formatCOP(o.deliveryFee)}` : ""}
          </span>
          <span className="text-[11px] font-medium text-navy">
            {sched ? `Programado: ${sched}` : "Lo antes posible"}
          </span>
        </div>
        {o.deliveryAddress && (
          <p className="mt-1 text-[13px] leading-snug text-ink">📍 {o.deliveryAddress}</p>
        )}
      </div>
    );
  };

  // Tarjeta de un pedido PENDIENTE DE PAGO: aún no entra a la cocina.
  const pendingCard = (o: Order) => (
    <div
      key={o.id}
      className="border-2 border-gold/60 bg-card shadow-[0_1px_8px_rgba(4,27,49,0.06)]"
    >
      <div className="flex items-start justify-between gap-3 px-4 pt-3.5">
        <div className="min-w-0">
          <p className="font-display text-[22px] leading-none text-navy">#{o.code}</p>
          <p className="mt-1 text-[13px] font-medium text-ink">{o.customer.name}</p>
          {o.customer.phone && (
            <a href={`tel:${o.customer.phone}`} className="text-[12px] text-gold-deep underline">
              {o.customer.phone}
            </a>
          )}
        </div>
        <div className="text-right">
          <span className="smallcaps inline-block bg-gold px-2 py-1 text-[10px] font-semibold text-navy">
            Pendiente de pago
          </span>
          <p className="mt-1 text-[11px] text-ink-faint">{timeAgo(o.createdAt)}</p>
        </div>
      </div>

      {deliveryBlock(o)}

      {itemsList(o)}

      {o.customer.note && (
        <p className="mx-4 mb-1 border-l-2 border-gold px-2.5 py-1 text-[12.5px] italic text-ink-soft">
          <span className="smallcaps mr-1 text-[9px] not-italic text-gold-deep">Cliente:</span>
          “{o.customer.note}”
        </p>
      )}

      {billingCard(o, o.billing)}

      <div className="border-t border-gold-soft/25 px-4 py-2">
        <span className="text-[13px] font-semibold text-navy">
          Debe pagar {formatCOP(o.total)}
        </span>
      </div>

      <div className="flex border-t border-gold-soft/25">
        <button
          type="button"
          onClick={() => discardOrder(o)}
          className="h-13 w-2/5 py-3.5 text-[13px] font-medium text-ink-faint hover:bg-paper-deep"
        >
          Descartar
        </button>
        <button
          type="button"
          onClick={() => confirmPayment(o)}
          className="h-13 w-3/5 border-l border-gold-soft/25 bg-verde py-3.5 text-[14px] font-semibold leading-tight text-white transition-transform hover:bg-verde/90 active:scale-[0.99]"
        >
          Confirmar pago y preparar
        </button>
      </div>
    </div>
  );

  // Tarjeta de un pedido — la misma en el tablero (escritorio) y la lista (móvil).
  const card = (o: Order) => (
    <div
      key={o.id}
      className="border border-gold-soft/50 bg-card shadow-[0_1px_8px_rgba(4,27,49,0.06)]"
    >
      <div className="flex items-start justify-between gap-3 px-4 pt-3.5">
        <div className="min-w-0">
          <p className="font-display text-[22px] leading-none text-navy">#{o.code}</p>
          <p className="mt-1 text-[13px] font-medium text-ink">{o.customer.name}</p>
          {o.customer.phone && (
            <a href={`tel:${o.customer.phone}`} className="text-[12px] text-gold-deep underline">
              {o.customer.phone}
            </a>
          )}
        </div>
        <div className="text-right">
          <span className={`smallcaps inline-block px-2 py-1 text-[10px] font-semibold ${STATUS_STYLE[o.status]}`}>
            {STATUS_LABEL[o.status]}
          </span>
          <p className="mt-1 text-[11px] text-ink-faint">{timeAgo(o.createdAt)}</p>
        </div>
      </div>

      {deliveryBlock(o)}

      <ul className="mt-3 border-t border-gold-soft/25 px-4 py-2.5 text-[13.5px] text-ink">
        {o.items.map((it, i) => (
          <li key={i} className="py-0.5">
            <div className="flex justify-between gap-2">
              <span>
                <span className="font-semibold text-navy">{it.qty}×</span> {it.name}
                {it.variant && <span className="text-ink-faint"> · {it.variant}</span>}
              </span>
              <span className="shrink-0 text-ink-soft">{formatCOP(it.unitPrice * it.qty)}</span>
            </div>
            {it.note && (
              <p className="border-l-2 border-gold pl-1.5 text-[12px] italic text-gold-deep">
                ↳ {it.note}
              </p>
            )}
          </li>
        ))}
      </ul>

      {o.customer.note && (
        <p className="mx-4 mb-1 border-l-2 border-gold px-2.5 py-1 text-[12.5px] italic text-ink-soft">
          <span className="smallcaps mr-1 text-[9px] not-italic text-gold-deep">Cliente:</span>
          “{o.customer.note}”
        </p>
      )}

      {/* Datos para la factura electrónica (sólo si el cliente la pidió) */}
      {billingCard(o, o.billing)}

      {/* Nota interna del restaurante */}
      <div className="border-t border-gold-soft/25 px-4 py-2">
        {noteEditId === o.id ? (
          <div>
            <textarea
              value={noteDraft}
              onChange={(e) => setNoteDraft(e.target.value)}
              rows={2}
              autoFocus
              placeholder="Nota interna (ej. pagó, mesa 5, cliente frecuente…)"
              className="w-full resize-none border border-gold-soft/70 bg-paper px-2.5 py-2 text-[13px] text-ink outline-none focus:border-navy"
            />
            <div className="mt-1.5 flex gap-2">
              <button
                type="button"
                onClick={() => saveNote(o)}
                className="h-9 flex-1 bg-navy text-[12.5px] font-semibold text-gold-soft"
              >
                Guardar nota
              </button>
              <button
                type="button"
                onClick={() => setNoteEditId(null)}
                className="h-9 border border-gold-soft/60 px-4 text-[12.5px] text-ink-soft"
              >
                Cancelar
              </button>
            </div>
          </div>
        ) : o.staffNote ? (
          <button
            type="button"
            onClick={() => startEditNote(o)}
            className="flex w-full items-start gap-2 border-l-2 border-navy bg-navy/[0.03] px-2.5 py-1.5 text-left"
          >
            <svg viewBox="0 0 24 24" className="mt-0.5 h-3.5 w-3.5 shrink-0 text-navy" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z" />
            </svg>
            <span className="flex-1 text-[12.5px] text-navy">{o.staffNote}</span>
            <span className="smallcaps shrink-0 text-[9px] text-gold-deep">Editar</span>
          </button>
        ) : (
          <button
            type="button"
            onClick={() => startEditNote(o)}
            className="flex items-center gap-1.5 text-[12px] font-medium text-gold-deep"
          >
            <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <path d="M12 5v14M5 12h14" />
            </svg>
            Agregar nota interna
          </button>
        )}
      </div>

      <div className="flex items-center justify-between gap-3 border-t border-gold-soft/25 px-4 py-2">
        <span className="text-[13px] font-semibold text-navy">Total {formatCOP(o.total)}</span>
        {o.status !== "recibido" && (
          <button
            type="button"
            onClick={() => revert(o)}
            className="text-[11.5px] text-ink-faint underline"
          >
            Deshacer
          </button>
        )}
      </div>

      {waLink(o) ? (
        <a
          href={waLink(o)!}
          target="_blank"
          rel="noopener noreferrer"
          className="flex h-11 w-full items-center justify-center gap-2 border-t border-gold-soft/25 bg-verde/10 text-[13.5px] font-semibold text-verde hover:bg-verde/15"
        >
          <svg viewBox="0 0 24 24" className="h-4 w-4" fill="currentColor" aria-hidden>
            <path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2Zm0 18.2c-1.5 0-3-.4-4.2-1.1l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2Zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8-.2-.1-.4-.1-.6.1-.2.2-.6.8-.8 1-.1.2-.3.2-.5.1a6.7 6.7 0 0 1-3.4-3c-.3-.4 0-.5.1-.7l.4-.5c.1-.2.2-.3.3-.5v-.5c0-.1-.5-1.4-.7-1.9-.2-.5-.4-.4-.6-.4h-.5c-.2 0-.5.1-.7.3-.2.3-.9.9-.9 2.2s.9 2.5 1.1 2.7c.1.2 1.9 2.9 4.6 4a15 15 0 0 0 1.5.6c.6.2 1.2.2 1.7.1.5-.1 1.5-.6 1.7-1.2.2-.6.2-1.1.2-1.2l-.4-.3Z" />
          </svg>
          Avisar por WhatsApp
        </a>
      ) : (
        o.customer.phone ? null : (
          <p className="border-t border-gold-soft/25 px-4 py-1.5 text-center text-[11px] text-ink-faint">
            Sin teléfono para avisar
          </p>
        )
      )}

      {NEXT[o.status] && (
        <button
          type="button"
          onClick={() => advance(o)}
          className="h-13 w-full bg-navy py-3.5 text-[15px] font-semibold text-gold-soft transition-transform hover:bg-navy/90 active:scale-[0.99]"
        >
          {NEXT_LABEL[o.status]}
        </button>
      )}
    </div>
  );

  return (
    <div>
      {/* Destello de pedido nuevo */}
      {flash && (
        <div className="pointer-events-none fixed inset-0 z-50 animate-pulse border-[6px] border-[#b3261e]" aria-hidden />
      )}

      {/* Controles: en vivo / historial por día */}
      <div className="mt-3 flex items-center justify-between gap-2 lg:mt-0">
        <div className="flex items-center gap-1.5">
          <h1 className="mr-2 hidden font-display text-[20px] text-navy lg:block">Pedidos</h1>
          <button
            type="button"
            onClick={() => setDay(null)}
            className={`smallcaps h-9 border px-3.5 text-[10.5px] font-medium ${
              live ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/60 bg-card text-ink-soft"
            }`}
          >
            En vivo
          </button>
          <input
            type="date"
            value={day ?? ""}
            max={todayBogota()}
            onChange={(e) => setDay(e.target.value || null)}
            aria-label="Ver pedidos de un día"
            className={`h-9 border bg-card px-2 text-[12.5px] text-ink-soft outline-none ${
              live ? "border-gold-soft/60" : "border-navy"
            }`}
          />
        </div>
        {live ? (
          <button
            type="button"
            onClick={() => setSoundOn((s) => !s)}
            className={`flex h-9 items-center gap-1.5 rounded-full border px-3 text-[11px] font-medium ${
              soundOn ? "border-verde/50 bg-verde/10 text-verde" : "border-ink-faint/40 text-ink-faint"
            }`}
            aria-pressed={soundOn}
          >
            <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              {soundOn ? (
                <>
                  <path d="M11 5 6 9H2v6h4l5 4V5Z" />
                  <path d="M15.5 8.5a5 5 0 0 1 0 7M19 5a9 9 0 0 1 0 14" />
                </>
              ) : (
                <>
                  <path d="M11 5 6 9H2v6h4l5 4V5Z" />
                  <path d="m23 9-6 6M17 9l6 6" />
                </>
              )}
            </svg>
            {soundOn ? "Sonido" : "Silencio"}
          </button>
        ) : (
          <p className="text-[12px] text-ink-faint">
            {orders.length} pedido{orders.length === 1 ? "" : "s"} · {formatCOP(dayTotal)}
          </p>
        )}
      </div>

      <p className="mt-2 text-[11px] text-ink-faint">
        {live ? (
          <>
            {active.length} activo{active.length === 1 ? "" : "s"}
            {connError && <span className="text-[#b3261e]"> · sin conexión</span>}
          </>
        ) : (
          <>Historial del {day}{connError && <span className="text-[#b3261e]"> · sin conexión</span>}</>
        )}
      </p>

      {/* Por confirmar pago — aparte de la cocina; al confirmar, entra a la cola */}
      {live && pending.length > 0 && (
        <section className="mt-4 rounded-lg border border-gold/50 bg-gold-soft/10 p-2.5 sm:p-3">
          <header className="mb-2.5 flex items-center gap-2 px-1">
            <span className="h-2.5 w-2.5 rounded-full bg-gold" />
            <h2 className="smallcaps text-[11px] font-semibold text-navy">Por confirmar pago</h2>
            <span className="ml-auto text-[11px] font-medium text-ink-faint">{pending.length}</span>
          </header>
          <p className="mb-3 px-1 text-[11.5px] leading-relaxed text-ink-soft">
            Estos pedidos aún no entran a la cocina. Cuando veas la plata en la cuenta o el
            comprobante, dale <b>Confirmar pago y preparar</b> y arrancan de una en preparación.
          </p>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {pending.map(pendingCard)}
          </div>
        </section>
      )}

      {/* Pedidos activos */}
      {active.length === 0 ? (
        <p className="mt-16 text-center text-[13px] text-ink-faint">
          {live ? (
            <>
              No hay pedidos por ahora.
              <br />
              Los nuevos aparecerán aquí automáticamente.
            </>
          ) : (
            "Sin pedidos activos ese día."
          )}
        </p>
      ) : (
        <>
          {/* Tablero por estado — escritorio */}
          <div className="mt-4 hidden gap-4 lg:grid lg:grid-cols-3 lg:items-start">
            {COLUMNS.map((col) => {
              const list = byStatus(col.status);
              return (
                <section key={col.status} className="rounded-lg bg-paper-deep/40 p-2.5">
                  <header className="mb-2.5 flex items-center gap-2 px-1">
                    <span className={`h-2.5 w-2.5 rounded-full ${col.dot}`} />
                    <h2 className="smallcaps text-[11px] font-semibold text-navy">{col.title}</h2>
                    <span className="ml-auto text-[11px] font-medium text-ink-faint">{list.length}</span>
                  </header>
                  <div className="flex flex-col gap-3">
                    {list.length === 0 ? (
                      <p className="px-1 py-6 text-center text-[11.5px] text-ink-faint/70">Sin pedidos</p>
                    ) : (
                      list.map(card)
                    )}
                  </div>
                </section>
              );
            })}
          </div>

          {/* Lista única — móvil */}
          <div className="mx-auto mt-3 flex max-w-2xl flex-col gap-3 lg:hidden">
            {active
              .slice()
              .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
              .map(card)}
          </div>
        </>
      )}

      {/* Recogidos */}
      {done.length > 0 && (
        <div className="mt-8">
          <p className="smallcaps mb-2 text-[10px] text-ink-faint">
            {live ? "Recogidos hoy" : "Recogidos"}
          </p>
          <div className="grid gap-1.5 sm:grid-cols-2 lg:grid-cols-3">
            {done
              .slice()
              .sort((a, b) => b.statusAt.localeCompare(a.statusAt))
              .map((o) => (
                <div
                  key={o.id}
                  className="flex items-center justify-between border border-gold-soft/30 bg-paper/60 px-4 py-2 text-[13px] text-ink-faint"
                >
                  <span>
                    <span className="font-semibold text-ink-soft">#{o.code}</span> {o.customer.name}
                    <span className="ml-2 text-[11.5px]">{formatCOP(o.total)}</span>
                  </span>
                  <button type="button" onClick={() => revert(o)} className="text-[11px] underline">
                    Reabrir
                  </button>
                </div>
              ))}
          </div>
        </div>
      )}
    </div>
  );
}

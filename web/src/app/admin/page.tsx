"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { formatCOP } from "@/lib/format";
import { STATUS_LABEL, type Order, type OrderStatus } from "@/lib/orders";

const CODE_KEY = "panisse-staff-code";
const POLL_MS = 4000;

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
  const msg: Record<OrderStatus, string> = {
    recibido: `${hola} Recibimos tu pedido #${o.code} en PANISSE. ✅ Te avisamos cuando esté listo.`,
    preparacion: `${hola} Tu pedido #${o.code} en PANISSE ya está en preparación. 👨‍🍳`,
    listo: `${hola} Tu pedido #${o.code} en PANISSE ya está listo para recoger. 🎉 ¡Te esperamos!`,
    recogido: `¡Gracias por tu compra${name ? `, ${name}` : ""}! 🙌 Te esperamos pronto en PANISSE.`,
  };
  return msg[o.status];
}
function waLink(o: Order): string | null {
  const phone = waPhone(o.customer.phone);
  if (!phone) return null;
  return `https://wa.me/${phone}?text=${encodeURIComponent(waMessage(o))}`;
}

export default function AdminPage() {
  const [code, setCode] = useState("");
  const [authed, setAuthed] = useState(false);
  const [input, setInput] = useState("");
  const [orders, setOrders] = useState<Order[]>([]);
  const [loginError, setLoginError] = useState("");
  const [connError, setConnError] = useState(false);
  const [flash, setFlash] = useState(false);
  const [soundOn, setSoundOn] = useState(true);

  const seenIds = useRef<Set<string>>(new Set());
  const audioCtx = useRef<AudioContext | null>(null);
  const firstLoad = useRef(true);

  useEffect(() => {
    document.title = "Panel de pedidos · PANISSE";
    const saved = localStorage.getItem(CODE_KEY);
    if (saved) {
      setCode(saved);
      setAuthed(true);
    }
  }, []);

  const beep = useCallback(() => {
    if (!soundOn) return;
    try {
      const ctx = audioCtx.current;
      if (!ctx) return;
      const play = (freq: number, start: number) => {
        const o = ctx.createOscillator();
        const g = ctx.createGain();
        o.connect(g);
        g.connect(ctx.destination);
        o.frequency.value = freq;
        o.type = "sine";
        g.gain.setValueAtTime(0.0001, ctx.currentTime + start);
        g.gain.exponentialRampToValueAtTime(0.35, ctx.currentTime + start + 0.02);
        g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + start + 0.35);
        o.start(ctx.currentTime + start);
        o.stop(ctx.currentTime + start + 0.36);
      };
      play(880, 0);
      play(1174, 0.18);
    } catch {
      /* ignore */
    }
  }, [soundOn]);

  const poll = useCallback(async (staffCode: string) => {
    try {
      const res = await fetch("/api/orders", { headers: { "x-staff-code": staffCode } });
      if (res.status === 401) {
        localStorage.removeItem(CODE_KEY);
        setAuthed(false);
        setCode("");
        setLoginError("La clave ya no es válida. Ingresa de nuevo.");
        return;
      }
      const data = await res.json();
      setConnError(false);
      const list: Order[] = data.orders || [];

      // Detecta pedidos nuevos (excepto en la primera carga)
      const currentIds = new Set(list.map((o) => o.id));
      if (!firstLoad.current) {
        const hasNew = list.some((o) => !seenIds.current.has(o.id) && o.status === "recibido");
        if (hasNew) {
          beep();
          setFlash(true);
          setTimeout(() => setFlash(false), 2500);
        }
      }
      seenIds.current = currentIds;
      firstLoad.current = false;
      setOrders(list);
    } catch {
      setConnError(true);
    }
  }, [beep]);

  // Polling
  useEffect(() => {
    if (!authed || !code) return;
    firstLoad.current = true;
    seenIds.current = new Set();
    poll(code);
    const iv = setInterval(() => poll(code), POLL_MS);
    return () => clearInterval(iv);
  }, [authed, code, poll]);

  const login = async () => {
    setLoginError("");
    const c = input.trim();
    if (!c) return;
    // Verifica contra el servidor con una consulta real
    try {
      const res = await fetch("/api/orders", { headers: { "x-staff-code": c } });
      if (res.status === 401) {
        setLoginError("Clave incorrecta.");
        return;
      }
      // Activa audio dentro del gesto del usuario
      try {
        audioCtx.current = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
      } catch {
        /* sin audio */
      }
      localStorage.setItem(CODE_KEY, c);
      setCode(c);
      setAuthed(true);
    } catch {
      setLoginError("No se pudo conectar. Revisa tu internet.");
    }
  };

  const advance = async (order: Order) => {
    const next = NEXT[order.status];
    if (!next) return;
    // Optimista
    setOrders((prev) => prev.map((o) => (o.id === order.id ? { ...o, status: next } : o)));
    try {
      await fetch("/api/orders/status", {
        method: "POST",
        headers: { "content-type": "application/json", "x-staff-code": code },
        body: JSON.stringify({ id: order.id, status: next }),
      });
    } catch {
      poll(code); // recarga si falla
    }
  };

  const revert = async (order: Order) => {
    const order_flow: OrderStatus[] = ["recibido", "preparacion", "listo", "recogido"];
    const idx = order_flow.indexOf(order.status);
    if (idx <= 0) return;
    const prevStatus = order_flow[idx - 1];
    setOrders((prev) => prev.map((o) => (o.id === order.id ? { ...o, status: prevStatus } : o)));
    try {
      await fetch("/api/orders/status", {
        method: "POST",
        headers: { "content-type": "application/json", "x-staff-code": code },
        body: JSON.stringify({ id: order.id, status: prevStatus }),
      });
    } catch {
      poll(code);
    }
  };

  // ── Login ──
  if (!authed) {
    return (
      <div className="mx-auto flex min-h-dvh max-w-sm flex-col justify-center px-8">
        <h1 className="text-center font-display text-[26px] text-navy">PANISSE</h1>
        <p className="mt-1 text-center text-[13px] text-ink-faint">Panel de pedidos</p>
        <input
          type="password"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && login()}
          placeholder="Clave de acceso"
          className="mt-8 h-12 w-full border border-gold-soft/70 bg-card px-4 text-center text-[16px] tracking-wide text-ink outline-none focus:border-navy"
          autoFocus
        />
        {loginError && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{loginError}</p>}
        <button
          type="button"
          onClick={login}
          className="mt-4 h-12 w-full bg-navy text-[14px] font-semibold text-gold-soft"
        >
          Entrar
        </button>
      </div>
    );
  }

  const active = orders.filter((o) => o.status !== "recogido");
  const done = orders.filter((o) => o.status === "recogido");

  return (
    <div className="mx-auto min-h-dvh max-w-2xl px-3 pb-16">
      {/* Destello de pedido nuevo */}
      {flash && (
        <div className="pointer-events-none fixed inset-0 z-50 animate-pulse border-[6px] border-[#b3261e]" aria-hidden />
      )}

      {/* Encabezado */}
      <header className="sticky top-0 z-20 -mx-3 flex items-center justify-between border-b border-gold-soft/50 bg-paper/95 px-4 py-3 backdrop-blur-md">
        <div>
          <h1 className="font-display text-[18px] leading-none text-navy">Pedidos</h1>
          <p className="mt-0.5 text-[11px] text-ink-faint">
            {active.length} activo{active.length === 1 ? "" : "s"}
            {connError && <span className="text-[#b3261e]"> · sin conexión</span>}
          </p>
        </div>
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
      </header>

      {/* Lista de pedidos activos */}
      {active.length === 0 ? (
        <p className="mt-16 text-center text-[13px] text-ink-faint">
          No hay pedidos por ahora.
          <br />
          Los nuevos aparecerán aquí automáticamente.
        </p>
      ) : (
        <ul className="mt-3 flex flex-col gap-3">
          {active
            .slice()
            .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
            .map((o) => (
              <li
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

                <ul className="mt-3 border-t border-gold-soft/25 px-4 py-2.5 text-[13.5px] text-ink">
                  {o.items.map((it, i) => (
                    <li key={i} className="flex justify-between gap-2 py-0.5">
                      <span>
                        <span className="font-semibold text-navy">{it.qty}×</span> {it.name}
                        {it.variant && <span className="text-ink-faint"> · {it.variant}</span>}
                      </span>
                      <span className="shrink-0 text-ink-soft">{formatCOP(it.unitPrice * it.qty)}</span>
                    </li>
                  ))}
                </ul>

                {o.customer.note && (
                  <p className="mx-4 mb-1 border-l-2 border-gold px-2.5 py-1 text-[12.5px] italic text-ink-soft">
                    “{o.customer.note}”
                  </p>
                )}

                <div className="flex items-center justify-between gap-3 border-t border-gold-soft/25 px-4 py-2">
                  <span className="text-[13px] font-semibold text-navy">
                    Total {formatCOP(o.total)}
                  </span>
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
                    className="flex h-11 w-full items-center justify-center gap-2 border-t border-gold-soft/25 bg-verde/10 text-[13.5px] font-semibold text-verde"
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
                    className="h-13 w-full bg-navy py-3.5 text-[15px] font-semibold text-gold-soft transition-transform active:scale-[0.99]"
                  >
                    {NEXT_LABEL[o.status]}
                  </button>
                )}
              </li>
            ))}
        </ul>
      )}

      {/* Recogidos recientes */}
      {done.length > 0 && (
        <div className="mt-8">
          <p className="smallcaps mb-2 text-[10px] text-ink-faint">Recogidos hoy</p>
          <ul className="flex flex-col gap-1.5">
            {done
              .slice()
              .sort((a, b) => b.statusAt.localeCompare(a.statusAt))
              .map((o) => (
                <li
                  key={o.id}
                  className="flex items-center justify-between border border-gold-soft/30 bg-paper/60 px-4 py-2 text-[13px] text-ink-faint"
                >
                  <span>
                    <span className="font-semibold text-ink-soft">#{o.code}</span> {o.customer.name}
                  </span>
                  <button type="button" onClick={() => revert(o)} className="text-[11px] underline">
                    Reabrir
                  </button>
                </li>
              ))}
          </ul>
        </div>
      )}
    </div>
  );
}

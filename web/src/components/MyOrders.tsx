"use client";

import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { useMyOrders } from "@/lib/myOrders";
import { STATUS_LABEL, type OrderStatus } from "@/lib/orders";
import { useScrollLock } from "@/lib/scrollLock";
import StatusTrack from "./StatusTrack";

const DOT: Record<OrderStatus, string> = {
  recibido: "bg-gold-deep",
  preparacion: "bg-gold-deep",
  listo: "bg-verde",
  recogido: "bg-ink-faint",
};

export default function MyOrders() {
  const { orders, dismiss } = useMyOrders();
  const [open, setOpen] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  const active = orders.filter((o) => o.status !== "recogido");

  // Cierra la hoja si ya no hay pedidos que mostrar
  useEffect(() => {
    if (orders.length === 0) setOpen(false);
  }, [orders.length]);

  // Congela el fondo mientras la hoja está abierta
  useScrollLock(open);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  if (active.length === 0) return null;
  const latest = active[0];

  // La hoja se renderiza con un portal al <body> para que NO quede atrapada
  // dentro del encabezado fijo (que usa backdrop-blur y crea un bloque contenedor).
  const sheet = (
    <div className="fixed inset-0 z-[60]" role="dialog" aria-modal="true" aria-label="Mis pedidos">
      <button
        type="button"
        aria-label="Cerrar"
        onClick={() => setOpen(false)}
        className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]"
      />
      <div className="anim-sheet-up absolute inset-x-0 bottom-0 mx-auto max-w-md">
        <div className="max-h-[85dvh] overflow-y-auto rounded-t-3xl bg-card pb-[calc(env(safe-area-inset-bottom)+22px)] shadow-[0_-12px_40px_rgba(4,17,29,0.25)]">
          <div className="sticky top-0 z-10 flex items-center justify-between border-b border-gold-soft/40 bg-card px-5 pb-3.5 pt-4">
            <span className="w-8" />
            <h3 className="font-display text-[19px] text-navy">Mis pedidos</h3>
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Cerrar"
              className="flex h-8 w-8 items-center justify-center rounded-full text-ink-soft active:bg-paper-deep"
            >
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
                <path d="M6 6l12 12M18 6 6 18" />
              </svg>
            </button>
          </div>

          <div className="flex flex-col gap-4 px-5 pt-4">
            {orders.map((o) => (
              <div key={o.id} className="border border-gold-soft/50 bg-paper px-4 py-4">
                <div className="flex items-center justify-between">
                  <p className="font-display text-[22px] leading-none text-navy">#{o.code}</p>
                  {o.status === "recogido" ? (
                    <span className="smallcaps flex items-center gap-1 text-[10px] text-verde">
                      <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                        <path d="M20 6 9 17l-5-5" />
                      </svg>
                      Recogido
                    </span>
                  ) : (
                    <span className="smallcaps text-[10px] text-gold-deep">{STATUS_LABEL[o.status]}</span>
                  )}
                </div>

                {o.status === "recogido" ? (
                  <div className="mt-3 flex items-center justify-between">
                    <p className="text-[12.5px] text-ink-soft">¡Gracias! Ya recogiste este pedido.</p>
                    <button type="button" onClick={() => dismiss(o.id)} className="text-[11.5px] text-ink-faint underline">
                      Quitar
                    </button>
                  </div>
                ) : (
                  <>
                    <StatusTrack status={o.status} />
                    {o.status === "listo" && (
                      <p className="mt-3 text-center text-[12.5px] font-medium text-verde">
                        ¡Tu pedido está listo! Pásalo a recoger en tienda.
                      </p>
                    )}
                  </>
                )}
              </div>
            ))}
            <p className="pb-1 text-center text-[11px] text-ink-faint">
              El estado se actualiza solo. Muestra tu número en tienda para recoger.
            </p>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <>
      {/* Aviso dentro del encabezado fijo */}
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="flex w-full items-center gap-2.5 border-t border-gold-soft/40 bg-gold-soft/12 px-4 py-2 text-left"
      >
        <span className="relative flex h-2.5 w-2.5 shrink-0">
          <span className={`absolute inline-flex h-full w-full animate-ping rounded-full opacity-60 ${DOT[latest.status]}`} />
          <span className={`relative inline-flex h-2.5 w-2.5 rounded-full ${DOT[latest.status]}`} />
        </span>
        <span className="min-w-0 flex-1 truncate text-[12.5px] text-navy">
          <span className="font-semibold">Tu pedido #{latest.code}</span>
          <span className="text-ink-soft"> · {STATUS_LABEL[latest.status]}</span>
          {active.length > 1 && <span className="text-ink-faint"> · +{active.length - 1} más</span>}
        </span>
        <span className="smallcaps shrink-0 text-[9.5px] text-gold-deep">Ver</span>
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 shrink-0 text-gold" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
          <path d="m9 6 6 6-6 6" />
        </svg>
      </button>

      {/* Hoja de seguimiento (portal al body para escapar del encabezado) */}
      {open && mounted && createPortal(sheet, document.body)}
    </>
  );
}

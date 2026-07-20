"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import { useCart } from "@/lib/cart";
import { useMyOrders } from "@/lib/myOrders";
import { formatCOP } from "@/lib/format";
import { checkClient, createOrder, getOrderStatus, EMAIL_RE, type CreatedOrder } from "@/lib/api";
import { type OrderStatus } from "@/lib/orders";
import StatusTrack from "./StatusTrack";

type View = "hidden" | "cart" | "checkout" | "done";

export default function CartBar() {
  const cart = useCart();
  const { addOrder } = useMyOrders();
  const [view, setView] = useState<View>("hidden");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [note, setNote] = useState("");
  const [email, setEmail] = useState("");
  const [birthday, setBirthday] = useState("");
  // null = aún no verificamos el correo; luego {known, name?} del servidor
  const [known, setKnown] = useState<{ known: boolean; name?: string } | null>(null);
  const [checking, setChecking] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  const [order, setOrder] = useState<CreatedOrder | null>(null);
  const [liveStatus, setLiveStatus] = useState<OrderStatus>("recibido");

  const open = view !== "hidden";

  // Bloquea el scroll del fondo cuando el panel está abierto
  useEffect(() => {
    document.documentElement.classList.toggle("scroll-locked", open);
    return () => document.documentElement.classList.remove("scroll-locked");
  }, [open]);

  // Seguimiento en vivo del pedido tras enviarlo
  useEffect(() => {
    if (view !== "done" || !order) return;
    let stop = false;
    const tick = async () => {
      if (document.hidden) return; // no chequear con la pantalla apagada
      try {
        const s = await getOrderStatus(order.id);
        if (!stop && s) setLiveStatus(s.status);
      } catch {
        /* reintenta en el próximo ciclo */
      }
    };
    tick();
    const iv = setInterval(tick, 6000);
    return () => {
      stop = true;
      clearInterval(iv);
    };
  }, [view, order]);

  // Paso 1 del checkout: verificar el correo. Si el cliente ya existe,
  // el servidor completa sus datos y no se le vuelven a pedir.
  const checkEmail = async () => {
    setError("");
    const e = email.trim();
    if (!EMAIL_RE.test(e)) {
      setError("Escribe un correo válido");
      return;
    }
    setChecking(true);
    try {
      setKnown(await checkClient(e));
    } catch {
      setError("No se pudo verificar el correo. Revisa tu internet.");
    } finally {
      setChecking(false);
    }
  };

  const submit = async () => {
    setError("");
    if (!known) return;
    if (!known.known) {
      if (!name.trim()) {
        setError("Escribe tu nombre para el pedido");
        return;
      }
      if (!birthday) {
        setError("Cuéntanos tu cumpleaños para sorprenderte");
        return;
      }
    }
    setSending(true);
    try {
      const created = await createOrder(
        {
          email: email.trim(),
          note: note.trim(),
          name: known.known ? undefined : name.trim(),
          phone: known.known ? undefined : phone.trim(),
          birthday: known.known ? undefined : birthday,
        },
        cart.lines,
      );
      setOrder(created);
      setLiveStatus("recibido");
      addOrder({ id: created.id, code: created.code }); // queda guardado para que el cliente lo siga viendo
      cart.clear();
      setView("done");
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudo enviar el pedido");
    } finally {
      setSending(false);
    }
  };

  const closeAll = () => {
    setView("hidden");
    setName("");
    setPhone("");
    setNote("");
    setEmail("");
    setBirthday("");
    setKnown(null);
    setError("");
    setOrder(null);
  };

  return (
    <>
      {/* Barra flotante */}
      {cart.count > 0 && view === "hidden" && (
        <button
          type="button"
          onClick={() => setView("cart")}
          className="anim-fade-up fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md items-center justify-between gap-3 bg-navy px-5 py-3.5 pb-[calc(env(safe-area-inset-bottom)+14px)] text-gold-soft shadow-[0_-8px_24px_rgba(4,17,29,0.28)]"
        >
          <span className="flex items-center gap-2.5">
            <span className="flex h-7 min-w-7 items-center justify-center rounded-full bg-gold-soft px-1.5 text-[13px] font-bold text-navy">
              {cart.count}
            </span>
            <span className="text-[14px] font-medium">Ver mi pedido</span>
          </span>
          <span className="font-display text-[17px] font-semibold">{formatCOP(cart.total)}</span>
        </button>
      )}

      {open && (
        <div className="fixed inset-0 z-50" role="dialog" aria-modal="true" aria-label="Mi pedido">
          <button
            type="button"
            aria-label="Cerrar"
            onClick={view === "done" ? closeAll : () => setView("hidden")}
            className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]"
          />
          <div className="anim-sheet-up absolute inset-x-0 bottom-0 mx-auto max-w-md">
            <div className="max-h-[90dvh] overflow-y-auto rounded-t-3xl bg-card pb-[calc(env(safe-area-inset-bottom)+20px)] shadow-[0_-12px_40px_rgba(4,17,29,0.25)]">
              {/* Encabezado */}
              <div className="sticky top-0 z-10 flex items-center justify-between border-b border-gold-soft/40 bg-card px-5 pb-3.5 pt-4">
                <button
                  type="button"
                  onClick={
                    view === "checkout"
                      ? () => setView("cart")
                      : view === "done"
                        ? closeAll
                        : () => setView("hidden")
                  }
                  className="flex h-8 w-8 items-center justify-center rounded-full text-ink-soft active:bg-paper-deep"
                  aria-label={view === "checkout" ? "Volver" : "Cerrar"}
                >
                  <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                    {view === "checkout" ? <path d="M15 5l-7 7 7 7" /> : <path d="M6 6l12 12M18 6 6 18" />}
                  </svg>
                </button>
                <h3 className="font-display text-[19px] text-navy">
                  {view === "cart" ? "Mi pedido" : view === "checkout" ? "Tus datos" : "¡Pedido enviado!"}
                </h3>
                {view === "cart" && cart.lines.length > 0 ? (
                  <button
                    type="button"
                    onClick={() => cart.clear()}
                    className="text-[12px] font-medium text-ink-faint underline underline-offset-2"
                  >
                    Vaciar
                  </button>
                ) : (
                  <span className="w-8" />
                )}
              </div>

              {/* ── Vista carrito ── */}
              {view === "cart" && (
                <div className="px-5 pt-3">
                  {cart.lines.length === 0 ? (
                    <p className="py-12 text-center text-[13px] text-ink-faint">
                      Tu pedido está vacío.
                    </p>
                  ) : (
                    <>
                      <ul className="divide-y divide-gold-soft/25">
                        {cart.lines.map((l) => (
                          <li key={`${l.productId}::${l.variant}::${l.note}`} className="flex items-start gap-3 py-3">
                            {l.image ? (
                              <div className="relative h-14 w-14 shrink-0 overflow-hidden border border-gold-soft/50">
                                <Image src={l.image} alt={l.name} fill sizes="56px" className="object-cover" />
                              </div>
                            ) : (
                              <div className="h-14 w-14 shrink-0 border border-gold-soft/40 bg-paper-deep" />
                            )}
                            <div className="min-w-0 flex-1">
                              <p className="font-display text-[15px] leading-snug text-navy">{l.name}</p>
                              {l.variant && <p className="text-[11.5px] text-ink-faint">{l.variant}</p>}
                              {l.note && (
                                <p className="mt-0.5 border-l-2 border-gold pl-1.5 text-[11.5px] italic text-ink-soft">
                                  {l.note}
                                </p>
                              )}
                              <p className="mt-0.5 text-[13px] font-semibold text-gold-deep">
                                {formatCOP(l.unitPrice)}
                              </p>
                            </div>
                            <div className="flex shrink-0 items-center border border-gold-soft/70">
                              <button
                                type="button"
                                aria-label="Quitar uno"
                                onClick={() => cart.setQty(l.productId, l.variant, l.note, l.qty - 1)}
                                className="flex h-9 w-9 items-center justify-center text-[18px] text-ink-soft active:bg-gold-soft/20"
                              >
                                −
                              </button>
                              <span className="w-7 text-center font-display text-[15px] text-navy">{l.qty}</span>
                              <button
                                type="button"
                                aria-label="Agregar uno"
                                onClick={() => cart.setQty(l.productId, l.variant, l.note, l.qty + 1)}
                                className="flex h-9 w-9 items-center justify-center text-[18px] text-ink-soft active:bg-gold-soft/20"
                              >
                                +
                              </button>
                            </div>
                          </li>
                        ))}
                      </ul>
                      <div className="mt-3 flex items-baseline justify-between border-t border-gold-soft/40 pt-4">
                        <span className="smallcaps text-[11px] text-ink-soft">Total</span>
                        <span className="font-display text-[22px] font-semibold text-navy">
                          {formatCOP(cart.total)}
                        </span>
                      </div>
                      <button
                        type="button"
                        onClick={() => setView("checkout")}
                        className="mt-4 h-12 w-full bg-navy text-[14px] font-semibold text-gold-soft transition-transform active:scale-[0.98]"
                      >
                        Continuar
                      </button>
                      <p className="mt-3 text-center text-[11px] text-ink-faint">
                        Pedido para recoger en tienda · pagas al recoger
                      </p>
                    </>
                  )}
                </div>
              )}

              {/* ── Vista checkout: primero el correo; si ya es cliente,
                     no se le vuelve a pedir nada ── */}
              {view === "checkout" && (
                <div className="px-5 pt-4">
                  <label className="block">
                    <span className="smallcaps text-[10px] text-gold-deep">Correo *</span>
                    <input
                      value={email}
                      onChange={(e) => {
                        setEmail(e.target.value);
                        setKnown(null);
                      }}
                      onKeyDown={(e) => e.key === "Enter" && !known && checkEmail()}
                      placeholder="tucorreo@ejemplo.com"
                      inputMode="email"
                      autoComplete="email"
                      autoFocus
                      className="mt-1 h-12 w-full border border-gold-soft/70 bg-paper px-3.5 text-[15px] text-ink outline-none focus:border-navy"
                    />
                  </label>

                  {!known ? (
                    <>
                      <p className="mt-2 text-[11.5px] text-ink-faint">
                        Si ya has pedido antes, con tu correo recuperamos tus datos.
                      </p>
                      {error && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{error}</p>}
                      <button
                        type="button"
                        onClick={checkEmail}
                        disabled={checking}
                        className="mt-4 h-12 w-full bg-navy text-[14px] font-semibold text-gold-soft transition-transform active:scale-[0.98] disabled:opacity-60"
                      >
                        {checking ? "Verificando…" : "Continuar"}
                      </button>
                    </>
                  ) : (
                    <>
                      {known.known ? (
                        <div className="mt-3.5 border-l-2 border-verde bg-verde/10 px-3 py-2.5">
                          <p className="text-[13.5px] font-medium text-ink">
                            ¡Hola de nuevo{known.name ? `, ${known.name.trim().split(" ")[0]}` : ""}! 👋
                          </p>
                          <p className="mt-0.5 text-[11.5px] text-ink-soft">
                            Ya tenemos tus datos guardados; no hace falta nada más.
                          </p>
                        </div>
                      ) : (
                        <>
                          <label className="mt-3.5 block">
                            <span className="smallcaps text-[10px] text-gold-deep">Nombre *</span>
                            <input
                              value={name}
                              onChange={(e) => setName(e.target.value)}
                              placeholder="Tu nombre"
                              autoComplete="name"
                              autoFocus
                              className="mt-1 h-12 w-full border border-gold-soft/70 bg-paper px-3.5 text-[15px] text-ink outline-none focus:border-navy"
                            />
                          </label>
                          <label className="mt-3.5 block">
                            <span className="smallcaps text-[10px] text-gold-deep">Teléfono</span>
                            <input
                              value={phone}
                              onChange={(e) => setPhone(e.target.value)}
                              placeholder="Para avisarte por WhatsApp cuando esté listo"
                              inputMode="tel"
                              autoComplete="tel"
                              className="mt-1 h-12 w-full border border-gold-soft/70 bg-paper px-3.5 text-[15px] text-ink outline-none focus:border-navy"
                            />
                          </label>
                          <label className="mt-3.5 block">
                            <span className="smallcaps text-[10px] text-gold-deep">Cumpleaños *</span>
                            <input
                              type="date"
                              value={birthday}
                              onChange={(e) => setBirthday(e.target.value)}
                              max={new Date().toISOString().slice(0, 10)}
                              className="mt-1 h-12 w-full border border-gold-soft/70 bg-paper px-3.5 text-[15px] text-ink outline-none focus:border-navy"
                            />
                            <span className="mt-1 block text-[11px] text-ink-faint">
                              Para consentirte en tu día 🎂
                            </span>
                          </label>
                        </>
                      )}

                      <label className="mt-3.5 block">
                        <span className="smallcaps text-[10px] text-gold-deep">Nota (opcional)</span>
                        <textarea
                          value={note}
                          onChange={(e) => setNote(e.target.value)}
                          placeholder="Ej. sin cebolla, término medio…"
                          rows={2}
                          className="mt-1 w-full resize-none border border-gold-soft/70 bg-paper px-3.5 py-2.5 text-[15px] text-ink outline-none focus:border-navy"
                        />
                      </label>

                      <div className="mt-4 flex items-baseline justify-between border-t border-gold-soft/40 pt-4">
                        <span className="smallcaps text-[11px] text-ink-soft">Total a pagar en tienda</span>
                        <span className="font-display text-[20px] font-semibold text-navy">{formatCOP(cart.total)}</span>
                      </div>

                      {error && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{error}</p>}

                      <button
                        type="button"
                        onClick={submit}
                        disabled={sending}
                        className="mt-4 h-12 w-full bg-navy text-[14px] font-semibold text-gold-soft transition-transform active:scale-[0.98] disabled:opacity-60"
                      >
                        {sending ? "Enviando…" : "Enviar pedido para recoger"}
                      </button>
                    </>
                  )}
                </div>
              )}

              {/* ── Vista confirmación ── */}
              {view === "done" && order && (
                <div className="px-6 pb-2 pt-6 text-center">
                  <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-verde/12 text-verde">
                    <svg viewBox="0 0 24 24" className="h-7 w-7" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                      <path d="M20 6 9 17l-5-5" />
                    </svg>
                  </div>
                  <p className="mt-4 text-[13px] text-ink-soft">Tu número de pedido</p>
                  <p className="font-display text-[44px] font-semibold leading-none text-navy">#{order.code}</p>
                  <p className="mt-3 text-[13px] leading-relaxed text-ink-soft">
                    Muéstralo en tienda para recoger. Te avisamos cuando esté listo.
                  </p>

                  <div className="mt-5 border border-gold-soft/50 bg-paper px-4 py-4">
                    <p className="smallcaps text-[10px] text-gold-deep">Estado</p>
                    <StatusTrack status={liveStatus} />
                  </div>

                  <button
                    type="button"
                    onClick={closeAll}
                    className="mt-5 h-12 w-full border border-gold-soft/70 bg-card text-[14px] font-medium text-ink-soft"
                  >
                    Seguir viendo el menú
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}

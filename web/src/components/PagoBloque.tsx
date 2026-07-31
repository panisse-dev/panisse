"use client";

// Bloque de pago del cliente: portal de Davivienda, transferencia a la
// cuenta con su QR, y el botón para avisar por WhatsApp con el
// comprobante.
//
// Vive en un solo sitio a propósito: lo usan el pedido y la reserva con
// decoración, así el número de cuenta, el QR y el portal se cambian una
// sola vez y quedan iguales en todas partes.

import { useState } from "react";
import { formatCOP } from "@/lib/format";
import { restaurant } from "@/lib/menu";
import { BANK_TRANSFER, DAVIVIENDA_PAYMENT_URL } from "@/lib/payment";

/** Copia al portapapeles. Cae a execCommand en los navegadores dentro de
    Instagram o WhatsApp, que bloquean la Clipboard API. */
function copiar(text: string, flash: () => void) {
  const fallback = () => {
    try {
      const ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.focus();
      ta.select();
      if (document.execCommand("copy")) flash();
      document.body.removeChild(ta);
    } catch {
      /* si falla, el cliente puede escribir el dato a mano */
    }
  };
  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(text).then(flash, fallback);
  } else {
    fallback();
  }
}

export default function PagoBloque({
  total,
  titulo = "Paga tu pedido",
  resumen,
  nombre,
  whatsapp,
  avisoWhatsApp = "Ya pagué mi pedido 🧾",
  nota = "Pon tu nombre como referencia.",
}: {
  /** Cuánto hay que pagar. */
  total: number;
  /** Rótulo de arriba del bloque. */
  titulo?: string;
  /** Qué se está pagando, para el mensaje de WhatsApp. */
  resumen: string;
  /** Nombre del cliente, si se conoce. */
  nombre?: string;
  /** WhatsApp de la sede; si no viene, el del restaurante. */
  whatsapp?: string;
  /** Primera línea del mensaje de WhatsApp. */
  avisoWhatsApp?: string;
  /** Aclaración de abajo. */
  nota?: string;
}) {
  const [copiado, setCopiado] = useState(false);
  const [copiadaCuenta, setCopiadaCuenta] = useState(false);

  const marca = (set: (v: boolean) => void) => () => {
    set(true);
    window.setTimeout(() => set(false), 2500);
  };

  // Sin puntos ni símbolos (ej. "50000"): el portal pide un número y el
  // cliente solo lo pega.
  const copiarValor = () => copiar(String(total), marca(setCopiado));
  const copiarCuenta = () => copiar(BANK_TRANSFER.number, marca(setCopiadaCuenta));

  const tel = (whatsapp || restaurant.whatsapp).replace(/\D/g, "");
  const mensaje = encodeURIComponent(
    `¡Hola PANISSE! ${avisoWhatsApp}${nombre ? `\n\nA nombre de: ${nombre}` : ""}\n\n${resumen}\n\nTotal: ${formatCOP(
      total,
    )}\n\nAdjunto el comprobante de pago 👇`,
  );

  return (
    <div className="mt-4 border-2 border-gold-soft bg-paper px-4 py-4 text-left">
      <p className="smallcaps text-[10px] text-gold-deep">{titulo}</p>
      <div className="mt-2 flex items-center justify-between gap-3">
        <div>
          <p className="text-[11px] text-ink-faint">Total a pagar</p>
          <p className="font-display text-[22px] font-semibold leading-none text-navy">
            {formatCOP(total)}
          </p>
        </div>
        <button
          type="button"
          onClick={copiarValor}
          className="h-9 shrink-0 border border-gold-soft/70 px-3 text-[12.5px] font-medium text-ink-soft active:bg-gold-soft/20"
        >
          {copiado ? "¡Copiado!" : "Copiar valor"}
        </button>
      </div>

      {/* Opción 1: portal de Davivienda */}
      <a
        href={DAVIVIENDA_PAYMENT_URL}
        target="_blank"
        rel="noopener noreferrer"
        onClick={copiarValor}
        className="mt-3 flex h-12 w-full items-center justify-center bg-navy text-[14px] font-semibold text-gold-soft transition-transform active:scale-[0.98]"
      >
        Pagar con Davivienda
      </a>

      <div className="my-3 flex items-center gap-2 text-[10px] text-ink-faint">
        <span className="h-px flex-1 bg-gold-soft/40" />
        <span className="smallcaps">o por transferencia</span>
        <span className="h-px flex-1 bg-gold-soft/40" />
      </div>

      {/* Opción 2: transferencia directa a la cuenta */}
      <div className="border border-gold-soft/50 bg-card px-3.5 py-3">
        <p className="text-[12px] text-ink-soft">
          {BANK_TRANSFER.bank} · {BANK_TRANSFER.type}
        </p>
        <div className="mt-1 flex items-center justify-between gap-3">
          <p className="font-display text-[19px] font-semibold leading-none tracking-wide text-navy">
            {BANK_TRANSFER.number}
          </p>
          <button
            type="button"
            onClick={copiarCuenta}
            className="h-9 shrink-0 border border-gold-soft/70 px-3 text-[12.5px] font-medium text-ink-soft active:bg-gold-soft/20"
          >
            {copiadaCuenta ? "¡Copiado!" : "Copiar número"}
          </button>
        </div>
        <p className="mt-1.5 text-[11px] text-ink-faint">
          A nombre de <b>{BANK_TRANSFER.holder}</b>
        </p>

        {/* QR: se escanea con la app de cualquier banco o billetera. */}
        <div className="mt-3 border-t border-gold-soft/30 pt-3">
          <p className="text-center text-[11.5px] text-ink-soft">
            O escanéalo con la app de tu banco o billetera
          </p>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/pago-qr.svg"
            alt="Código QR para pagar a PANISSE con cualquier banco o billetera"
            width={200}
            height={200}
            className="mx-auto mt-2 h-44 w-44 bg-white p-2"
          />
          <p className="mt-1.5 text-center text-[10.5px] text-ink-faint">
            Nequi · Daviplata · Bancolombia · BBVA y más
          </p>
        </div>
      </div>

      {nota && <p className="mt-3 text-[11px] leading-relaxed text-ink-faint">{nota}</p>}

      {/* Aviso de pago: abre WhatsApp con todo escrito; el cliente solo
          adjunta el comprobante y envía. */}
      <a
        href={`https://wa.me/${tel}?text=${mensaje}`}
        target="_blank"
        rel="noopener noreferrer"
        className="mt-3 flex h-12 w-full items-center justify-center gap-2 bg-verde text-[14px] font-semibold text-white transition-transform active:scale-[0.98]"
      >
        <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor" aria-hidden>
          <path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2Zm0 18.2c-1.5 0-3-.4-4.2-1.1l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2Zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8-.2-.1-.4-.1-.6.1-.2.2-.6.8-.8 1-.1.2-.3.2-.5.1a6.7 6.7 0 0 1-3.4-3c-.3-.4 0-.5.1-.7l.4-.5c.1-.2.2-.3.3-.5v-.5c0-.1-.5-1.4-.7-1.9-.2-.5-.4-.4-.6-.4h-.5c-.2 0-.5.1-.7.3-.2.3-.9.9-.9 2.2s.9 2.5 1.1 2.7c.1.2 1.9 2.9 4.6 4a15 15 0 0 0 1.5.6c.6.2 1.2.2 1.7.1.5-.1 1.5-.6 1.7-1.2.2-.6.2-1.1.2-1.2l-.4-.3Z" />
        </svg>
        Ya pagué · Enviar comprobante
      </a>
      <p className="mt-1.5 text-[10.5px] leading-relaxed text-ink-faint">
        Te abre WhatsApp con todo escrito: solo adjunta la foto del comprobante y envía. Así
        confirmamos tu pago más rápido.
      </p>
    </div>
  );
}

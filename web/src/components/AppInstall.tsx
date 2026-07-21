"use client";

import { useEffect, useState } from "react";
import { useCart } from "@/lib/cart";

// Evento propietario de Chrome/Android para ofrecer instalar la app.
interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
}

const DISMISS_KEY = "panisse-pwa-dismissed";

// Registra el service worker (habilita instalar + carga rápida) y muestra un
// aviso discreto para "agregar a la pantalla de inicio". En Android es un botón
// que instala directo; en iPhone es una ayudita (Safari sólo instala a mano).
export default function AppInstall() {
  const cart = useCart();
  const [mounted, setMounted] = useState(false);
  const [dismissed, setDismissed] = useState(true);
  const [deferred, setDeferred] = useState<BeforeInstallPromptEvent | null>(null);
  const [isIOS, setIsIOS] = useState(false);

  useEffect(() => {
    setMounted(true);

    const ios = /iphone|ipad|ipod/i.test(window.navigator.userAgent);

    // Service worker: SÓLO en Android/escritorio. En iPhone es inestable en
    // modo app (dejaba la app instalada en blanco), así que ahí NO lo usamos y
    // además limpiamos cualquiera que haya quedado registrado antes.
    if ("serviceWorker" in navigator) {
      if (ios) {
        navigator.serviceWorker
          .getRegistrations()
          .then((regs) => regs.forEach((r) => r.unregister()))
          .catch(() => {});
        if (typeof caches !== "undefined") {
          caches.keys().then((keys) => keys.forEach((k) => caches.delete(k))).catch(() => {});
        }
      } else {
        navigator.serviceWorker.register("/sw.js").catch(() => {
          /* si falla, la web sigue funcionando igual */
        });
      }
    }

    // ¿Ya está instalada? (abierta como app) → no molestar.
    const standalone =
      window.matchMedia("(display-mode: standalone)").matches ||
      // iOS marca esto cuando se abre desde la pantalla de inicio
      (window.navigator as unknown as { standalone?: boolean }).standalone === true;
    if (standalone) return;

    // ¿Ya lo cerró antes?
    if (localStorage.getItem(DISMISS_KEY) === "1") return;

    setIsIOS(ios);
    if (ios) setDismissed(false); // en iOS mostramos la ayudita de una vez

    const onPrompt = (e: Event) => {
      e.preventDefault(); // guardamos el evento para dispararlo con nuestro botón
      setDeferred(e as BeforeInstallPromptEvent);
      if (localStorage.getItem(DISMISS_KEY) !== "1") setDismissed(false);
    };
    window.addEventListener("beforeinstallprompt", onPrompt);

    const onInstalled = () => close();
    window.addEventListener("appinstalled", onInstalled);

    return () => {
      window.removeEventListener("beforeinstallprompt", onPrompt);
      window.removeEventListener("appinstalled", onInstalled);
    };
  }, []);

  const close = () => {
    setDismissed(true);
    try {
      localStorage.setItem(DISMISS_KEY, "1");
    } catch {
      /* ignore */
    }
  };

  const install = async () => {
    if (!deferred) return;
    await deferred.prompt();
    await deferred.userChoice;
    setDeferred(null);
    close();
  };

  // Sólo se muestra: montado, no cerrado, con algo que ofrecer (botón Android o
  // ayuda iOS) y con el carrito vacío para no chocar con la barra del pedido.
  if (!mounted || dismissed || cart.count > 0) return null;
  if (!deferred && !isIOS) return null;

  return (
    <div className="anim-fade-up fixed inset-x-0 bottom-0 z-30 mx-auto max-w-md px-3 pb-[calc(env(safe-area-inset-bottom)+10px)]">
      <div className="flex items-center gap-3 rounded-xl border border-gold-soft/50 bg-navy px-3.5 py-3 shadow-[0_-8px_24px_rgba(4,17,29,0.28)]">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-gold-soft/15 text-[20px] font-semibold text-gold-soft">
          P
        </div>
        <div className="min-w-0 flex-1">
          {isIOS ? (
            <p className="text-[12.5px] leading-snug text-gold-soft">
              Agrega PANISSE a tu inicio: toca{" "}
              <span aria-hidden>⎋</span> Compartir y luego{" "}
              <b>Agregar a inicio</b>.
            </p>
          ) : (
            <p className="text-[13px] font-medium text-gold-soft">
              Agrega PANISSE a tu celular
            </p>
          )}
        </div>
        {!isIOS && deferred && (
          <button
            type="button"
            onClick={install}
            className="shrink-0 rounded-lg bg-gold-soft px-3 py-1.5 text-[12.5px] font-semibold text-navy active:scale-[0.97]"
          >
            Instalar
          </button>
        )}
        <button
          type="button"
          onClick={close}
          aria-label="Cerrar"
          className="shrink-0 text-gold-soft/70 active:text-gold-soft"
        >
          <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
            <path d="M6 6l12 12M18 6 6 18" />
          </svg>
        </button>
      </div>
    </div>
  );
}

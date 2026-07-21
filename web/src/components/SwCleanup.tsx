"use client";

import { useEffect } from "react";

// Ya NO usamos "app instalable" ni service worker. Este componente limpia, en
// cada visita, cualquier service worker o caché que haya quedado registrado de
// aquella época, para que ningún dispositivo se quede atascado con una versión
// vieja del panel o del menú. Para un equipo limpio no hace nada.
export default function SwCleanup() {
  useEffect(() => {
    try {
      if ("serviceWorker" in navigator) {
        navigator.serviceWorker
          .getRegistrations()
          .then((regs) => regs.forEach((r) => r.unregister()))
          .catch(() => {});
      }
      if (typeof caches !== "undefined") {
        caches
          .keys()
          .then((keys) => keys.forEach((k) => caches.delete(k)))
          .catch(() => {});
      }
    } catch {
      /* si algo falla, la web funciona igual */
    }
  }, []);
  return null;
}

"use client";

// Bloqueo del scroll del fondo cuando hay una hoja/overlay abierto.
//
// No basta con `overflow: hidden`: en iOS, al enfocar un campo dentro de una
// hoja fija, Safari intenta mostrar el cursor desplazando TODA la página, y
// como la hoja está anclada a la ventana, se ve moverse de lado. Para evitarlo
// "congelamos" la página en su sitio (position: fixed con el desplazamiento
// guardado): así el documento no puede desplazarse y sólo se mueve el contenido
// interno de la hoja, que es lo correcto.
//
// Con contador de referencias por si se solapan dos overlays: sólo se libera
// cuando se cierra el último.

import { useEffect } from "react";

let locks = 0;
let savedY = 0;

function lock() {
  locks += 1;
  if (locks > 1) return;
  savedY = window.scrollY;
  const b = document.body;
  b.style.position = "fixed";
  b.style.top = `-${savedY}px`;
  b.style.insetInline = "0";
  b.style.width = "100%";
  document.documentElement.classList.add("scroll-locked");
}

function unlock() {
  if (locks === 0) return;
  locks -= 1;
  if (locks > 0) return;
  const b = document.body;
  b.style.position = "";
  b.style.top = "";
  b.style.insetInline = "";
  b.style.width = "";
  document.documentElement.classList.remove("scroll-locked");
  window.scrollTo(0, savedY);
}

/** Congela el fondo mientras `active` sea true; lo restaura al cerrar. */
export function useScrollLock(active: boolean) {
  useEffect(() => {
    if (!active) return;
    lock();
    return unlock;
  }, [active]);
}

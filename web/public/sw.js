// Auto-borrado. Ya NO usamos service worker.
//
// Este archivo queda sólo para limpiar los teléfonos que registraron una
// versión anterior (que dejaba la app instalada en blanco): al detectar esta
// versión, borra sus cachés, se desregistra solo y recarga la página para
// soltarse. Los visitantes nuevos nunca registran service worker.

self.addEventListener("install", () => self.skipWaiting());

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      try {
        const keys = await caches.keys();
        await Promise.all(keys.map((k) => caches.delete(k)));
        await self.registration.unregister();
        const clients = await self.clients.matchAll({ type: "window" });
        clients.forEach((c) => c.navigate(c.url));
      } catch {
        /* si algo falla, no pasa nada: el sitio funciona sin service worker */
      }
    })(),
  );
});

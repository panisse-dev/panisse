// Service worker mínimo de PANISSE.
//
// Su función principal aquí es habilitar la instalación como app ("agregar a
// inicio") y hacer que abra rápido incluso con internet lento, sirviendo desde
// caché lo que ya se visitó. NO cachea datos del menú ni pedidos (esos siempre
// se piden frescos a Supabase), sólo la envoltura de la página y los recursos
// estáticos, con estrategia "red primero y caché de respaldo".

const CACHE = "panisse-v1";

self.addEventListener("install", (event) => {
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      // Borra cachés de versiones anteriores.
      const keys = await caches.keys();
      await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
      await self.clients.claim();
    })(),
  );
});

self.addEventListener("fetch", (event) => {
  const req = event.request;

  // Sólo GET del mismo origen; nunca tocar las llamadas a Supabase/APIs.
  if (req.method !== "GET" || new URL(req.url).origin !== self.location.origin) {
    return;
  }

  event.respondWith(
    (async () => {
      try {
        // Red primero: siempre lo más fresco.
        const fresh = await fetch(req);
        const cache = await caches.open(CACHE);
        cache.put(req, fresh.clone());
        return fresh;
      } catch {
        // Sin conexión: intenta servir lo guardado.
        const cached = await caches.match(req);
        if (cached) return cached;
        // Como último recurso, la página de inicio para navegaciones.
        if (req.mode === "navigate") {
          const home = await caches.match("/");
          if (home) return home;
        }
        throw new Error("sin conexión y sin caché");
      }
    })(),
  );
});

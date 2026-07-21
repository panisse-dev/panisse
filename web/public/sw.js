// Service worker mínimo y a prueba de fallos de PANISSE.
//
// Su única razón de ser es (1) habilitar "instalar app" en Android y (2)
// acelerar la carga de imágenes y archivos fijos. NUNCA se mete con las
// páginas (HTML) ni con las llamadas a Supabase: esas van directo por el
// navegador, así la app instalada SIEMPRE abre y navega, aunque el internet
// falle un instante (en iPhone los service workers son delicados y un manejo
// agresivo dejaba la app en blanco).

const CACHE = "panisse-v2";

// Sólo estos recursos son fijos e inmutables (llevan huella en el nombre):
// se pueden guardar sin miedo. El HTML y los datos NO.
const CACHEABLE = /\/_next\/static\/|\/icons\/|\.(?:js|css|woff2?|png|jpe?g|webp|svg|ico)$/;

self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
      await self.clients.claim();
    })(),
  );
});

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;

  const url = new URL(req.url);
  // Otro dominio (Supabase, WhatsApp…) o algo que no sea recurso fijo:
  // no lo tocamos, lo maneja el navegador normal.
  if (url.origin !== self.location.origin || !CACHEABLE.test(url.pathname)) return;

  // Recurso fijo: caché primero (rápido), y si no está, red y se guarda.
  event.respondWith(
    (async () => {
      const cached = await caches.match(req);
      if (cached) return cached;
      try {
        const fresh = await fetch(req);
        if (fresh.ok) {
          const cache = await caches.open(CACHE);
          cache.put(req, fresh.clone());
        }
        return fresh;
      } catch {
        return cached || Response.error();
      }
    })(),
  );
});

import type { MetadataRoute } from "next";

// El sitio es 100% estático (output: export): el manifest se genera en el build.
export const dynamic = "force-static";

// Manifest de la app instalable (PWA): permite "agregar a la pantalla de
// inicio" con el ícono de PANISSE y abrirla a pantalla completa.
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "PANISSE",
    short_name: "PANISSE",
    description: "Carta de PANISSE — cocina italiana en Pereira. Pide desde tu mesa.",
    start_url: "/",
    scope: "/",
    display: "standalone",
    orientation: "portrait",
    background_color: "#04111d",
    theme_color: "#04111d",
    lang: "es",
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/icons/icon-192-maskable.png", sizes: "192x192", type: "image/png", purpose: "maskable" },
      { src: "/icons/icon-512-maskable.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}

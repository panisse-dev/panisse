import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Sitio 100% estático (carta QR): exporta HTML plano, sin servidor.
  // Es lo más rápido y robusto para alojar en Netlify.
  output: "export",
  images: {
    // La exportación estática no usa el optimizador de imágenes de Next;
    // servimos las webp tal cual (ya vienen a 720px).
    unoptimized: true,
  },
};

export default nextConfig;

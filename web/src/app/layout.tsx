import type { Metadata, Viewport } from "next";
import { Playfair_Display, Outfit } from "next/font/google";
import "./globals.css";
import { CartProvider } from "@/lib/cart";
import { OrdersProvider } from "@/lib/myOrders";
import SwCleanup from "@/components/SwCleanup";

const playfair = Playfair_Display({
  variable: "--font-playfair",
  subsets: ["latin"],
  display: "swap",
});

const outfit = Outfit({
  variable: "--font-outfit",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "PANISSE · Menú",
    template: "%s · PANISSE",
  },
  description:
    "Carta de PANISSE — cocina italiana en Pereira. Brunch, lunch y dinner, vinos y bebidas.",
};

export const viewport: Viewport = {
  themeColor: "#f6f6f5",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  // Al abrir el teclado, la zona visible se encoge para que la hoja quede
  // encima y no tapada (soportado en navegadores modernos; inofensivo si no).
  interactiveWidget: "resizes-content",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es" className={`${playfair.variable} ${outfit.variable}`}>
      <body className="antialiased">
        <SwCleanup />
        <OrdersProvider>
          <CartProvider>{children}</CartProvider>
        </OrdersProvider>
      </body>
    </html>
  );
}

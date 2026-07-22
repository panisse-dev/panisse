import type { Metadata, Viewport } from "next";
import {
  Playfair_Display,
  Outfit,
  Cormorant_Garamond,
  Montserrat,
  Dancing_Script,
} from "next/font/google";
import "./globals.css";
import { CartProvider } from "@/lib/cart";
import { OrdersProvider } from "@/lib/myOrders";
import { LocationProvider } from "@/lib/location";
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

// Tipos de letra adicionales para el editor de apariencia del panel.
const cormorant = Cormorant_Garamond({
  variable: "--font-cormorant",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  display: "swap",
});

const montserrat = Montserrat({
  variable: "--font-montserrat",
  subsets: ["latin"],
  display: "swap",
});

const dancing = Dancing_Script({
  variable: "--font-dancing",
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
    <html
      lang="es"
      className={`${playfair.variable} ${outfit.variable} ${cormorant.variable} ${montserrat.variable} ${dancing.variable}`}
    >
      <body className="antialiased">
        <SwCleanup />
        <LocationProvider>
          <OrdersProvider>
            <CartProvider>{children}</CartProvider>
          </OrdersProvider>
        </LocationProvider>
      </body>
    </html>
  );
}

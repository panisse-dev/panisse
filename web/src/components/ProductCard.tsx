"use client";

import Image from "next/image";
import type { Product } from "@/lib/menu";
import { formatCOP } from "@/lib/format";
import { NewBadge, VegBadge } from "./ProductRow";

function priceLabel(product: Product): string | null {
  if (product.hidePrice || product.prices.length === 0) return null;
  const values = product.prices.map((p) => p.discounted ?? p.price);
  const min = Math.min(...values);
  return product.prices.length > 1 ? `Desde ${formatCOP(min)}` : formatCOP(values[0]);
}

export default function ProductCard({
  product,
  onOpen,
}: {
  product: Product;
  onOpen: (p: Product) => void;
}) {
  const price = priceLabel(product);

  return (
    <button
      type="button"
      onClick={() => onOpen(product)}
      className="group flex flex-col overflow-hidden border border-gold-soft/50 bg-card text-left shadow-[0_1px_6px_rgba(4,27,49,0.06)] transition-transform active:scale-[0.98]"
    >
      {/* Imagen (o placeholder elegante) */}
      <div className="relative aspect-square w-full overflow-hidden bg-paper-deep">
        {product.image ? (
          <Image
            src={product.image}
            alt={product.name}
            fill
            sizes="(max-width: 448px) 45vw, 200px"
            className="object-cover"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center bg-gradient-to-br from-paper to-paper-deep">
            <svg viewBox="0 0 24 24" className="h-8 w-8 text-gold-soft/60" fill="none" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <path d="M7 3v7M5 3v3.5A2 2 0 0 0 7 8.5 2 2 0 0 0 9 6.5V3M7 10v11M15 3c-1.7 1.2-2.5 3-2.5 5 0 1.7 1 3 2.5 3s2.5-1.3 2.5-3c0-2-.8-3.8-2.5-5ZM15 11v10" />
            </svg>
          </div>
        )}

        {/* Insignias */}
        {(product.veg || product.isNew) && (
          <div className="absolute left-1.5 top-1.5 flex items-center gap-1">
            {product.isNew && <NewBadge />}
            {product.veg && (
              <span className="flex h-5 w-5 items-center justify-center rounded-full bg-card/90 shadow-sm">
                <VegBadge />
              </span>
            )}
          </div>
        )}

        {/* Botón agregar */}
        <span className="absolute bottom-1.5 right-1.5 flex h-7 w-7 items-center justify-center rounded-full bg-navy text-gold-soft shadow-[0_2px_6px_rgba(4,17,29,0.35)]">
          <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden>
            <path d="M12 5v14M5 12h14" />
          </svg>
        </span>
      </div>

      {/* Texto */}
      <div className="flex flex-1 flex-col px-2.5 pb-2.5 pt-2 text-center">
        <h4 className="font-display text-[13.5px] font-semibold leading-tight text-navy">
          {product.name}
        </h4>
        {product.description && (
          <p className="mt-1 line-clamp-2 text-[10.5px] leading-snug text-ink-soft">
            {product.description}
          </p>
        )}
        {price && (
          <p className="mt-auto pt-1.5 text-[13px] font-semibold text-gold-deep">{price}</p>
        )}
      </div>
    </button>
  );
}

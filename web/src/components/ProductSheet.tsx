"use client";

import Image from "next/image";
import { useEffect } from "react";
import type { Product } from "@/lib/menu";
import { formatCOP } from "@/lib/format";
import { NewBadge, VegBadge } from "./ProductRow";

export default function ProductSheet({
  product,
  isFavorite,
  onToggleFavorite,
  onClose,
}: {
  product: Product | null;
  isFavorite: boolean;
  onToggleFavorite: () => void;
  onClose: () => void;
}) {
  useEffect(() => {
    if (!product) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [product, onClose]);

  if (!product) return null;

  return (
    <div className="fixed inset-0 z-50" role="dialog" aria-modal="true" aria-label={product.name}>
      <button
        type="button"
        aria-label="Cerrar"
        onClick={onClose}
        className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]"
      />
      <div className="anim-sheet-up absolute inset-x-0 bottom-0 mx-auto max-w-md">
        <div className="max-h-[88dvh] overflow-y-auto rounded-t-3xl bg-card pb-[calc(env(safe-area-inset-bottom)+20px)] shadow-[0_-12px_40px_rgba(4,17,29,0.25)]">
          {/* Asa + cerrar */}
          <div className="sticky top-0 z-10 flex items-center justify-between bg-gradient-to-b from-card via-card/95 to-transparent px-4 pb-3 pt-3">
            <span className="w-9" />
            <span className="h-1 w-10 rounded-full bg-ink/15" aria-hidden />
            <button
              type="button"
              onClick={onClose}
              aria-label="Cerrar"
              className="flex h-9 w-9 items-center justify-center rounded-full bg-paper-deep text-ink-soft"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
                <path d="M6 6l12 12M18 6 6 18" />
              </svg>
            </button>
          </div>

          {product.image && (
            <div className="relative mx-5 h-64 overflow-hidden border border-gold-soft/70 bg-paper-deep outline outline-1 outline-offset-[3px] outline-gold-soft/40">
              <Image
                src={product.image}
                alt={product.name}
                fill
                sizes="(max-width: 448px) 90vw, 400px"
                className="object-cover"
              />
            </div>
          )}

          <div className="px-6 pt-5">
            <div className="flex items-center gap-2">
              {product.veg && <VegBadge />}
              {product.isNew && <NewBadge />}
            </div>
            <h3 className="mt-1 font-display text-[24px] leading-tight text-navy">
              {product.name}
            </h3>
            {product.description && (
              <p className="mt-2.5 text-[14px] leading-relaxed text-ink-soft">
                {product.description}
              </p>
            )}

            {!product.hidePrice && product.prices.length > 0 && (
              <div className="mt-5 flex flex-col gap-2.5 border-t border-gold-soft/40 pt-4">
                {product.prices.map((pr, i) => (
                  <div key={i} className="flex items-baseline gap-2">
                    <span className="text-[14px] text-ink-soft">
                      {pr.label || (product.prices.length > 1 ? product.name : "Precio")}
                    </span>
                    <span className="leader" aria-hidden />
                    {pr.discounted != null && pr.discounted < pr.price ? (
                      <span>
                        <span className="mr-2 text-[13px] text-ink-faint line-through">
                          {formatCOP(pr.price)}
                        </span>
                        <span className="font-display text-[19px] font-semibold text-gold-deep">
                          {formatCOP(pr.discounted)}
                        </span>
                      </span>
                    ) : (
                      <span className="font-display text-[19px] font-semibold text-gold-deep">
                        {formatCOP(pr.price)}
                      </span>
                    )}
                  </div>
                ))}
              </div>
            )}

            <button
              type="button"
              onClick={onToggleFavorite}
              className={`mt-6 flex h-12 w-full items-center justify-center gap-2 border text-[13px] font-medium transition-colors ${
                isFavorite
                  ? "border-gold bg-gold/12 text-gold-deep"
                  : "border-gold-soft/70 bg-paper text-ink-soft"
              }`}
            >
              <svg
                viewBox="0 0 24 24"
                className="h-4.5 w-4.5"
                fill={isFavorite ? "currentColor" : "none"}
                stroke="currentColor"
                strokeWidth="1.8"
                aria-hidden
              >
                <path d="M12 21s-7.5-4.6-10-9.3C.6 8.6 2.6 5 6.2 5c2.2 0 3.6 1.2 4.4 2.5L12 9l1.4-1.5C14.2 6.2 15.6 5 17.8 5c3.6 0 5.6 3.6 4.2 6.7C19.5 16.4 12 21 12 21Z" />
              </svg>
              {isFavorite ? "Guardado en mi selección" : "Guardar en mi selección"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

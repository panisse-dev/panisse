"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import type { Product } from "@/lib/menu";
import { formatCOP } from "@/lib/format";
import { useCart } from "@/lib/cart";
import { NewBadge, VegBadge } from "./ProductRow";

export default function ProductSheet({
  product,
  onClose,
}: {
  product: Product | null;
  onClose: () => void;
}) {
  const cart = useCart();
  const [priceIdx, setPriceIdx] = useState(0);
  const [qty, setQty] = useState(1);
  const [added, setAdded] = useState(false);

  // Reinicia selección al abrir otro producto
  useEffect(() => {
    setPriceIdx(0);
    setQty(1);
    setAdded(false);
  }, [product?.id]);

  useEffect(() => {
    if (!product) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [product, onClose]);

  if (!product) return null;

  const orderable = !product.hidePrice && product.prices.length > 0;
  const hasVariants = product.prices.length > 1;
  const sel = product.prices[priceIdx];
  const unit = sel ? (sel.discounted ?? sel.price) : 0;

  const handleAdd = () => {
    if (!orderable || !sel) return;
    cart.add(
      {
        productId: product.id,
        name: product.name,
        variant: hasVariants ? sel.label || `Opción ${priceIdx + 1}` : "",
        unitPrice: unit,
        image: product.image,
      },
      qty,
    );
    setAdded(true);
    setTimeout(onClose, 260);
  };

  return (
    <div className="fixed inset-0 z-50" role="dialog" aria-modal="true" aria-label={product.name}>
      <button
        type="button"
        aria-label="Cerrar"
        onClick={onClose}
        className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]"
      />
      <div className="anim-sheet-up absolute inset-x-0 bottom-0 mx-auto max-w-md">
        <div className="max-h-[90dvh] overflow-y-auto rounded-t-3xl bg-card pb-[calc(env(safe-area-inset-bottom)+20px)] shadow-[0_-12px_40px_rgba(4,17,29,0.25)]">
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
            <div className="relative mx-5 h-60 overflow-hidden border border-gold-soft/70 bg-paper-deep outline outline-1 outline-offset-[3px] outline-gold-soft/40">
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
            <h3 className="mt-1 font-display text-[24px] leading-tight text-navy">{product.name}</h3>
            {product.description && (
              <p className="mt-2.5 text-[14px] leading-relaxed text-ink-soft">{product.description}</p>
            )}

            {/* Selección de variante o precio único */}
            {orderable && (
              <div className="mt-5 border-t border-gold-soft/40 pt-4">
                {hasVariants ? (
                  <div className="flex flex-col gap-2">
                    <p className="smallcaps text-[10px] text-gold-deep">Elige una opción</p>
                    {product.prices.map((pr, i) => {
                      const u = pr.discounted ?? pr.price;
                      const active = i === priceIdx;
                      return (
                        <button
                          key={i}
                          type="button"
                          onClick={() => setPriceIdx(i)}
                          className={`flex items-center justify-between border px-4 py-3 text-left transition-colors ${
                            active ? "border-navy bg-navy/[0.04]" : "border-gold-soft/60 bg-paper"
                          }`}
                        >
                          <span className="flex items-center gap-2.5">
                            <span
                              className={`flex h-4 w-4 items-center justify-center rounded-full border ${
                                active ? "border-navy" : "border-ink-faint"
                              }`}
                            >
                              {active && <span className="h-2 w-2 rounded-full bg-navy" />}
                            </span>
                            <span className="text-[14px] text-ink">{pr.label || `Opción ${i + 1}`}</span>
                          </span>
                          <span className="font-display text-[16px] font-semibold text-gold-deep">
                            {formatCOP(u)}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                ) : (
                  <div className="flex items-baseline gap-2">
                    <span className="text-[14px] text-ink-soft">Precio</span>
                    <span className="leader" aria-hidden />
                    {sel.discounted != null && sel.discounted < sel.price ? (
                      <span>
                        <span className="mr-2 text-[13px] text-ink-faint line-through">{formatCOP(sel.price)}</span>
                        <span className="font-display text-[19px] font-semibold text-gold-deep">{formatCOP(sel.discounted)}</span>
                      </span>
                    ) : (
                      <span className="font-display text-[19px] font-semibold text-gold-deep">{formatCOP(sel.price)}</span>
                    )}
                  </div>
                )}
              </div>
            )}

            {orderable ? (
              <div className="mt-6 flex items-stretch gap-3">
                {/* Cantidad */}
                <div className="flex items-center border border-gold-soft/70 bg-paper">
                  <button
                    type="button"
                    aria-label="Quitar uno"
                    onClick={() => setQty((q) => Math.max(1, q - 1))}
                    className="flex h-12 w-11 items-center justify-center text-[20px] text-ink-soft active:bg-gold-soft/20"
                  >
                    −
                  </button>
                  <span className="w-8 text-center font-display text-[17px] text-navy">{qty}</span>
                  <button
                    type="button"
                    aria-label="Agregar uno"
                    onClick={() => setQty((q) => Math.min(50, q + 1))}
                    className="flex h-12 w-11 items-center justify-center text-[20px] text-ink-soft active:bg-gold-soft/20"
                  >
                    +
                  </button>
                </div>
                {/* Agregar */}
                <button
                  type="button"
                  onClick={handleAdd}
                  className="flex h-12 flex-1 items-center justify-center gap-2 bg-navy px-4 text-[14px] font-semibold text-gold-soft transition-transform active:scale-[0.98]"
                >
                  {added ? (
                    "¡Agregado!"
                  ) : (
                    <>
                      <span>Agregar</span>
                      <span className="opacity-60">·</span>
                      <span>{formatCOP(unit * qty)}</span>
                    </>
                  )}
                </button>
              </div>
            ) : (
              <p className="mt-6 border border-gold-soft/50 bg-paper px-4 py-3 text-center text-[13px] text-ink-soft">
                Consulta el precio en tienda
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

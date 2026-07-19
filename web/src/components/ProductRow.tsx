"use client";

import Image from "next/image";
import type { Product } from "@/lib/menu";
import { formatCOP } from "@/lib/format";

export function VegBadge() {
  return (
    <span
      className="inline-flex shrink-0 items-center text-verde"
      title="Vegetariano"
      aria-label="Vegetariano"
    >
      <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="currentColor" aria-hidden>
        <path d="M20 4c-7 0-12 3-13.5 8.5C5.6 15.7 5 18.5 5 20h2c0-1 .2-2.3.6-3.7C9 17.4 10.7 18 12.5 18 17 18 20 13 20 4ZM7 12c.6-3 3-5.3 6.6-6.4C11 7.6 8.8 9.9 7.6 13.4 7.4 13 7.2 12.5 7 12Z" />
      </svg>
    </span>
  );
}

export function NewBadge() {
  return (
    <span className="smallcaps inline-flex shrink-0 items-center rounded-full bg-gold/12 px-1.5 py-px text-[9px] font-semibold text-gold-deep">
      Nuevo
    </span>
  );
}

function PriceText({ price, discounted }: { price: number; discounted: number | null }) {
  if (discounted != null && discounted < price) {
    return (
      <span className="shrink-0 whitespace-nowrap">
        <span className="mr-1.5 text-[12px] text-ink-faint line-through">{formatCOP(price)}</span>
        <span className="font-semibold text-gold-deep">{formatCOP(discounted)}</span>
      </span>
    );
  }
  return <span className="shrink-0 whitespace-nowrap font-semibold text-gold-deep">{formatCOP(price)}</span>;
}

export default function ProductRow({
  product,
  onOpen,
  contextLabel,
}: {
  product: Product;
  onOpen: (p: Product) => void;
  contextLabel?: string;
}) {
  const single = !product.hidePrice && product.prices.length === 1 ? product.prices[0] : null;
  const multi = !product.hidePrice && product.prices.length > 1 ? product.prices : null;

  // Une la última palabra del nombre con los badges para que la hojita/etiqueta
  // nunca quede huérfana en una línea propia.
  const hasBadges = product.veg || product.isNew;
  const words = product.name.split(" ");
  const lastWord = words.pop() ?? "";
  const headWords = words.join(" ");

  return (
    <button
      type="button"
      onClick={() => onOpen(product)}
      className="block w-full py-3.5 text-left transition-colors active:bg-gold-soft/10"
    >
      <div className="flex items-start gap-3.5">
        <div className="min-w-0 flex-1">
          {contextLabel && (
            <p className="smallcaps mb-0.5 text-[9.5px] text-ink-faint">{contextLabel}</p>
          )}
          <div className="flex items-baseline gap-1.5">
            <h4 className="font-display text-[16.5px] leading-snug text-navy">
              {hasBadges ? (
                <>
                  {headWords && <>{headWords} </>}
                  <span className="whitespace-nowrap">
                    {lastWord}
                    <span className="ml-1.5 inline-flex translate-y-px items-center gap-1 align-baseline">
                      {product.veg && <VegBadge />}
                      {product.isNew && <NewBadge />}
                    </span>
                  </span>
                </>
              ) : (
                product.name
              )}
            </h4>
            {single && <span className="leader" aria-hidden />}
            {single && (
              <span className="text-[14.5px]">
                <PriceText price={single.price} discounted={single.discounted} />
              </span>
            )}
          </div>
          {product.description && (
            <p className="mt-1 text-[12.5px] leading-relaxed text-ink-soft">
              {product.description}
            </p>
          )}
          {multi && (
            <div className="mt-1.5 flex flex-col gap-1">
              {multi.map((pr, i) => (
                <div key={i} className="flex items-baseline gap-1.5 text-[13px]">
                  <span className="text-ink-soft">{pr.label || product.name}</span>
                  <span className="leader" aria-hidden />
                  <span className="text-[13.5px]">
                    <PriceText price={pr.price} discounted={pr.discounted} />
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
        {product.image && (
          <div className="relative h-[76px] w-[76px] shrink-0 overflow-hidden border border-gold-soft/70 bg-paper-deep">
            <Image
              src={product.image}
              alt={product.name}
              fill
              sizes="76px"
              className="object-cover"
            />
          </div>
        )}
      </div>
    </button>
  );
}

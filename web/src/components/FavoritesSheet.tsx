"use client";

import { useEffect, useMemo } from "react";
import type { Menu, Product } from "@/lib/menu";
import { formatCOP } from "@/lib/format";

export default function FavoritesSheet({
  menu,
  favorites,
  open,
  onClose,
  onOpenProduct,
  onRemove,
}: {
  menu: Menu;
  favorites: Set<string>;
  open: boolean;
  onClose: () => void;
  onOpenProduct: (p: Product) => void;
  onRemove: (id: string) => void;
}) {
  const items = useMemo(() => {
    const out: { product: Product; path: string }[] = [];
    for (const s of menu.sections) {
      for (const p of s.products) if (favorites.has(p.id)) out.push({ product: p, path: s.name });
      for (const ss of s.subsections)
        for (const p of ss.products) if (favorites.has(p.id)) out.push({ product: p, path: ss.name });
    }
    return out;
  }, [menu, favorites]);

  const total = useMemo(
    () =>
      items.reduce((sum, it) => {
        const pr = it.product.prices[0];
        return sum + (pr ? (pr.discounted ?? pr.price) : 0);
      }, 0),
    [items],
  );

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50" role="dialog" aria-modal="true" aria-label="Mi selección">
      <button
        type="button"
        aria-label="Cerrar"
        onClick={onClose}
        className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]"
      />
      <div className="anim-sheet-up absolute inset-x-0 bottom-0 mx-auto max-w-md">
        <div className="max-h-[80dvh] overflow-y-auto rounded-t-3xl bg-card pb-[calc(env(safe-area-inset-bottom)+24px)] shadow-[0_-12px_40px_rgba(4,17,29,0.25)]">
          <div className="sticky top-0 z-10 border-b border-gold-soft/40 bg-card px-6 pb-4 pt-4">
            <span className="mx-auto block h-1 w-10 rounded-full bg-ink/15" aria-hidden />
            <div className="mt-3 flex items-baseline justify-between">
              <h3 className="font-display text-[20px] text-navy">Mi selección</h3>
              <span className="text-[12px] text-ink-faint">
                {items.length} {items.length === 1 ? "plato" : "platos"}
              </span>
            </div>
          </div>

          {items.length === 0 ? (
            <p className="px-6 py-12 text-center text-[13px] leading-relaxed text-ink-faint">
              Aún no has guardado platos.
              <br />
              Toca un plato y usa “Guardar en mi selección”.
            </p>
          ) : (
            <>
              <ul className="divide-y divide-gold-soft/25 px-6">
                {items.map(({ product, path }) => {
                  const pr = product.prices[0];
                  return (
                    <li key={product.id} className="flex items-center gap-3 py-3">
                      <button
                        type="button"
                        onClick={() => onOpenProduct(product)}
                        className="min-w-0 flex-1 text-left"
                      >
                        <p className="smallcaps text-[9.5px] text-ink-faint">{path}</p>
                        <p className="font-display text-[15.5px] leading-snug text-navy">
                          {product.name}
                        </p>
                      </button>
                      {pr && (
                        <span className="shrink-0 text-[13.5px] font-semibold text-gold-deep">
                          {formatCOP(pr.discounted ?? pr.price)}
                        </span>
                      )}
                      <button
                        type="button"
                        onClick={() => onRemove(product.id)}
                        aria-label={`Quitar ${product.name}`}
                        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-ink-faint active:bg-paper-deep"
                      >
                        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
                          <path d="M4 7h16M10 11v6M14 11v6M6 7l1 12a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-12M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2" />
                        </svg>
                      </button>
                    </li>
                  );
                })}
              </ul>
              <div className="mx-6 mt-2 flex items-baseline justify-between border-t border-gold-soft/40 pt-4">
                <span className="smallcaps text-[11px] text-ink-soft">Total aproximado</span>
                <span className="font-display text-[20px] font-semibold text-navy">
                  {formatCOP(total)}
                </span>
              </div>
              <p className="mt-2 px-6 text-[11px] leading-relaxed text-ink-faint">
                Muéstrale esta lista a tu mesero para ordenar.
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

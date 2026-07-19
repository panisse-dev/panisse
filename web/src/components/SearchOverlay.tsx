"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import type { Menu, Product } from "@/lib/menu";
import { normalize } from "@/lib/format";
import ProductRow from "./ProductRow";

interface IndexedProduct {
  product: Product;
  path: string;
  haystack: string;
}

export default function SearchOverlay({
  menu,
  open,
  onClose,
  onOpenProduct,
}: {
  menu: Menu;
  open: boolean;
  onClose: () => void;
  onOpenProduct: (p: Product) => void;
}) {
  const [query, setQuery] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);

  const index = useMemo<IndexedProduct[]>(() => {
    const out: IndexedProduct[] = [];
    for (const s of menu.sections) {
      for (const p of s.products) {
        out.push({
          product: p,
          path: s.name,
          haystack: normalize(`${p.name} ${p.description} ${s.name}`),
        });
      }
      for (const ss of s.subsections) {
        for (const p of ss.products) {
          out.push({
            product: p,
            path: `${s.name} · ${ss.name}`,
            haystack: normalize(`${p.name} ${p.description} ${s.name} ${ss.name}`),
          });
        }
      }
    }
    return out;
  }, [menu]);

  const q = normalize(query.trim());
  const results = useMemo(() => {
    if (q.length < 2) return [];
    const terms = q.split(/\s+/);
    return index.filter((e) => terms.every((t) => e.haystack.includes(t))).slice(0, 60);
  }, [q, index]);

  useEffect(() => {
    if (open) {
      setQuery("");
      // Autofocus tras la animación de entrada
      const t = setTimeout(() => inputRef.current?.focus(), 80);
      return () => clearTimeout(t);
    }
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="anim-fade-in fixed inset-0 z-40 bg-black/20" role="dialog" aria-modal="true" aria-label="Buscar en la carta">
      <div className="marble-col mx-auto flex h-full max-w-md flex-col">
        <div className="flex items-center gap-3 border-b border-gold-soft/60 bg-card/92 px-4 pb-3 pt-[calc(env(safe-area-inset-top)+12px)] backdrop-blur-md">
          <div className="flex h-11 flex-1 items-center gap-2.5 border border-gold-soft/70 bg-card px-4">
            <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0 text-gold-deep" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
              <circle cx="11" cy="11" r="7" />
              <path d="m20 20-3.5-3.5" />
            </svg>
            <input
              ref={inputRef}
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={`Buscar en ${menu.label}…`}
              className="h-full w-full bg-transparent text-[15px] text-ink outline-none placeholder:text-ink-faint"
              autoComplete="off"
              autoCorrect="off"
            />
            {query && (
              <button
                type="button"
                onClick={() => setQuery("")}
                aria-label="Limpiar búsqueda"
                className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-paper-deep text-ink-faint"
              >
                <svg viewBox="0 0 24 24" className="h-3 w-3" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden>
                  <path d="M6 6l12 12M18 6 6 18" />
                </svg>
              </button>
            )}
          </div>
          <button
            type="button"
            onClick={onClose}
            className="shrink-0 text-[13px] font-medium text-gold-deep"
          >
            Cancelar
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-5 pb-10">
          {q.length < 2 ? (
            <p className="mt-14 text-center text-[13px] text-ink-faint">
              Escribe el nombre de un plato o un ingrediente
            </p>
          ) : results.length === 0 ? (
            <p className="mt-14 text-center text-[13px] text-ink-faint">
              Sin resultados para “{query.trim()}”
            </p>
          ) : (
            <div className="mt-3 divide-y divide-gold-soft/25 border border-gold-soft/35 bg-white/75 px-4">
              {results.map((r) => (
                <ProductRow
                  key={r.product.id + r.path}
                  product={r.product}
                  contextLabel={r.path}
                  onOpen={onOpenProduct}
                />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

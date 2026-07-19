"use client";

import { createContext, useContext, useEffect, useMemo, useState, useCallback } from "react";

export interface CartLine {
  productId: string;
  name: string;
  variant: string; // etiqueta de variante ("" si no aplica)
  unitPrice: number;
  qty: number;
  image: string | null;
}

interface CartAPI {
  lines: CartLine[];
  count: number;
  total: number;
  add: (line: Omit<CartLine, "qty">, qty?: number) => void;
  setQty: (productId: string, variant: string, qty: number) => void;
  remove: (productId: string, variant: string) => void;
  clear: () => void;
  qtyOf: (productId: string, variant: string) => number;
}

const KEY = "panisse-cart";
const CartCtx = createContext<CartAPI | null>(null);
const lineKey = (p: string, v: string) => `${p}::${v}`;

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [lines, setLines] = useState<CartLine[]>([]);
  const [ready, setReady] = useState(false);

  // Cargar tras montar (evita desajuste servidor/cliente)
  useEffect(() => {
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) setLines(JSON.parse(raw) as CartLine[]);
    } catch {
      /* ignore */
    }
    setReady(true);
  }, []);

  useEffect(() => {
    if (!ready) return;
    try {
      localStorage.setItem(KEY, JSON.stringify(lines));
    } catch {
      /* ignore */
    }
  }, [lines, ready]);

  const add = useCallback((line: Omit<CartLine, "qty">, qty = 1) => {
    setLines((prev) => {
      const k = lineKey(line.productId, line.variant);
      const i = prev.findIndex((l) => lineKey(l.productId, l.variant) === k);
      if (i === -1) return [...prev, { ...line, qty }];
      const next = [...prev];
      next[i] = { ...next[i], qty: next[i].qty + qty };
      return next;
    });
  }, []);

  const setQty = useCallback((productId: string, variant: string, qty: number) => {
    setLines((prev) => {
      const k = lineKey(productId, variant);
      if (qty <= 0) return prev.filter((l) => lineKey(l.productId, l.variant) !== k);
      return prev.map((l) => (lineKey(l.productId, l.variant) === k ? { ...l, qty } : l));
    });
  }, []);

  const remove = useCallback((productId: string, variant: string) => {
    const k = lineKey(productId, variant);
    setLines((prev) => prev.filter((l) => lineKey(l.productId, l.variant) !== k));
  }, []);

  const clear = useCallback(() => setLines([]), []);

  const value = useMemo<CartAPI>(() => {
    const count = lines.reduce((s, l) => s + l.qty, 0);
    const total = lines.reduce((s, l) => s + l.qty * l.unitPrice, 0);
    return {
      lines,
      count,
      total,
      add,
      setQty,
      remove,
      clear,
      qtyOf: (p, v) => lines.find((l) => lineKey(l.productId, l.variant) === lineKey(p, v))?.qty ?? 0,
    };
  }, [lines, add, setQty, remove, clear]);

  return <CartCtx.Provider value={value}>{children}</CartCtx.Provider>;
}

export function useCart(): CartAPI {
  const ctx = useContext(CartCtx);
  if (!ctx) throw new Error("useCart debe usarse dentro de <CartProvider>");
  return ctx;
}

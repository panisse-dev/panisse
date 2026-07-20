"use client";

import { createContext, useContext, useEffect, useMemo, useRef, useState, useCallback } from "react";

export interface CartLine {
  productId: string;
  name: string;
  variant: string; // etiqueta de variante ("" si no aplica)
  note: string; // nota/descripción para este plato ("" si no aplica)
  unitPrice: number;
  qty: number;
  image: string | null;
}

interface CartAPI {
  lines: CartLine[];
  count: number;
  total: number;
  add: (line: Omit<CartLine, "qty">, qty?: number) => void;
  setQty: (productId: string, variant: string, note: string, qty: number) => void;
  remove: (productId: string, variant: string, note: string) => void;
  clear: () => void;
}

const KEY = "panisse-cart";
const MAX_AGE = 3 * 60 * 60 * 1000; // el carrito caduca a las 3 horas del primer producto
const CartCtx = createContext<CartAPI | null>(null);
// Dos platos iguales con notas distintas son líneas separadas.
const lineKey = (p: string, v: string, n: string) => `${p}::${v}::${n}`;
const keyOf = (l: CartLine) => lineKey(l.productId, l.variant, l.note);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [lines, setLines] = useState<CartLine[]>([]);
  const [ready, setReady] = useState(false);
  const atRef = useRef<number | null>(null); // cuándo se agregó el primer producto

  // localStorage es la fuente de verdad compartida: al volver a esta
  // pestaña (o si otra pestaña cambió el carrito, p. ej. lo vació al
  // enviar un pedido) adoptamos lo que haya guardado.
  const syncFromStorage = useCallback(() => {
    try {
      const raw = localStorage.getItem(KEY);
      if (!raw) {
        atRef.current = null;
        setLines((prev) => (prev.length === 0 ? prev : []));
        return;
      }
      const parsed = JSON.parse(raw);
      if (parsed && Array.isArray(parsed.lines)) {
        const age = Date.now() - (parsed.at || 0);
        if (parsed.lines.length > 0 && age <= MAX_AGE) {
          atRef.current = parsed.at || Date.now();
          // normaliza líneas viejas sin `note`
          const next = (parsed.lines as CartLine[]).map((l) => ({ ...l, note: l.note || "" }));
          setLines((prev) => (JSON.stringify(prev) === JSON.stringify(next) ? prev : next));
        } else {
          localStorage.removeItem(KEY); // carrito viejo → se descarta
          atRef.current = null;
          setLines((prev) => (prev.length === 0 ? prev : []));
        }
      }
    } catch {
      /* ignore */
    }
  }, []);

  // Cargar tras montar (evita desajuste servidor/cliente)
  useEffect(() => {
    syncFromStorage();
    setReady(true);
  }, [syncFromStorage]);

  // Sincroniza entre pestañas y al volver a la app (Safari suspendida,
  // pestaña restaurada, QR escaneado de nuevo…): así un pedido enviado
  // en cualquier pestaña vacía el carrito en todas.
  useEffect(() => {
    if (!ready) return;
    const onStorage = (e: StorageEvent) => {
      if (e.key === KEY || e.key === null) syncFromStorage();
    };
    const onReturn = () => {
      if (!document.hidden) syncFromStorage();
    };
    window.addEventListener("storage", onStorage);
    window.addEventListener("pageshow", onReturn);
    document.addEventListener("visibilitychange", onReturn);
    return () => {
      window.removeEventListener("storage", onStorage);
      window.removeEventListener("pageshow", onReturn);
      document.removeEventListener("visibilitychange", onReturn);
    };
  }, [ready, syncFromStorage]);

  useEffect(() => {
    if (!ready) return;
    try {
      if (lines.length === 0) {
        atRef.current = null;
        localStorage.removeItem(KEY);
      } else {
        if (atRef.current == null) atRef.current = Date.now();
        localStorage.setItem(KEY, JSON.stringify({ at: atRef.current, lines }));
      }
    } catch {
      /* ignore */
    }
  }, [lines, ready]);

  const add = useCallback((line: Omit<CartLine, "qty">, qty = 1) => {
    setLines((prev) => {
      const k = lineKey(line.productId, line.variant, line.note);
      const i = prev.findIndex((l) => keyOf(l) === k);
      if (i === -1) return [...prev, { ...line, qty }];
      const next = [...prev];
      next[i] = { ...next[i], qty: next[i].qty + qty };
      return next;
    });
  }, []);

  const setQty = useCallback((productId: string, variant: string, note: string, qty: number) => {
    setLines((prev) => {
      const k = lineKey(productId, variant, note);
      if (qty <= 0) return prev.filter((l) => keyOf(l) !== k);
      return prev.map((l) => (keyOf(l) === k ? { ...l, qty } : l));
    });
  }, []);

  const remove = useCallback((productId: string, variant: string, note: string) => {
    const k = lineKey(productId, variant, note);
    setLines((prev) => prev.filter((l) => keyOf(l) !== k));
  }, []);

  const clear = useCallback(() => {
    setLines([]);
    atRef.current = null;
    // Borra el guardado de inmediato (sin esperar al efecto) para que
    // el carrito no reviva si la página se cierra justo tras el pedido.
    try {
      localStorage.removeItem(KEY);
    } catch {
      /* ignore */
    }
  }, []);

  const value = useMemo<CartAPI>(() => {
    const count = lines.reduce((s, l) => s + l.qty, 0);
    const total = lines.reduce((s, l) => s + l.qty * l.unitPrice, 0);
    return { lines, count, total, add, setQty, remove, clear };
  }, [lines, add, setQty, remove, clear]);

  return <CartCtx.Provider value={value}>{children}</CartCtx.Provider>;
}

export function useCart(): CartAPI {
  const ctx = useContext(CartCtx);
  if (!ctx) throw new Error("useCart debe usarse dentro de <CartProvider>");
  return ctx;
}

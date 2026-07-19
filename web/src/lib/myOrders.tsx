"use client";

import { createContext, useCallback, useContext, useEffect, useRef, useState } from "react";
import { getOrderStatus } from "./api";
import type { OrderStatus } from "./orders";

export interface TrackedOrder {
  id: string;
  code: string;
  createdAt: string;
  status: OrderStatus;
}

const KEY = "panisse-my-orders";
const MAX_AGE = 12 * 60 * 60 * 1000; // 12 h
const POLL_MS = 8000;

function prune(list: TrackedOrder[]): TrackedOrder[] {
  const now = Date.now();
  return list.filter((o) => now - new Date(o.createdAt).getTime() < MAX_AGE);
}

interface OrdersAPI {
  orders: TrackedOrder[];
  addOrder: (o: { id: string; code: string; createdAt?: string; status?: OrderStatus }) => void;
  dismiss: (id: string) => void;
}

const Ctx = createContext<OrdersAPI | null>(null);

export function OrdersProvider({ children }: { children: React.ReactNode }) {
  const [orders, setOrders] = useState<TrackedOrder[]>([]);
  const [ready, setReady] = useState(false);
  const ordersRef = useRef<TrackedOrder[]>([]);
  ordersRef.current = orders;

  // Cargar tras montar
  useEffect(() => {
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) setOrders(prune(JSON.parse(raw) as TrackedOrder[]));
    } catch {
      /* ignore */
    }
    setReady(true);
  }, []);

  // Persistir
  useEffect(() => {
    if (!ready) return;
    try {
      localStorage.setItem(KEY, JSON.stringify(orders));
    } catch {
      /* ignore */
    }
  }, [orders, ready]);

  const addOrder = useCallback((o: { id: string; code: string; createdAt?: string; status?: OrderStatus }) => {
    setOrders((prev) => {
      const t: TrackedOrder = {
        id: o.id,
        code: o.code,
        createdAt: o.createdAt ?? new Date().toISOString(),
        status: o.status ?? "recibido",
      };
      return prune([t, ...prev.filter((x) => x.id !== o.id)]).slice(0, 6);
    });
  }, []);

  const dismiss = useCallback((id: string) => {
    setOrders((prev) => prev.filter((x) => x.id !== id));
  }, []);

  // Consultar estados en vivo (un solo intervalo, lee la lista más reciente por ref)
  useEffect(() => {
    if (!ready) return;
    let stop = false;
    const tick = async () => {
      const list = ordersRef.current.filter(
        (o) => o.status !== "recogido" && Date.now() - new Date(o.createdAt).getTime() < MAX_AGE,
      );
      if (list.length === 0) return;
      const updates = await Promise.all(
        list.map(async (o) => {
          try {
            const s = await getOrderStatus(o.id);
            return { id: o.id, status: s.status };
          } catch {
            return null;
          }
        }),
      );
      if (stop) return;
      setOrders((prev) =>
        prune(
          prev.map((o) => {
            const u = updates.find((x) => x && x.id === o.id);
            return u ? { ...o, status: u.status } : o;
          }),
        ),
      );
    };
    tick();
    const iv = setInterval(tick, POLL_MS);
    return () => {
      stop = true;
      clearInterval(iv);
    };
  }, [ready]);

  return <Ctx.Provider value={{ orders, addOrder, dismiss }}>{children}</Ctx.Provider>;
}

export function useMyOrders(): OrdersAPI {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useMyOrders debe usarse dentro de <OrdersProvider>");
  return ctx;
}

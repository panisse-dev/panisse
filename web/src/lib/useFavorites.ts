"use client";

import { useCallback, useEffect, useState } from "react";

const KEY = "panisse-favorites";

export function useFavorites() {
  const [favorites, setFavorites] = useState<Set<string>>(new Set());

  // Load after mount to avoid SSR/client hydration mismatch
  useEffect(() => {
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) setFavorites(new Set(JSON.parse(raw) as string[]));
    } catch {
      /* localStorage unavailable — favorites stay in memory */
    }
  }, []);

  const toggle = useCallback((id: string) => {
    setFavorites((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      try {
        localStorage.setItem(KEY, JSON.stringify([...next]));
      } catch {
        /* ignore */
      }
      return next;
    });
  }, []);

  return { favorites, toggle };
}

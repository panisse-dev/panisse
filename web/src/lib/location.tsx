"use client";

import { createContext, useContext, useEffect, useState } from "react";
import { rpc } from "./supabase";

export interface Sede {
  id: string;
  name: string;
  address: string;
  whatsapp: string;
}

interface LocationAPI {
  sedes: Sede[];
  sedeId: string | null;
  sede: Sede | null;
  setSede: (id: string) => void;
  clearSede: () => void;
  ready: boolean;
}

const KEY = "panisse-sede";
const Ctx = createContext<LocationAPI | null>(null);

export function LocationProvider({ children }: { children: React.ReactNode }) {
  const [sedes, setSedes] = useState<Sede[]>([]);
  const [sedeId, setSedeId] = useState<string | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    try {
      const saved = localStorage.getItem(KEY);
      if (saved) setSedeId(saved);
    } catch {
      /* ignore */
    }
    rpc<Sede[]>("public_locations")
      .then((list) => setSedes(list))
      .catch(() => setSedes([]))
      .finally(() => setReady(true));
  }, []);

  const setSede = (id: string) => {
    setSedeId(id);
    try {
      localStorage.setItem(KEY, id);
    } catch {
      /* ignore */
    }
  };

  const clearSede = () => {
    setSedeId(null);
    try {
      localStorage.removeItem(KEY);
    } catch {
      /* ignore */
    }
  };

  // La sede vale sólo si sigue existiendo en la lista (una vez cargada).
  const exists = !ready || sedes.length === 0 || sedes.some((s) => s.id === sedeId);
  const validId = sedeId && exists ? sedeId : null;
  const sede = sedes.find((s) => s.id === validId) ?? null;

  return (
    <Ctx.Provider value={{ sedes, sedeId: validId, sede, setSede, clearSede, ready }}>
      {children}
    </Ctx.Provider>
  );
}

export function useLocation(): LocationAPI {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useLocation debe usarse dentro de <LocationProvider>");
  return ctx;
}

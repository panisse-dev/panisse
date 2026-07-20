"use client";

// Marco del panel: puerta de acceso con clave del personal + navegación
// entre Pedidos, Menú, Clientes y Analítica. Expone la clave por contexto.
import Link from "next/link";
import { usePathname } from "next/navigation";
import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { CODE_KEY, staffVerify } from "@/lib/admin";

interface StaffCtx {
  code: string;
  logout: () => void;
}

const Ctx = createContext<StaffCtx | null>(null);

export function useStaff(): StaffCtx {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useStaff debe usarse dentro de <AdminShell>");
  return ctx;
}

const TABS = [
  { href: "/admin", label: "Pedidos" },
  { href: "/admin/menu", label: "Menú" },
  { href: "/admin/clientes", label: "Clientes" },
  { href: "/admin/analitica", label: "Analítica" },
];

export default function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [code, setCode] = useState("");
  const [authed, setAuthed] = useState(false);
  const [checked, setChecked] = useState(false);
  const [input, setInput] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem(CODE_KEY);
    if (saved) {
      setCode(saved);
      setAuthed(true);
    }
    setChecked(true);
  }, []);

  const login = async () => {
    const c = input.trim();
    if (!c || busy) return;
    setError("");
    setBusy(true);
    try {
      const ok = await staffVerify(c);
      if (!ok) {
        setError("Clave incorrecta.");
        return;
      }
      localStorage.setItem(CODE_KEY, c);
      setCode(c);
      setAuthed(true);
    } catch {
      setError("No se pudo conectar. Revisa tu internet.");
    } finally {
      setBusy(false);
    }
  };

  const logout = useCallback(() => {
    localStorage.removeItem(CODE_KEY);
    setCode("");
    setAuthed(false);
  }, []);

  if (!checked) return null;

  if (!authed) {
    return (
      <div className="mx-auto flex min-h-dvh max-w-sm flex-col justify-center px-8">
        <h1 className="text-center font-display text-[26px] text-navy">PANISSE</h1>
        <p className="mt-1 text-center text-[13px] text-ink-faint">Panel de administración</p>
        <input
          type="password"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && login()}
          placeholder="Clave de acceso"
          className="mt-8 h-12 w-full border border-gold-soft/70 bg-card px-4 text-center text-[16px] tracking-wide text-ink outline-none focus:border-navy"
          autoFocus
        />
        {error && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{error}</p>}
        <button
          type="button"
          onClick={login}
          disabled={busy}
          className="mt-4 h-12 w-full bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60"
        >
          {busy ? "Verificando…" : "Entrar"}
        </button>
      </div>
    );
  }

  return (
    <Ctx.Provider value={{ code, logout }}>
      <div className="mx-auto min-h-dvh w-full max-w-5xl px-3 pb-16">
        <header className="sticky top-0 z-30 -mx-3 border-b border-gold-soft/50 bg-paper/95 px-3 backdrop-blur-md">
          <div className="flex items-center justify-between pb-1 pt-[calc(env(safe-area-inset-top)+10px)]">
            <div className="px-1">
              <p className="smallcaps text-[9px] text-gold-deep">Panisse</p>
              <h1 className="font-display text-[18px] leading-tight text-navy">Panel</h1>
            </div>
            <button
              type="button"
              onClick={logout}
              className="px-2 py-1 text-[11.5px] text-ink-faint underline underline-offset-2"
            >
              Salir
            </button>
          </div>
          <nav aria-label="Secciones del panel" className="chips-scroll -mx-1 flex gap-1.5 overflow-x-auto px-1 pb-2.5 pt-1">
            {TABS.map((t) => {
              const active =
                t.href === "/admin" ? pathname === "/admin" : pathname.startsWith(t.href);
              return (
                <Link
                  key={t.href}
                  href={t.href}
                  className={`smallcaps flex h-9 shrink-0 items-center whitespace-nowrap border px-4 text-[10.5px] font-medium transition-colors ${
                    active
                      ? "border-navy bg-navy text-gold-soft"
                      : "border-gold-soft/60 bg-card text-ink-soft"
                  }`}
                >
                  {t.label}
                </Link>
              );
            })}
          </nav>
        </header>
        {children}
      </div>
    </Ctx.Provider>
  );
}

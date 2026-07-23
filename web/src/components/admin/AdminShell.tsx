"use client";

// Marco del panel: puerta de acceso con clave del personal + navegación
// entre Pedidos, Menú, Clientes y Analítica. En escritorio usa una barra
// lateral fija (el trabajador lo abre en PC); en móvil, pestañas arriba.
import Link from "next/link";
import { usePathname } from "next/navigation";
import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { CODE_KEY, staffContext, staffVerify } from "@/lib/admin";

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

type IconProps = { className?: string };
const Icon = ({ d, className }: { d: string; className?: string }) => (
  <svg
    viewBox="0 0 24 24"
    className={className}
    fill="none"
    stroke="currentColor"
    strokeWidth="1.7"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden
  >
    {d.split("|").map((p, i) => (
      <path key={i} d={p} />
    ))}
  </svg>
);

const TABS: { href: string; label: string; icon: (p: IconProps) => React.ReactNode }[] = [
  {
    href: "/admin",
    label: "Pedidos",
    icon: (p) => <Icon {...p} d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9|M13.7 21a2 2 0 0 1-3.4 0" />,
  },
  {
    href: "/admin/reservas",
    label: "Reservas",
    icon: (p) => <Icon {...p} d="M8 2v4M16 2v4M3 10h18|M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z" />,
  },
  {
    href: "/admin/menu",
    label: "Menú",
    icon: (p) => <Icon {...p} d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />,
  },
  {
    href: "/admin/clientes",
    label: "Clientes",
    icon: (p) => <Icon {...p} d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" />,
  },
  {
    href: "/admin/analitica",
    label: "Analítica",
    icon: (p) => <Icon {...p} d="M3 3v18h18M18 17V9M13 17V5M8 17v-3" />,
  },
  {
    href: "/admin/ajustes",
    label: "Ajustes",
    icon: (p) => <Icon {...p} d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z|M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />,
  },
];

function isActive(href: string, pathname: string): boolean {
  return href === "/admin" ? pathname === "/admin" : pathname.startsWith(href);
}

export default function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [code, setCode] = useState("");
  const [authed, setAuthed] = useState(false);
  const [checked, setChecked] = useState(false);
  const [input, setInput] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [sedeName, setSedeName] = useState("");
  // Cambio de sede: pide la clave de la otra sede y cambia el contexto.
  const [switchOpen, setSwitchOpen] = useState(false);
  const [switchInput, setSwitchInput] = useState("");
  const [switchError, setSwitchError] = useState("");
  const [switchBusy, setSwitchBusy] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem(CODE_KEY);
    if (saved) {
      setCode(saved);
      setAuthed(true);
    }
    setChecked(true);
  }, []);

  // Sede según la clave con que se entró (o "Todas las sedes" para el dueño).
  useEffect(() => {
    if (!code) {
      setSedeName("");
      return;
    }
    staffContext(code)
      .then((c) => setSedeName(c.locationName))
      .catch(() => setSedeName(""));
  }, [code]);

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

  // Cambiar de sede sin salir: verifica la clave de la otra sede y cambia.
  const doSwitch = async () => {
    const c = switchInput.trim();
    if (!c || switchBusy) return;
    setSwitchError("");
    setSwitchBusy(true);
    try {
      const ok = await staffVerify(c);
      if (!ok) {
        setSwitchError("Clave incorrecta.");
        return;
      }
      localStorage.setItem(CODE_KEY, c);
      setCode(c);
      setSwitchOpen(false);
      setSwitchInput("");
    } catch {
      setSwitchError("No se pudo conectar.");
    } finally {
      setSwitchBusy(false);
    }
  };

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
      <div className="min-h-dvh lg:flex">
        {/* ── Barra lateral (escritorio) ── */}
        <aside className="fixed inset-y-0 left-0 z-30 hidden w-60 flex-col border-r border-gold-soft/40 bg-navy px-4 py-6 lg:flex">
          <div className="px-2">
            <p className="smallcaps text-[10px] text-gold-soft/70">Panisse</p>
            <h1 className="font-display text-[22px] leading-tight text-gold-soft">Panel</h1>
            {sedeName && (
              <p className="smallcaps mt-1.5 flex items-center gap-1.5 text-[10.5px] font-semibold text-gold-soft/90">
                <span className="inline-block h-1.5 w-1.5 rounded-full bg-gold-soft" />
                {sedeName}
              </p>
            )}
          </div>
          <nav aria-label="Secciones del panel" className="mt-8 flex flex-col gap-1.5">
            {TABS.map((t) => {
              const active = isActive(t.href, pathname);
              return (
                <Link
                  key={t.href}
                  href={t.href}
                  className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-[14px] font-medium transition-colors ${
                    active
                      ? "bg-gold-soft text-navy"
                      : "text-gold-soft/70 hover:bg-white/5 hover:text-gold-soft"
                  }`}
                >
                  {t.icon({ className: "h-5 w-5 shrink-0" })}
                  {t.label}
                </Link>
              );
            })}
          </nav>
          <div className="mt-auto flex flex-col gap-1">
            <button
              type="button"
              onClick={() => {
                setSwitchOpen(true);
                setSwitchInput("");
                setSwitchError("");
              }}
              className="flex items-center gap-2 rounded-lg px-3 py-2.5 text-[13px] font-medium text-gold-soft/70 hover:bg-white/5 hover:text-gold-soft"
            >
              <Icon className="h-4.5 w-4.5" d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z|M12 10a2 2 0 1 0 0-4 2 2 0 0 0 0 4" />
              Cambiar sede
            </button>
            <button
              type="button"
              onClick={logout}
              className="flex items-center gap-2 rounded-lg px-3 py-2.5 text-[13px] font-medium text-gold-soft/60 hover:bg-white/5 hover:text-gold-soft"
            >
              <Icon className="h-4.5 w-4.5" d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9" />
              Salir
            </button>
          </div>
        </aside>

        {/* ── Barra superior (móvil) ── */}
        <header className="sticky top-0 z-30 border-b border-gold-soft/50 bg-paper/95 px-3 backdrop-blur-md lg:hidden">
          <div className="flex items-center justify-between pb-1 pt-[calc(env(safe-area-inset-top)+10px)]">
            <div className="px-1">
              <p className="smallcaps text-[9px] text-gold-deep">Panisse</p>
              <h1 className="font-display text-[18px] leading-tight text-navy">Panel</h1>
              {sedeName && (
                <p className="mt-0.5 flex items-center gap-1 text-[10.5px] font-semibold leading-tight text-gold-deep">
                  <span className="inline-block h-1.5 w-1.5 rounded-full bg-gold-deep" />
                  {sedeName}
                </p>
              )}
            </div>
            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={() => {
                  setSwitchOpen(true);
                  setSwitchInput("");
                  setSwitchError("");
                }}
                className="px-1 py-1 text-[11.5px] text-gold-deep underline underline-offset-2"
              >
                Cambiar sede
              </button>
              <button
                type="button"
                onClick={logout}
                className="px-1 py-1 text-[11.5px] text-ink-faint underline underline-offset-2"
              >
                Salir
              </button>
            </div>
          </div>
          <nav aria-label="Secciones del panel" className="chips-scroll -mx-1 flex gap-1.5 overflow-x-auto px-1 pb-2.5 pt-1">
            {TABS.map((t) => {
              const active = isActive(t.href, pathname);
              return (
                <Link
                  key={t.href}
                  href={t.href}
                  className={`smallcaps flex h-9 shrink-0 items-center gap-1.5 whitespace-nowrap border px-4 text-[10.5px] font-medium transition-colors ${
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

        {/* ── Contenido ── */}
        <main className="flex-1 lg:pl-60">
          <div className="mx-auto w-full max-w-6xl px-3 pb-16 lg:px-8 lg:pt-6">{children}</div>
        </main>
      </div>

      {/* ── Cambiar de sede (pide la clave) ── */}
      {switchOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6" role="dialog" aria-modal="true" aria-label="Cambiar de sede">
          <button type="button" aria-label="Cerrar" onClick={() => setSwitchOpen(false)} className="anim-fade-in absolute inset-0 bg-navy/50 backdrop-blur-[2px]" />
          <div className="anim-fade-up relative w-full max-w-xs border border-gold-soft/60 bg-card px-6 py-6 shadow-[0_12px_40px_rgba(4,17,29,0.3)]">
            <h2 className="text-center font-display text-[19px] text-navy">Cambiar de sede</h2>
            <p className="mt-1 text-center text-[12px] text-ink-faint">
              Escribe la clave de la sede a la que quieres entrar.
            </p>
            <input
              type="password"
              value={switchInput}
              onChange={(e) => setSwitchInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && doSwitch()}
              placeholder="Clave de la sede"
              autoFocus
              className="mt-4 h-12 w-full border border-gold-soft/70 bg-paper px-4 text-center text-[16px] tracking-wide text-ink outline-none focus:border-navy"
            />
            {switchError && <p className="mt-2 text-center text-[12.5px] text-[#b3261e]">{switchError}</p>}
            <div className="mt-4 flex gap-2">
              <button type="button" onClick={doSwitch} disabled={switchBusy} className="h-11 flex-1 bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60">
                {switchBusy ? "Verificando…" : "Cambiar"}
              </button>
              <button type="button" onClick={() => setSwitchOpen(false)} className="h-11 border border-gold-soft/70 px-4 text-[13px] text-ink-soft">
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}
    </Ctx.Provider>
  );
}

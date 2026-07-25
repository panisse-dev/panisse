"use client";

// Editor de la apariencia de las cartas (Panisse / Roka).
//
// Todo lo que se toca aquí se ve al instante en la vista previa, que usa
// exactamente las mismas variables CSS que la carta real: lo que se ve es
// lo que van a ver los clientes.

import { useCallback, useEffect, useState } from "react";
import { isAuthError, staffMenuThemes, staffSaveMenuTheme, uploadImage } from "@/lib/admin";
import {
  DEFAULT_MENU_THEME,
  menuThemeVars,
  type Background,
  type MenuTheme,
  type SectionStyle,
} from "@/lib/menuTheme";
import { FONT_OPTIONS, type FontKey } from "@/lib/theme";

const BRANDS: { id: string; label: string }[] = [
  { id: "panisse", label: "Carta Panisse" },
  { id: "roka", label: "Carta Roka" },
];

const SCALES: { v: number; label: string }[] = [
  { v: 0.9, label: "Pequeña" },
  { v: 1, label: "Normal" },
  { v: 1.1, label: "Grande" },
  { v: 1.25, label: "Muy grande" },
];

const BACKGROUNDS: { v: Background; label: string }[] = [
  { v: "marble", label: "Mármol" },
  { v: "plain", label: "Color liso" },
  { v: "image", label: "Foto" },
];

const SECTIONS: { v: SectionStyle; label: string }[] = [
  { v: "ornament", label: "Adorno clásico" },
  { v: "boxed", label: "Recuadro" },
];

export default function MenuSkinEditor({
  code,
  onAuth,
}: {
  code: string;
  onAuth: () => void;
}) {
  const [brand, setBrand] = useState("panisse");
  const [themes, setThemes] = useState<Record<string, MenuTheme> | null>(null);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");
  const [uploading, setUploading] = useState(false);

  const load = useCallback(async () => {
    try {
      const all = await staffMenuThemes(code);
      setThemes({
        panisse: { ...DEFAULT_MENU_THEME.panisse, ...(all?.panisse ?? {}) },
        roka: { ...DEFAULT_MENU_THEME.roka, ...(all?.roka ?? {}) },
      });
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setThemes({ ...DEFAULT_MENU_THEME });
    }
  }, [code, onAuth]);

  useEffect(() => {
    load();
  }, [load]);

  if (!themes) {
    return <p className="mt-3 text-[12.5px] text-ink-faint">Cargando…</p>;
  }

  const t = themes[brand];
  const set = (patch: Partial<MenuTheme>) => {
    setThemes((prev) => (prev ? { ...prev, [brand]: { ...prev[brand], ...patch } } : prev));
    setMsg("");
  };

  const save = async () => {
    setSaving(true);
    setMsg("");
    try {
      await staffSaveMenuTheme(code, brand, t);
      setMsg("Guardado ✓ ya lo ven los clientes");
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setMsg("No se pudo guardar.");
    } finally {
      setSaving(false);
    }
  };

  const restore = () => {
    if (!window.confirm("¿Volver al diseño original de esta carta?")) return;
    set({ ...DEFAULT_MENU_THEME[brand] });
  };

  const pickImage = async (file: File | null) => {
    if (!file) return;
    setUploading(true);
    setMsg("");
    try {
      const url = await uploadImage(code, file);
      set({ bgImage: url, background: "image" });
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setMsg("No se pudo subir la foto.");
    } finally {
      setUploading(false);
    }
  };

  return (
    <div>
      {/* Qué carta se está editando */}
      <div className="mt-3 grid grid-cols-2 gap-1.5">
        {BRANDS.map((b) => (
          <button
            key={b.id}
            type="button"
            onClick={() => {
              setBrand(b.id);
              setMsg("");
            }}
            className={`smallcaps h-10 border text-[11px] font-medium ${brand === b.id ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-card text-ink-soft"}`}
          >
            {b.label}
          </button>
        ))}
      </div>

      <div className="mt-3 lg:flex lg:items-start lg:gap-4">
        {/* ── Controles ── */}
        <div className="lg:min-w-0 lg:flex-1">
          <Group title="Fondo de la carta">
            <div className="grid grid-cols-3 gap-1.5">
              {BACKGROUNDS.map((o) => (
                <button
                  key={o.v}
                  type="button"
                  onClick={() => set({ background: o.v })}
                  className={`h-9 border text-[11.5px] ${t.background === o.v ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-card text-ink-soft"}`}
                >
                  {o.label}
                </button>
              ))}
            </div>
            {t.background === "image" && (
              <div className="mt-2 flex items-center gap-2">
                {t.bgImage && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={t.bgImage}
                    alt="Fondo de la carta"
                    className="h-14 w-14 shrink-0 rounded border border-gold-soft/50 object-cover"
                  />
                )}
                <label className="flex h-9 cursor-pointer items-center border border-gold-soft/70 px-3 text-[11.5px] text-gold-deep">
                  {uploading ? "Subiendo…" : t.bgImage ? "Cambiar foto" : "Subir foto"}
                  <input
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={(e) => pickImage(e.target.files?.[0] ?? null)}
                  />
                </label>
                {t.bgImage && (
                  <button
                    type="button"
                    onClick={() => set({ bgImage: null, background: "plain" })}
                    className="h-9 border border-gold-soft/70 px-3 text-[11.5px] text-ink-soft"
                  >
                    Quitar
                  </button>
                )}
              </div>
            )}
            <p className="mt-1.5 text-[10.5px] leading-snug text-ink-faint">
              Sobre la foto se pone un velo blanco para que los platos se sigan leyendo.
            </p>
          </Group>

          <Group title="Colores">
            <div className="grid grid-cols-2 gap-2">
              <Color label="Fondo" value={t.bgColor} onChange={(v) => set({ bgColor: v })} />
              <Color label="Tarjetas" value={t.cardColor} onChange={(v) => set({ cardColor: v })} />
              <Color label="Títulos" value={t.titleColor} onChange={(v) => set({ titleColor: v })} />
              <Color label="Texto" value={t.textColor} onChange={(v) => set({ textColor: v })} />
              <Color label="Detalles y precios" value={t.goldColor} onChange={(v) => set({ goldColor: v })} />
            </div>
          </Group>

          <Group title="Letra">
            <div className="grid gap-2 sm:grid-cols-2">
              <label className="block">
                <span className="smallcaps text-[9px] text-gold-deep">Títulos</span>
                <select
                  value={t.titleFont}
                  onChange={(e) => set({ titleFont: e.target.value as FontKey })}
                  className="mt-1 h-10 w-full border border-gold-soft/70 bg-card px-2 text-[12.5px] text-ink outline-none focus:border-navy"
                >
                  {FONT_OPTIONS.map((f) => (
                    <option key={f.key} value={f.key}>{f.label}</option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="smallcaps text-[9px] text-gold-deep">Textos</span>
                <select
                  value={t.bodyFont}
                  onChange={(e) => set({ bodyFont: e.target.value as FontKey })}
                  className="mt-1 h-10 w-full border border-gold-soft/70 bg-card px-2 text-[12.5px] text-ink outline-none focus:border-navy"
                >
                  {FONT_OPTIONS.map((f) => (
                    <option key={f.key} value={f.key}>{f.label}</option>
                  ))}
                </select>
              </label>
            </div>
            <p className="smallcaps mt-2.5 text-[9px] text-gold-deep">Tamaño general</p>
            <div className="mt-1 grid grid-cols-4 gap-1.5">
              {SCALES.map((o) => (
                <button
                  key={o.v}
                  type="button"
                  onClick={() => set({ scale: o.v })}
                  className={`h-9 border text-[11px] ${t.scale === o.v ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-card text-ink-soft"}`}
                >
                  {o.label}
                </button>
              ))}
            </div>
          </Group>

          <Group title="Títulos de sección">
            <div className="grid grid-cols-2 gap-1.5">
              {SECTIONS.map((o) => (
                <button
                  key={o.v}
                  type="button"
                  onClick={() => set({ sectionStyle: o.v })}
                  className={`h-9 border text-[11.5px] ${t.sectionStyle === o.v ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-card text-ink-soft"}`}
                >
                  {o.label}
                </button>
              ))}
            </div>
          </Group>
        </div>

        {/* ── Vista previa: usa las mismas variables que la carta real ── */}
        <div className="mt-4 lg:mt-0 lg:w-[320px] lg:shrink-0">
          <p className="smallcaps text-[9px] text-gold-deep">Así se va a ver</p>
          <div
            data-menu-skin
            data-section-style={t.sectionStyle}
            style={{
              ...menuThemeVars(t),
              backgroundColor: "var(--color-paper)",
              backgroundImage:
                t.background === "image" && t.bgImage
                  ? `linear-gradient(rgba(255,255,255,0.72), rgba(255,255,255,0.72)), url(${t.bgImage})`
                  : t.background === "marble"
                    ? 'url("/images/menus/dfc3a969-3a35-45ba-88f0-630986c314bb.webp")'
                    : undefined,
              backgroundSize: "cover",
              backgroundPosition: "center",
            }}
            className="mt-1 overflow-hidden border border-gold-soft/60 p-4"
          >
            <p className="smallcaps text-center text-[9px] text-gold-deep">
              {brand === "roka" ? "Roka" : "Panisse"}
            </p>
            <div className="ornament mt-2 text-center text-gold">
              <h2 className="font-display text-[22px] leading-tight text-navy">Entradas</h2>
            </div>
            <div className="mt-3 border border-gold-soft/35 bg-card px-3 py-3">
              <div className="flex items-baseline justify-between gap-2">
                <h4 className="font-display text-[16.5px] leading-snug text-navy">Caprese</h4>
                <span className="shrink-0 text-[13px] font-semibold text-gold-deep">$29.900</span>
              </div>
              <p className="mt-0.5 text-[12px] leading-snug text-ink-soft">
                Tostada de focaccia, mozzarella de búfala y tomate confitado.
              </p>
              <div className="mt-3 border-t border-gold-soft/25 pt-3">
                <div className="flex items-baseline justify-between gap-2">
                  <h4 className="font-display text-[16.5px] leading-snug text-navy">Trufada</h4>
                  <span className="shrink-0 text-[13px] font-semibold text-gold-deep">$24.900</span>
                </div>
                <p className="mt-0.5 text-[12px] leading-snug text-ink-soft">
                  Pan italiano, huevos cremados y queso trufado.
                </p>
              </div>
            </div>
            <div className="mt-3 flex items-center justify-center gap-2 bg-navy px-4 py-2.5 text-gold-soft">
              <span className="smallcaps text-[11px] font-medium tracking-[0.12em]">
                Reservar una mesa
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-gold-soft/30 pt-3">
        <button
          type="button"
          onClick={save}
          disabled={saving}
          className="h-11 bg-navy px-6 text-[13.5px] font-semibold text-gold-soft disabled:opacity-60"
        >
          {saving ? "Guardando…" : "Guardar"}
        </button>
        <button
          type="button"
          onClick={restore}
          className="h-11 border border-gold-soft/70 px-4 text-[12.5px] text-ink-soft"
        >
          Volver al diseño original
        </button>
        {msg && <span className="text-[12px] text-verde">{msg}</span>}
      </div>
    </div>
  );
}

function Group({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="mt-3 border border-gold-soft/50 bg-paper p-3">
      <p className="smallcaps text-[10px] font-semibold text-gold-deep">{title}</p>
      <div className="mt-2">{children}</div>
    </div>
  );
}

function Color({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <label className="block">
      <span className="smallcaps text-[9px] text-gold-deep">{label}</span>
      <div className="mt-1 flex items-center gap-2">
        <input
          type="color"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="h-9 w-10 shrink-0 cursor-pointer border border-gold-soft/70 bg-card p-0.5"
        />
        <input
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="h-9 w-full min-w-0 border border-gold-soft/70 bg-card px-2 text-[12px] text-ink outline-none focus:border-navy"
        />
      </div>
    </label>
  );
}

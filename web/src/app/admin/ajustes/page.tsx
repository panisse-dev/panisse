"use client";

// Ajustes editables desde el panel: datos de cada sede (teléfono, WhatsApp,
// dirección) y los títulos de los menús. Cada bloque se guarda por separado.
import { useCallback, useEffect, useState } from "react";
import {
  isAuthError,
  staffDeliverySettings,
  staffHomeTheme,
  staffLocations,
  staffMenus,
  staffUpdateDeliverySettings,
  staffUpdateHomeTheme,
  staffUpdateLocation,
  staffUpdateMenu,
  type DeliverySettings,
  type LocationRow,
  type MenuRow,
} from "@/lib/admin";
import { useStaff } from "@/components/admin/AdminShell";
import { formatCOP } from "@/lib/format";
import {
  DEFAULT_HOME_THEME,
  fontStack,
  FONT_OPTIONS,
  type FontKey,
  type HomeTheme,
  type ThemeText,
} from "@/lib/theme";

export default function AjustesPage() {
  const { code, logout } = useStaff();
  const [locations, setLocations] = useState<LocationRow[]>([]);
  const [menus, setMenus] = useState<MenuRow[]>([]);
  const [deliveries, setDeliveries] = useState<DeliverySettings[]>([]);
  const [theme, setTheme] = useState<HomeTheme | null>(null);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    try {
      const [locs, mns, dels, thm] = await Promise.all([
        staffLocations(code),
        staffMenus(code),
        staffDeliverySettings(code),
        staffHomeTheme(code),
      ]);
      setLocations(locs);
      setMenus(mns);
      setDeliveries(dels);
      setTheme(thm);
      setError("");
    } catch (e) {
      if (isAuthError(e)) logout();
      else setError("No se pudo cargar. Revisa tu internet.");
    }
  }, [code, logout]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div className="mx-auto max-w-2xl">
      <h1 className="mt-3 hidden font-display text-[20px] text-navy lg:block">Ajustes</h1>
      {error && <p className="mt-4 text-center text-[12.5px] text-[#b3261e]">{error}</p>}

      {/* ── Apariencia de la portada ── */}
      <section className="mt-4">
        <h2 className="smallcaps text-[11px] font-semibold text-gold-deep">Apariencia de la portada</h2>
        <p className="mt-1 text-[11.5px] text-ink-faint">
          Personaliza los títulos que ve el cliente al entrar: texto, tipo de letra, tamaño, color y
          el fondo. Se ve al instante.
        </p>
        {theme && <AppearanceEditor code={code} initial={theme} onAuth={logout} />}
      </section>

      {/* ── Sedes ── */}
      <section className="mt-4">
        <h2 className="smallcaps text-[11px] font-semibold text-gold-deep">Sedes</h2>
        <p className="mt-1 text-[11.5px] text-ink-faint">
          Estos datos los ve el cliente (dirección y WhatsApp) según la sede que elija.
        </p>
        <div className="mt-3 flex flex-col gap-3">
          {locations.map((l) => (
            <LocationCard key={l.id} code={code} loc={l} onSaved={load} onAuth={logout} />
          ))}
        </div>
      </section>

      {/* ── Domicilios ── */}
      <section className="mt-8">
        <h2 className="smallcaps text-[11px] font-semibold text-gold-deep">Domicilios</h2>
        <p className="mt-1 text-[11.5px] text-ink-faint">
          Enciende los domicilios por sede y define el costo, el pedido mínimo y el horario. Viene
          apagado hasta que lo actives.
        </p>
        <div className="mt-3 flex flex-col gap-3">
          {deliveries.map((d) => (
            <DeliveryCard key={d.locationId} code={code} data={d} onSaved={load} onAuth={logout} />
          ))}
        </div>
      </section>

      {/* ── Títulos de los menús ── */}
      <section className="mt-8">
        <h2 className="smallcaps text-[11px] font-semibold text-gold-deep">Títulos de los menús</h2>
        <p className="mt-1 text-[11.5px] text-ink-faint">
          El nombre y la frase de cada carta que ve el cliente en el inicio.
        </p>
        <div className="mt-3 flex flex-col gap-3">
          {menus.map((m) => (
            <MenuCard key={m.slug} code={code} menu={m} onSaved={load} onAuth={logout} />
          ))}
        </div>
      </section>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) {
  return (
    <label className="block">
      <span className="smallcaps text-[10px] text-gold-deep">{label}</span>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy"
      />
    </label>
  );
}

function SaveRow({ saving, msg, onSave }: { saving: boolean; msg: string; onSave: () => void }) {
  return (
    <div className="mt-3 flex items-center gap-3">
      <button
        type="button"
        onClick={onSave}
        disabled={saving}
        className="h-11 flex-1 bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60"
      >
        {saving ? "Guardando…" : "Guardar"}
      </button>
      {msg && <span className="text-[12px] text-ink-soft">{msg}</span>}
    </div>
  );
}

function LocationCard({
  code,
  loc,
  onSaved,
  onAuth,
}: {
  code: string;
  loc: LocationRow;
  onSaved: () => void;
  onAuth: () => void;
}) {
  const [name, setName] = useState(loc.name);
  const [address, setAddress] = useState(loc.address);
  const [whatsapp, setWhatsapp] = useState(loc.whatsapp);
  const [phone, setPhone] = useState(loc.phone);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  const save = async () => {
    setSaving(true);
    setMsg("");
    try {
      await staffUpdateLocation(code, loc.id, {
        name: name.trim(),
        address: address.trim(),
        whatsapp: whatsapp.trim(),
        phone: phone.trim(),
      });
      setMsg("Guardado ✓");
      onSaved();
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setMsg("No se pudo guardar.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="border border-gold-soft/60 bg-paper p-4">
      <p className="font-display text-[16px] text-navy">{loc.name}</p>
      <div className="mt-2 flex flex-col gap-3">
        <Field label="Nombre de la sede" value={name} onChange={setName} />
        <Field label="Dirección" value={address} onChange={setAddress} placeholder="Calle 00 #00-00, Pereira" />
        <Field label="WhatsApp" value={whatsapp} onChange={setWhatsapp} placeholder="+57 312 000 0000" />
        <Field label="Teléfono (opcional)" value={phone} onChange={setPhone} />
      </div>
      <SaveRow saving={saving} msg={msg} onSave={save} />
    </div>
  );
}

function MenuCard({
  code,
  menu,
  onSaved,
  onAuth,
}: {
  code: string;
  menu: MenuRow;
  onSaved: () => void;
  onAuth: () => void;
}) {
  const [label, setLabel] = useState(menu.label);
  const [tagline, setTagline] = useState(menu.tagline);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  const save = async () => {
    setSaving(true);
    setMsg("");
    try {
      await staffUpdateMenu(code, menu.slug, { label: label.trim(), tagline: tagline.trim() });
      setMsg("Guardado ✓");
      onSaved();
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setMsg("No se pudo guardar.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="border border-gold-soft/60 bg-paper p-4">
      <div className="flex flex-col gap-3">
        <Field label="Título" value={label} onChange={setLabel} />
        <Field label="Frase debajo" value={tagline} onChange={setTagline} />
      </div>
      <SaveRow saving={saving} msg={msg} onSave={save} />
    </div>
  );
}

function DeliveryCard({
  code,
  data,
  onSaved,
  onAuth,
}: {
  code: string;
  data: DeliverySettings;
  onSaved: () => void;
  onAuth: () => void;
}) {
  const [d, setD] = useState<DeliverySettings>(data);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  const set = <K extends keyof DeliverySettings>(k: K, v: DeliverySettings[K]) =>
    setD((prev) => ({ ...prev, [k]: v }));

  const save = async () => {
    setSaving(true);
    setMsg("");
    try {
      await staffUpdateDeliverySettings(code, d.locationId, {
        enabled: d.enabled,
        fee: d.fee,
        minOrder: d.minOrder,
        scheduling: d.scheduling,
        leadMinutes: d.leadMinutes,
        daysAhead: d.daysAhead,
        startTime: d.startTime,
        endTime: d.endTime,
        note: d.note,
      });
      setMsg("Guardado ✓");
      onSaved();
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setMsg("No se pudo guardar.");
    } finally {
      setSaving(false);
    }
  };

  const num = (label: string, k: keyof DeliverySettings, suffix?: string, hint?: string) => (
    <label className="block">
      <span className="smallcaps text-[10px] text-gold-deep">{label}</span>
      <div className="mt-1 flex items-center gap-2">
        <input
          type="number"
          value={d[k] as number}
          onChange={(e) => set(k, Number(e.target.value) as never)}
          className="h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy"
        />
        {suffix && <span className="shrink-0 text-[12px] text-ink-faint">{suffix}</span>}
      </div>
      {hint && <span className="mt-1 block text-[10.5px] text-ink-faint">{hint}</span>}
    </label>
  );

  return (
    <div className="border border-gold-soft/60 bg-paper p-4">
      <div className="flex items-center justify-between">
        <p className="font-display text-[16px] text-navy">{d.locationName}</p>
        <label className="flex items-center gap-2 text-[12px] text-ink-soft">
          <input
            type="checkbox"
            checked={d.enabled}
            onChange={(e) => set("enabled", e.target.checked)}
            className="h-4 w-4 accent-[#04111D]"
          />
          Acepta domicilios
        </label>
      </div>

      {d.enabled && (
        <>
          <div className="mt-3 grid grid-cols-2 gap-3">
            {num("Costo del domicilio", "fee", "COP", d.fee > 0 ? formatCOP(d.fee) : "Gratis")}
            {num("Pedido mínimo", "minOrder", "COP", d.minOrder > 0 ? formatCOP(d.minOrder) : "Sin mínimo")}
          </div>

          <label className="mt-3 flex items-center gap-2 text-[12.5px] text-ink-soft">
            <input
              type="checkbox"
              checked={d.scheduling}
              onChange={(e) => set("scheduling", e.target.checked)}
              className="h-4 w-4 accent-[#04111D]"
            />
            Permitir programar día y hora
          </label>

          <div className="mt-3 grid grid-cols-2 gap-3">
            <label className="block">
              <span className="smallcaps text-[10px] text-gold-deep">Entregan desde</span>
              <input
                type="time"
                value={d.startTime}
                onChange={(e) => set("startTime", e.target.value)}
                className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy"
              />
            </label>
            <label className="block">
              <span className="smallcaps text-[10px] text-gold-deep">Hasta</span>
              <input
                type="time"
                value={d.endTime}
                onChange={(e) => set("endTime", e.target.value)}
                className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy"
              />
            </label>
            {num("Anticipación mínima", "leadMinutes", "min")}
            {num("Se programa hasta", "daysAhead", "días adelante")}
          </div>

          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Aviso para el cliente (opcional)</span>
            <input
              value={d.note}
              onChange={(e) => set("note", e.target.value)}
              placeholder="Ej. solo Cerritos y alrededores"
              className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy"
            />
          </label>
        </>
      )}

      <SaveRow saving={saving} msg={msg} onSave={save} />
    </div>
  );
}

// ── Editor de apariencia de la portada del cliente ──
function ColorField({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
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
          className="h-9 w-full border border-gold-soft/70 bg-card px-2 text-[12px] text-ink outline-none focus:border-navy"
        />
      </div>
    </label>
  );
}

function TextControls({
  t,
  onChange,
  minSize,
  maxSize,
  showText = true,
}: {
  t: ThemeText;
  onChange: (patch: Partial<ThemeText>) => void;
  minSize: number;
  maxSize: number;
  showText?: boolean;
}) {
  return (
    <div className="mt-2 flex flex-col gap-2">
      {showText && (
        <label className="block">
          <span className="smallcaps text-[9px] text-gold-deep">Texto</span>
          <input
            value={t.text}
            onChange={(e) => onChange({ text: e.target.value })}
            className="mt-1 h-10 w-full border border-gold-soft/70 bg-card px-3 text-[14px] text-ink outline-none focus:border-navy"
          />
        </label>
      )}
      <div className="grid grid-cols-2 gap-2">
        <label className="block">
          <span className="smallcaps text-[9px] text-gold-deep">Tipo de letra</span>
          <select
            value={t.font}
            onChange={(e) => onChange({ font: e.target.value as FontKey })}
            className="mt-1 h-10 w-full border border-gold-soft/70 bg-card px-2 text-[12.5px] text-ink outline-none focus:border-navy"
          >
            {FONT_OPTIONS.map((f) => (
              <option key={f.key} value={f.key}>{f.label}</option>
            ))}
          </select>
        </label>
        <ColorField label="Color" value={t.color} onChange={(v) => onChange({ color: v })} />
      </div>
      <label className="block">
        <span className="smallcaps text-[9px] text-gold-deep">Tamaño · {t.size}px</span>
        <input
          type="range"
          min={minSize}
          max={maxSize}
          value={t.size}
          onChange={(e) => onChange({ size: Number(e.target.value) })}
          className="mt-1 w-full accent-[#04111D]"
        />
      </label>
    </div>
  );
}

function AppearanceEditor({ code, initial, onAuth }: { code: string; initial: HomeTheme; onAuth: () => void }) {
  const [t, setT] = useState<HomeTheme>(initial);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  const save = async () => {
    setSaving(true);
    setMsg("");
    try {
      await staffUpdateHomeTheme(code, t);
      setMsg("Guardado ✓");
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setMsg("No se pudo guardar.");
    } finally {
      setSaving(false);
    }
  };

  const reset = () => setT(DEFAULT_HOME_THEME);

  return (
    <div className="mt-3 border border-gold-soft/60 bg-paper p-4">
      {/* Vista previa */}
      <span className="smallcaps text-[9px] text-gold-deep">Vista previa</span>
      <div
        className="mt-1 flex flex-col items-center rounded border border-gold-soft/50 px-4 py-6 text-center"
        style={{ backgroundColor: t.bgColor }}
      >
        <p className="smallcaps font-medium" style={{ fontFamily: fontStack(t.eyebrow.font), fontSize: t.eyebrow.size, color: t.eyebrow.color }}>
          {t.eyebrow.text}
        </p>
        <p className="mt-2 leading-none" style={{ fontFamily: fontStack(t.brand.font), fontSize: t.brand.size, color: t.brand.color, letterSpacing: "0.08em" }}>
          {t.brand.mode === "text" ? t.brand.text : "PANISSE"}
        </p>
        {t.brand.mode === "logo" && (
          <span className="mt-0.5 text-[9px] text-ink-faint">(logo actual)</span>
        )}
        <p className="mt-2 italic" style={{ fontFamily: fontStack(t.tagline.font), fontSize: t.tagline.size, color: t.tagline.color }}>
          {t.tagline.text}
        </p>
      </div>

      {/* Línea de arriba */}
      <div className="mt-4">
        <h3 className="text-[13px] font-semibold text-navy">Línea de arriba</h3>
        <TextControls t={t.eyebrow} minSize={8} maxSize={24} onChange={(p) => setT((s) => ({ ...s, eyebrow: { ...s.eyebrow, ...p } }))} />
      </div>

      {/* Nombre */}
      <div className="mt-4 border-t border-gold-soft/40 pt-3">
        <h3 className="text-[13px] font-semibold text-navy">Nombre (PANISSE)</h3>
        <div className="mt-2 flex gap-1.5">
          <button
            type="button"
            onClick={() => setT((s) => ({ ...s, brand: { ...s.brand, mode: "logo" } }))}
            className={`smallcaps h-9 flex-1 border text-[10.5px] font-medium ${t.brand.mode === "logo" ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-card text-ink-soft"}`}
          >
            Usar logo
          </button>
          <button
            type="button"
            onClick={() => setT((s) => ({ ...s, brand: { ...s.brand, mode: "text" } }))}
            className={`smallcaps h-9 flex-1 border text-[10.5px] font-medium ${t.brand.mode === "text" ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-card text-ink-soft"}`}
          >
            Usar texto editable
          </button>
        </div>
        {t.brand.mode === "text" ? (
          <TextControls t={t.brand} minSize={20} maxSize={90} onChange={(p) => setT((s) => ({ ...s, brand: { ...s.brand, ...p } }))} />
        ) : (
          <p className="mt-2 text-[11px] text-ink-faint">
            Se muestra el logo de PANISSE. Cambia a “texto editable” para ajustar letra, tamaño y color.
          </p>
        )}
      </div>

      {/* Frase de abajo */}
      <div className="mt-4 border-t border-gold-soft/40 pt-3">
        <h3 className="text-[13px] font-semibold text-navy">Frase de abajo</h3>
        <TextControls t={t.tagline} minSize={10} maxSize={30} onChange={(p) => setT((s) => ({ ...s, tagline: { ...s.tagline, ...p } }))} />
      </div>

      {/* Fondo */}
      <div className="mt-4 border-t border-gold-soft/40 pt-3">
        <h3 className="text-[13px] font-semibold text-navy">Fondo</h3>
        <div className="mt-2 grid grid-cols-2 gap-2">
          <ColorField label="Color de fondo" value={t.bgColor} onChange={(v) => setT((s) => ({ ...s, bgColor: v }))} />
          <label className="flex items-end gap-2 pb-1 text-[12.5px] text-ink-soft">
            <input
              type="checkbox"
              checked={t.showMarble}
              onChange={(e) => setT((s) => ({ ...s, showMarble: e.target.checked }))}
              className="h-4 w-4 accent-[#04111D]"
            />
            Mostrar textura de mármol
          </label>
        </div>
      </div>

      <div className="mt-4 flex items-center gap-3">
        <button type="button" onClick={save} disabled={saving} className="h-11 flex-1 bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60">
          {saving ? "Guardando…" : "Guardar apariencia"}
        </button>
        <button type="button" onClick={reset} className="h-11 border border-gold-soft/70 px-4 text-[12.5px] text-ink-soft">
          Restaurar
        </button>
        {msg && <span className="text-[12px] text-ink-soft">{msg}</span>}
      </div>
    </div>
  );
}

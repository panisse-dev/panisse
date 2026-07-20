"use client";

// Editor del menú: edita nombre, descripción, precios, foto, etiquetas y
// visibilidad de cada producto, y nombre/descripción de cada categoría.
// Los cambios quedan en Supabase y la carta pública los toma al instante.
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  isAuthError,
  staffMenuTree,
  staffUpdateProduct,
  staffUpdateSection,
  uploadImage,
  type AdminMenu,
  type AdminProduct,
  type AdminSection,
} from "@/lib/admin";
import { useStaff } from "@/components/admin/AdminShell";
import { formatCOP } from "@/lib/format";

interface PriceDraft {
  label: string;
  price: string;
  discounted: string;
}

interface Draft {
  name: string;
  description: string;
  image: string | null;
  hidePrice: boolean;
  isNew: boolean;
  veg: boolean;
  visible: boolean;
  prices: PriceDraft[];
}

function toDraft(p: AdminProduct): Draft {
  return {
    name: p.name,
    description: p.description,
    image: p.image,
    hidePrice: p.hidePrice,
    isNew: p.isNew,
    veg: p.veg,
    visible: p.visible,
    prices: p.prices.map((e) => ({
      label: e.label || "",
      price: String(e.price ?? ""),
      discounted: e.discounted != null ? String(e.discounted) : "",
    })),
  };
}

function Toggle({
  on,
  onChange,
  label,
}: {
  on: boolean;
  onChange: (v: boolean) => void;
  label?: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      aria-label={label}
      onClick={() => onChange(!on)}
      className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${
        on ? "bg-verde" : "bg-ink-faint/30"
      }`}
    >
      <span
        className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-all ${
          on ? "left-[22px]" : "left-0.5"
        }`}
      />
    </button>
  );
}

export default function MenuAdminPage() {
  const { code, logout } = useStaff();
  const [tree, setTree] = useState<AdminMenu[] | null>(null);
  const [menuSlug, setMenuSlug] = useState("");
  const [error, setError] = useState("");

  // Producto en edición
  const [editing, setEditing] = useState<AdminProduct | null>(null);
  const [draft, setDraft] = useState<Draft | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [formError, setFormError] = useState("");

  // Categoría en edición
  const [editingSection, setEditingSection] = useState<AdminSection | null>(null);
  const [secName, setSecName] = useState("");
  const [secDesc, setSecDesc] = useState("");

  const load = useCallback(async () => {
    try {
      const t = await staffMenuTree(code);
      setTree(t);
      setMenuSlug((cur) => cur || t[0]?.slug || "");
      setError("");
    } catch (e) {
      if (isAuthError(e)) logout();
      else setError("No se pudo cargar el menú. Revisa tu internet.");
    }
  }, [code, logout]);

  useEffect(() => {
    load();
  }, [load]);

  const menu = useMemo(
    () => tree?.find((m) => m.slug === menuSlug) ?? null,
    [tree, menuSlug],
  );

  // Reemplaza un producto en el árbol local (sin recargar todo)
  const patchLocal = (id: string, patch: Partial<AdminProduct>) => {
    setTree((prev) =>
      prev
        ? prev.map((m) => ({
            ...m,
            sections: m.sections.map((s) => ({
              ...s,
              products: s.products.map((p) => (p.id === id ? { ...p, ...patch } : p)),
              subsections: (s.subsections || []).map((ss) => ({
                ...ss,
                products: ss.products.map((p) => (p.id === id ? { ...p, ...patch } : p)),
              })),
            })),
          }))
        : prev,
    );
  };

  const patchLocalSection = (id: string, patch: Partial<AdminSection>) => {
    setTree((prev) =>
      prev
        ? prev.map((m) => ({
            ...m,
            sections: m.sections.map((s) =>
              s.id === id
                ? { ...s, ...patch }
                : {
                    ...s,
                    subsections: (s.subsections || []).map((ss) =>
                      ss.id === id ? { ...ss, ...patch } : ss,
                    ),
                  },
            ),
          }))
        : prev,
    );
  };

  const quickToggle = async (p: AdminProduct, visible: boolean) => {
    patchLocal(p.id, { visible });
    try {
      await staffUpdateProduct(code, p.id, { visible });
    } catch (e) {
      patchLocal(p.id, { visible: !visible });
      if (isAuthError(e)) logout();
    }
  };

  const openEditor = (p: AdminProduct) => {
    setEditing(p);
    setDraft(toDraft(p));
    setFormError("");
  };

  const closeEditor = () => {
    setEditing(null);
    setDraft(null);
  };

  const save = async () => {
    if (!editing || !draft || saving) return;
    setFormError("");
    const name = draft.name.trim();
    if (!name) {
      setFormError("El nombre no puede quedar vacío.");
      return;
    }
    const prices = draft.prices
      .map((e) => ({
        label: e.label.trim(),
        price: Math.round(Number(e.price) || 0),
        discounted: e.discounted.trim() === "" ? null : Math.round(Number(e.discounted) || 0),
      }))
      .filter((e) => e.price > 0);
    if (prices.length === 0 && !draft.hidePrice) {
      setFormError("Agrega al menos un precio o marca «Esconder precio».");
      return;
    }
    const patch = {
      name,
      description: draft.description.trim(),
      image: draft.image,
      prices,
      hidePrice: draft.hidePrice,
      isNew: draft.isNew,
      veg: draft.veg,
      visible: draft.visible,
    };
    setSaving(true);
    try {
      await staffUpdateProduct(code, editing.id, patch);
      patchLocal(editing.id, patch as Partial<AdminProduct>);
      closeEditor();
    } catch (e) {
      if (isAuthError(e)) logout();
      else setFormError(e instanceof Error ? e.message : "No se pudo guardar.");
    } finally {
      setSaving(false);
    }
  };

  const onPickImage = async (file: File | undefined) => {
    if (!file || !draft) return;
    setFormError("");
    setUploading(true);
    try {
      const url = await uploadImage(code, file);
      setDraft((d) => (d ? { ...d, image: url } : d));
    } catch (e) {
      setFormError(e instanceof Error ? e.message : "No se pudo subir la imagen.");
    } finally {
      setUploading(false);
    }
  };

  const openSection = (s: AdminSection) => {
    setEditingSection(s);
    setSecName(s.name);
    setSecDesc(s.description);
    setFormError("");
  };

  const saveSection = async () => {
    if (!editingSection || saving) return;
    const name = secName.trim();
    if (!name) {
      setFormError("El nombre no puede quedar vacío.");
      return;
    }
    setSaving(true);
    try {
      await staffUpdateSection(code, editingSection.id, {
        name,
        description: secDesc.trim(),
      });
      patchLocalSection(editingSection.id, { name, description: secDesc.trim() });
      setEditingSection(null);
    } catch (e) {
      if (isAuthError(e)) logout();
      else setFormError(e instanceof Error ? e.message : "No se pudo guardar.");
    } finally {
      setSaving(false);
    }
  };

  const priceSummary = (p: AdminProduct): string => {
    if (p.hidePrice || p.prices.length === 0) return "Sin precio";
    const first = p.prices[0];
    const val = first.discounted ?? first.price;
    return p.prices.length > 1 ? `${formatCOP(val)} +${p.prices.length - 1}` : formatCOP(val);
  };

  const ProductRow = ({ p }: { p: AdminProduct }) => (
    <li className={`flex items-center gap-3 py-2 ${p.visible ? "" : "opacity-50"}`}>
      <button
        type="button"
        onClick={() => openEditor(p)}
        className="flex min-w-0 flex-1 items-center gap-3 text-left"
      >
        {p.image ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={p.image}
            alt=""
            className="h-11 w-11 shrink-0 border border-gold-soft/50 object-cover"
          />
        ) : (
          <span className="flex h-11 w-11 shrink-0 items-center justify-center border border-gold-soft/40 bg-paper-deep text-[15px] text-ink-faint">
            🍽
          </span>
        )}
        <span className="min-w-0 flex-1">
          <span className="block truncate text-[13.5px] font-medium text-ink">
            {p.name}
            {p.isNew && <span className="ml-1.5 text-[10px] text-gold-deep">NUEVO</span>}
            {p.veg && <span className="ml-1 text-[10px] text-verde">VEG</span>}
          </span>
          <span className="block text-[11.5px] text-ink-faint">{priceSummary(p)}</span>
        </span>
        <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0 text-ink-faint" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
          <path d="m9 5 7 7-7 7" />
        </svg>
      </button>
      <Toggle on={p.visible} onChange={(v) => quickToggle(p, v)} label={`Visible: ${p.name}`} />
    </li>
  );

  const SectionBlock = ({ s, sub }: { s: AdminSection; sub?: boolean }) => (
    <section className={sub ? "mt-3 border-l-2 border-gold-soft/40 pl-3" : "mt-4 border border-gold-soft/50 bg-card px-4 py-3"}>
      <header className="flex items-center justify-between gap-2">
        <div className="min-w-0">
          <h3 className={`truncate font-display ${sub ? "text-[14px]" : "text-[16px]"} text-navy`}>
            {s.name}
          </h3>
          {s.description && (
            <p className="truncate text-[11.5px] italic text-ink-faint">{s.description}</p>
          )}
        </div>
        <button
          type="button"
          onClick={() => openSection(s)}
          aria-label={`Editar categoría ${s.name}`}
          className="flex h-8 w-8 shrink-0 items-center justify-center text-ink-faint active:bg-paper-deep"
        >
          <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
            <path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z" />
          </svg>
        </button>
      </header>
      {s.products.length > 0 && (
        <ul className="mt-1 divide-y divide-gold-soft/20">
          {s.products.map((p) => (
            <ProductRow key={p.id} p={p} />
          ))}
        </ul>
      )}
      {(s.subsections || []).map((ss) => (
        <SectionBlock key={ss.id} s={ss} sub />
      ))}
    </section>
  );

  return (
    <div className="mx-auto max-w-2xl">
      {error && <p className="mt-4 text-center text-[12.5px] text-[#b3261e]">{error}</p>}
      {!tree && !error && (
        <p className="mt-16 text-center text-[13px] text-ink-faint">Cargando menú…</p>
      )}

      {tree && (
        <>
          <div className="chips-scroll -mx-1 mt-3 flex gap-1.5 overflow-x-auto px-1">
            {tree.map((m) => (
              <button
                key={m.slug}
                type="button"
                onClick={() => setMenuSlug(m.slug)}
                className={`smallcaps h-9 shrink-0 whitespace-nowrap border px-4 text-[10.5px] font-medium ${
                  m.slug === menuSlug
                    ? "border-navy bg-navy text-gold-soft"
                    : "border-gold-soft/60 bg-card text-ink-soft"
                }`}
              >
                {m.label}
              </button>
            ))}
          </div>
          <p className="mt-2 text-[11px] text-ink-faint">
            Toca un producto para editarlo · el interruptor lo muestra u oculta en la carta.
          </p>

          {menu?.sections.map((s) => <SectionBlock key={s.id} s={s} />)}
        </>
      )}

      {/* ── Editor de producto ── */}
      {editing && draft && (
        <div className="fixed inset-0 z-50" role="dialog" aria-modal="true" aria-label={`Editar ${editing.name}`}>
          <button
            type="button"
            aria-label="Cerrar"
            onClick={closeEditor}
            className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]"
          />
          <div className="anim-sheet-up absolute inset-x-0 bottom-0 mx-auto max-w-md">
            <div className="max-h-[92dvh] overflow-y-auto rounded-t-3xl bg-card pb-[calc(env(safe-area-inset-bottom)+20px)] shadow-[0_-12px_40px_rgba(4,17,29,0.25)]">
              <div className="sticky top-0 z-10 flex items-center justify-between border-b border-gold-soft/40 bg-card px-5 pb-3 pt-4">
                <h3 className="font-display text-[18px] text-navy">Editar producto</h3>
                <button
                  type="button"
                  onClick={closeEditor}
                  aria-label="Cerrar"
                  className="flex h-8 w-8 items-center justify-center rounded-full text-ink-soft active:bg-paper-deep"
                >
                  <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
                    <path d="M6 6l12 12M18 6 6 18" />
                  </svg>
                </button>
              </div>

              <div className="px-5 pt-4">
                {/* Foto */}
                <div className="flex items-start gap-3">
                  {draft.image ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={draft.image}
                      alt=""
                      className="h-24 w-24 shrink-0 border border-gold-soft/60 object-cover"
                    />
                  ) : (
                    <span className="flex h-24 w-24 shrink-0 items-center justify-center border border-dashed border-gold-soft/70 bg-paper text-[24px] text-ink-faint">
                      🍽
                    </span>
                  )}
                  <div className="flex flex-col gap-2">
                    <label className="flex h-10 cursor-pointer items-center justify-center border border-navy px-4 text-[12.5px] font-medium text-navy active:bg-navy/5">
                      {uploading ? "Subiendo…" : draft.image ? "Cambiar foto" : "Subir foto"}
                      <input
                        type="file"
                        accept="image/*"
                        className="hidden"
                        disabled={uploading}
                        onChange={(e) => onPickImage(e.target.files?.[0])}
                      />
                    </label>
                    {draft.image && (
                      <button
                        type="button"
                        onClick={() => setDraft((d) => (d ? { ...d, image: null } : d))}
                        className="text-[11.5px] text-ink-faint underline"
                      >
                        Quitar foto
                      </button>
                    )}
                    <p className="text-[10.5px] text-ink-faint">Ideal 720×720, jpg/png/webp.</p>
                  </div>
                </div>

                {/* Nombre y descripción */}
                <label className="mt-4 block">
                  <span className="smallcaps text-[10px] text-gold-deep">Nombre</span>
                  <input
                    value={draft.name}
                    onChange={(e) => setDraft((d) => (d ? { ...d, name: e.target.value } : d))}
                    maxLength={80}
                    className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy"
                  />
                </label>
                <label className="mt-3 block">
                  <span className="smallcaps text-[10px] text-gold-deep">Descripción</span>
                  <textarea
                    value={draft.description}
                    onChange={(e) =>
                      setDraft((d) => (d ? { ...d, description: e.target.value } : d))
                    }
                    rows={3}
                    className="mt-1 w-full resize-none border border-gold-soft/70 bg-paper px-3 py-2.5 text-[14px] text-ink outline-none focus:border-navy"
                  />
                </label>

                {/* Precios */}
                <div className="mt-4">
                  <span className="smallcaps text-[10px] text-gold-deep">Precios</span>
                  {draft.prices.map((e, i) => (
                    <div key={i} className="mt-2 flex items-center gap-2">
                      <input
                        value={e.label}
                        onChange={(ev) =>
                          setDraft((d) => {
                            if (!d) return d;
                            const prices = d.prices.slice();
                            prices[i] = { ...prices[i], label: ev.target.value };
                            return { ...d, prices };
                          })
                        }
                        placeholder={draft.prices.length > 1 ? `Opción ${i + 1}` : "Etiqueta (opcional)"}
                        className="h-11 w-0 flex-1 border border-gold-soft/70 bg-paper px-2.5 text-[13px] text-ink outline-none focus:border-navy"
                      />
                      <input
                        value={e.price}
                        onChange={(ev) =>
                          setDraft((d) => {
                            if (!d) return d;
                            const prices = d.prices.slice();
                            prices[i] = { ...prices[i], price: ev.target.value.replace(/\D/g, "") };
                            return { ...d, prices };
                          })
                        }
                        placeholder="Precio"
                        inputMode="numeric"
                        className="h-11 w-24 border border-gold-soft/70 bg-paper px-2.5 text-right text-[13px] text-ink outline-none focus:border-navy"
                      />
                      <input
                        value={e.discounted}
                        onChange={(ev) =>
                          setDraft((d) => {
                            if (!d) return d;
                            const prices = d.prices.slice();
                            prices[i] = {
                              ...prices[i],
                              discounted: ev.target.value.replace(/\D/g, ""),
                            };
                            return { ...d, prices };
                          })
                        }
                        placeholder="Oferta"
                        inputMode="numeric"
                        className="h-11 w-20 border border-gold-soft/70 bg-paper px-2.5 text-right text-[13px] text-ink outline-none focus:border-navy"
                      />
                      <button
                        type="button"
                        aria-label="Quitar precio"
                        onClick={() =>
                          setDraft((d) =>
                            d ? { ...d, prices: d.prices.filter((_, j) => j !== i) } : d,
                          )
                        }
                        className="flex h-8 w-8 shrink-0 items-center justify-center text-ink-faint"
                      >
                        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
                          <path d="M6 6l12 12M18 6 6 18" />
                        </svg>
                      </button>
                    </div>
                  ))}
                  <button
                    type="button"
                    onClick={() =>
                      setDraft((d) =>
                        d
                          ? { ...d, prices: [...d.prices, { label: "", price: "", discounted: "" }] }
                          : d,
                      )
                    }
                    className="mt-2 flex items-center gap-1.5 text-[12px] font-medium text-gold-deep"
                  >
                    <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
                      <path d="M12 5v14M5 12h14" />
                    </svg>
                    Agregar precio (variante)
                  </button>
                </div>

                {/* Banderas */}
                <div className="mt-4 flex flex-col gap-2.5 border-t border-gold-soft/40 pt-3.5">
                  {(
                    [
                      ["visible", "Visible en la carta"],
                      ["isNew", "Marcar como «Nuevo»"],
                      ["veg", "Vegetariano"],
                      ["hidePrice", "Esconder precio (consultar en tienda)"],
                    ] as const
                  ).map(([key, label]) => (
                    <div key={key} className="flex items-center justify-between">
                      <span className="text-[13px] text-ink">{label}</span>
                      <Toggle
                        on={draft[key]}
                        onChange={(v) => setDraft((d) => (d ? { ...d, [key]: v } : d))}
                        label={label}
                      />
                    </div>
                  ))}
                </div>

                {formError && (
                  <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{formError}</p>
                )}

                <div className="mt-4 flex gap-2">
                  <button
                    type="button"
                    onClick={save}
                    disabled={saving || uploading}
                    className="h-12 flex-1 bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60"
                  >
                    {saving ? "Guardando…" : "Guardar cambios"}
                  </button>
                  <button
                    type="button"
                    onClick={closeEditor}
                    className="h-12 border border-gold-soft/70 px-5 text-[13px] text-ink-soft"
                  >
                    Cancelar
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── Editor de categoría ── */}
      {editingSection && (
        <div className="fixed inset-0 z-50" role="dialog" aria-modal="true" aria-label={`Editar ${editingSection.name}`}>
          <button
            type="button"
            aria-label="Cerrar"
            onClick={() => setEditingSection(null)}
            className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]"
          />
          <div className="anim-sheet-up absolute inset-x-0 bottom-0 mx-auto max-w-md">
            <div className="rounded-t-3xl bg-card px-5 pb-[calc(env(safe-area-inset-bottom)+20px)] pt-4 shadow-[0_-12px_40px_rgba(4,17,29,0.25)]">
              <h3 className="font-display text-[18px] text-navy">Editar categoría</h3>
              <label className="mt-3 block">
                <span className="smallcaps text-[10px] text-gold-deep">Nombre</span>
                <input
                  value={secName}
                  onChange={(e) => setSecName(e.target.value)}
                  maxLength={80}
                  className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy"
                />
              </label>
              <label className="mt-3 block">
                <span className="smallcaps text-[10px] text-gold-deep">Descripción</span>
                <textarea
                  value={secDesc}
                  onChange={(e) => setSecDesc(e.target.value)}
                  rows={2}
                  className="mt-1 w-full resize-none border border-gold-soft/70 bg-paper px-3 py-2.5 text-[14px] text-ink outline-none focus:border-navy"
                />
              </label>
              {formError && (
                <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{formError}</p>
              )}
              <div className="mt-4 flex gap-2">
                <button
                  type="button"
                  onClick={saveSection}
                  disabled={saving}
                  className="h-12 flex-1 bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60"
                >
                  {saving ? "Guardando…" : "Guardar"}
                </button>
                <button
                  type="button"
                  onClick={() => setEditingSection(null)}
                  className="h-12 border border-gold-soft/70 px-5 text-[13px] text-ink-soft"
                >
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

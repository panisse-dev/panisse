"use client";

// Clientes: base de datos con nombre, celular, correo y cumpleaños,
// más estadísticas de pedidos. Permite agregar, editar, borrar y exportar.
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  isAuthError,
  staffClients,
  staffDeleteClient,
  staffUpsertClient,
  type ClientRow,
} from "@/lib/admin";
import { useStaff } from "@/components/admin/AdminShell";
import { formatCOP, normalize } from "@/lib/format";

interface ClientForm {
  id?: string;
  name: string;
  phone: string;
  email: string;
  birthday: string;
  notes: string;
}

const EMPTY: ClientForm = { name: "", phone: "", email: "", birthday: "", notes: "" };

function fmtDate(iso: string | null): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("es-CO", {
    day: "2-digit",
    month: "short",
    year: "2-digit",
    timeZone: "America/Bogota",
  });
}

function fmtBirthday(b: string | null): string {
  if (!b) return "—";
  const [, m, d] = b.split("-");
  const months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
  return `${Number(d)} ${months[Number(m) - 1] ?? ""}`;
}

export default function ClientesPage() {
  const { code, logout } = useStaff();
  const [clients, setClients] = useState<ClientRow[] | null>(null);
  const [query, setQuery] = useState("");
  const [error, setError] = useState("");
  const [form, setForm] = useState<ClientForm | null>(null);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState("");

  const load = useCallback(async () => {
    try {
      setClients(await staffClients(code));
      setError("");
    } catch (e) {
      if (isAuthError(e)) logout();
      else setError("No se pudo cargar la lista. Revisa tu internet.");
    }
  }, [code, logout]);

  useEffect(() => {
    load();
  }, [load]);

  const filtered = useMemo(() => {
    if (!clients) return [];
    const q = normalize(query.trim());
    if (!q) return clients;
    return clients.filter((c) =>
      normalize(`${c.name} ${c.phone} ${c.email ?? ""}`).includes(q),
    );
  }, [clients, query]);

  const openNew = () => {
    setForm(EMPTY);
    setFormError("");
  };

  const openEdit = (c: ClientRow) => {
    setForm({
      id: c.id,
      name: c.name,
      phone: c.phone,
      email: c.email ?? "",
      birthday: c.birthday ?? "",
      notes: c.notes,
    });
    setFormError("");
  };

  const save = async () => {
    if (!form || saving) return;
    if (!form.name.trim()) {
      setFormError("Escribe el nombre.");
      return;
    }
    setSaving(true);
    try {
      await staffUpsertClient(code, {
        id: form.id,
        name: form.name.trim(),
        phone: form.phone.trim(),
        email: form.email.trim(),
        birthday: form.birthday || undefined,
        notes: form.notes.trim(),
      });
      setForm(null);
      await load();
    } catch (e) {
      if (isAuthError(e)) logout();
      else setFormError(e instanceof Error ? e.message : "No se pudo guardar.");
    } finally {
      setSaving(false);
    }
  };

  const remove = async (c: ClientRow) => {
    if (!window.confirm(`¿Eliminar a ${c.name}? Sus pedidos no se borran.`)) return;
    try {
      await staffDeleteClient(code, c.id);
      setClients((prev) => (prev ? prev.filter((x) => x.id !== c.id) : prev));
    } catch (e) {
      if (isAuthError(e)) logout();
      else setError("No se pudo eliminar.");
    }
  };

  const exportCsv = () => {
    if (!clients) return;
    const head = "Nombre,Celular,Email,Cumpleaños,Pedidos,Total,Registro,Última actividad,Notas";
    const rows = clients.map((c) =>
      [
        c.name,
        c.phone,
        c.email ?? "",
        c.birthday ?? "",
        c.ordersCount,
        c.totalSpent,
        fmtDate(c.createdAt),
        fmtDate(c.lastActivityAt),
        c.notes,
      ]
        .map((v) => `"${String(v).replace(/"/g, '""')}"`)
        .join(","),
    );
    const blob = new Blob(["﻿" + [head, ...rows].join("\n")], {
      type: "text/csv;charset=utf-8",
    });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "clientes-panisse.csv";
    a.click();
    URL.revokeObjectURL(a.href);
  };

  return (
    <div className="mx-auto max-w-5xl">
      <h1 className="mt-3 hidden font-display text-[20px] text-navy lg:block">Clientes</h1>
      <div className="mt-3 flex items-center gap-2">
        <div className="relative flex-1">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Buscar por nombre, celular o correo…"
            className="h-11 w-full border border-gold-soft/70 bg-card px-3.5 pr-9 text-[14px] text-ink outline-none focus:border-navy"
          />
          <svg viewBox="0 0 24 24" className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-faint" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
            <circle cx="11" cy="11" r="7" />
            <path d="m20 20-3.5-3.5" />
          </svg>
        </div>
        <button
          type="button"
          onClick={exportCsv}
          aria-label="Exportar CSV"
          className="flex h-11 w-11 shrink-0 items-center justify-center border border-gold-soft/70 bg-card text-ink-soft"
        >
          <svg viewBox="0 0 24 24" className="h-4.5 w-4.5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
            <path d="M12 3v12m0 0 4-4m-4 4-4-4M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" />
          </svg>
        </button>
        <button
          type="button"
          onClick={openNew}
          className="flex h-11 shrink-0 items-center gap-1.5 bg-navy px-4 text-[13px] font-semibold text-gold-soft"
        >
          <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
            <path d="M12 5v14M5 12h14" />
          </svg>
          Agregar
        </button>
      </div>

      <p className="mt-2 text-[11px] text-ink-faint">
        {clients ? (
          <>
            {filtered.length} de {clients.length} cliente{clients.length === 1 ? "" : "s"} · los
            pedidos con teléfono crean o actualizan clientes automáticamente
          </>
        ) : (
          "Cargando…"
        )}
        {error && <span className="text-[#b3261e]"> · {error}</span>}
      </p>

      {/* Tabla (desliza horizontal en el celular) */}
      {clients && filtered.length > 0 && (
        <div className="mt-3 overflow-x-auto border border-gold-soft/50 bg-card">
          <table className="w-full min-w-[720px] text-left text-[12.5px]">
            <thead>
              <tr className="smallcaps border-b border-gold-soft/40 text-[9.5px] text-gold-deep">
                <th className="px-3 py-2.5 font-medium">Nombre</th>
                <th className="px-3 py-2.5 font-medium">Celular</th>
                <th className="px-3 py-2.5 font-medium">Email</th>
                <th className="px-3 py-2.5 font-medium">Cumpleaños</th>
                <th className="px-3 py-2.5 text-right font-medium"># Pedidos</th>
                <th className="px-3 py-2.5 text-right font-medium">Total</th>
                <th className="px-3 py-2.5 font-medium">Últ. actividad</th>
                <th className="px-3 py-2.5 font-medium" aria-label="Acciones" />
              </tr>
            </thead>
            <tbody className="divide-y divide-gold-soft/20">
              {filtered.map((c) => (
                <tr key={c.id} className="text-ink">
                  <td className="px-3 py-2.5 font-medium">{c.name}</td>
                  <td className="px-3 py-2.5">
                    {c.phone ? (
                      <a href={`tel:${c.phone}`} className="text-gold-deep underline">
                        {c.phone}
                      </a>
                    ) : (
                      "—"
                    )}
                  </td>
                  <td className="max-w-[180px] truncate px-3 py-2.5">{c.email || "—"}</td>
                  <td className="px-3 py-2.5">{fmtBirthday(c.birthday)}</td>
                  <td className="px-3 py-2.5 text-right">{c.ordersCount}</td>
                  <td className="px-3 py-2.5 text-right">
                    {c.totalSpent > 0 ? formatCOP(c.totalSpent) : "—"}
                  </td>
                  <td className="px-3 py-2.5 text-ink-faint">{fmtDate(c.lastActivityAt)}</td>
                  <td className="px-3 py-2.5">
                    <div className="flex justify-end gap-1">
                      <button
                        type="button"
                        onClick={() => openEdit(c)}
                        aria-label={`Editar ${c.name}`}
                        className="flex h-8 w-8 items-center justify-center text-ink-faint active:bg-paper-deep"
                      >
                        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                          <path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z" />
                        </svg>
                      </button>
                      <button
                        type="button"
                        onClick={() => remove(c)}
                        aria-label={`Eliminar ${c.name}`}
                        className="flex h-8 w-8 items-center justify-center text-[#b3261e]/70 active:bg-paper-deep"
                      >
                        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                          <path d="M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2m3 0v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6" />
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {clients && filtered.length === 0 && (
        <p className="mt-16 text-center text-[13px] text-ink-faint">
          {query ? "Sin resultados para esa búsqueda." : "Aún no hay clientes registrados."}
        </p>
      )}

      {/* ── Formulario ── */}
      {form && (
        <div className="fixed inset-0 z-50 flex flex-col justify-end lg:items-center lg:justify-center lg:p-6" role="dialog" aria-modal="true" aria-label="Datos del cliente">
          <button
            type="button"
            aria-label="Cerrar"
            onClick={() => setForm(null)}
            className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]"
          />
          <div className="anim-sheet-up relative mx-auto w-full max-w-md">
            <div className="max-h-[92dvh] overflow-y-auto rounded-t-3xl bg-card px-5 pb-[calc(env(safe-area-inset-bottom)+20px)] pt-4 shadow-[0_-12px_40px_rgba(4,17,29,0.25)] lg:max-h-[85vh] lg:rounded-2xl lg:pb-6">
              <h3 className="font-display text-[18px] text-navy">
                {form.id ? "Editar cliente" : "Nuevo cliente"}
              </h3>
              <label className="mt-3 block">
                <span className="smallcaps text-[10px] text-gold-deep">Nombre *</span>
                <input
                  value={form.name}
                  onChange={(e) => setForm((f) => (f ? { ...f, name: e.target.value } : f))}
                  className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy"
                  autoFocus={!form.id}
                />
              </label>
              <label className="mt-3 block">
                <span className="smallcaps text-[10px] text-gold-deep">Celular</span>
                <input
                  value={form.phone}
                  onChange={(e) => setForm((f) => (f ? { ...f, phone: e.target.value } : f))}
                  inputMode="tel"
                  placeholder="+57 300 123 4567"
                  className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy"
                />
              </label>
              <label className="mt-3 block">
                <span className="smallcaps text-[10px] text-gold-deep">Correo</span>
                <input
                  value={form.email}
                  onChange={(e) => setForm((f) => (f ? { ...f, email: e.target.value } : f))}
                  inputMode="email"
                  placeholder="cliente@correo.com"
                  className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy"
                />
              </label>
              <label className="mt-3 block">
                <span className="smallcaps text-[10px] text-gold-deep">Cumpleaños</span>
                <input
                  type="date"
                  value={form.birthday}
                  onChange={(e) => setForm((f) => (f ? { ...f, birthday: e.target.value } : f))}
                  className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy"
                />
              </label>
              <label className="mt-3 block">
                <span className="smallcaps text-[10px] text-gold-deep">Notas</span>
                <textarea
                  value={form.notes}
                  onChange={(e) => setForm((f) => (f ? { ...f, notes: e.target.value } : f))}
                  rows={2}
                  placeholder="Ej. alérgico al maní, cliente frecuente…"
                  className="mt-1 w-full resize-none border border-gold-soft/70 bg-paper px-3 py-2.5 text-[14px] text-ink outline-none focus:border-navy"
                />
              </label>
              {formError && (
                <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{formError}</p>
              )}
              <div className="mt-4 flex gap-2">
                <button
                  type="button"
                  onClick={save}
                  disabled={saving}
                  className="h-12 flex-1 bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60"
                >
                  {saving ? "Guardando…" : "Guardar"}
                </button>
                <button
                  type="button"
                  onClick={() => setForm(null)}
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

"use client";

// Panel de reservas: lista del día con acciones (confirmar, cancelar, no
// llegó, cumplida) + ajustes de configuración (aforo, horario, días, abono).
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { formatCOP } from "@/lib/format";
import {
  isAuthError,
  staffAddReservationBlock,
  staffAssignTable,
  staffContext,
  staffCreateReservation,
  staffDeleteTable,
  staffDeleteZone,
  staffFloor,
  staffMoveTable,
  staffRemoveReservationBlock,
  staffSaveTable,
  staffSaveZone,
  staffReservationBlocks,
  staffReservations,
  staffReservationSettings,
  staffReservationStats,
  staffReservationsUpcoming,
  staffSetReservationDeposit,
  staffSetReservationNote,
  staffSetReservationSource,
  staffSetReservationStatus,
  staffUpdateReservationSettings,
  staffWalkin,
  SOURCE_LABEL,
  type Floor,
  type FloorTable,
  type Reservation,
  type ReservationBlock,
  type ReservationDay,
  type ReservationSettings,
  type ReservationSource,
  type ReservationStats,
  type ReservationStatusAdmin,
  type StaffContext,
} from "@/lib/admin";
import { useStaff } from "@/components/admin/AdminShell";

const POLL_MS = 20000;

const STATUS_LABEL: Record<ReservationStatusAdmin, string> = {
  pendiente: "Pendiente",
  confirmada: "Confirmada",
  cancelada: "Cancelada",
  cumplida: "Cumplida",
  no_show: "No llegó",
};
const STATUS_STYLE: Record<ReservationStatusAdmin, string> = {
  pendiente: "bg-gold text-navy",
  confirmada: "bg-verde text-white",
  cancelada: "bg-ink-faint/25 text-ink-soft",
  cumplida: "bg-navy text-gold-soft",
  no_show: "bg-[#b3261e] text-white",
};

const DOW = [
  { iso: 1, label: "Lun" },
  { iso: 2, label: "Mar" },
  { iso: 3, label: "Mié" },
  { iso: 4, label: "Jue" },
  { iso: 5, label: "Vie" },
  { iso: 6, label: "Sáb" },
  { iso: 7, label: "Dom" },
];

function todayBogota(): string {
  return new Date().toLocaleDateString("en-CA", { timeZone: "America/Bogota" });
}

function fmtTime(hhmm: string): string {
  const [h, m] = hhmm.split(":").map(Number);
  const p = h < 12 ? "am" : "pm";
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return `${h12}:${m.toString().padStart(2, "0")} ${p}`;
}

function fmtDay(iso: string): string {
  const [y, m, d] = iso.split("-").map(Number);
  const dt = new Date(y, m - 1, d);
  const dow = ["dom", "lun", "mar", "mié", "jue", "vie", "sáb"][dt.getDay()];
  const meses = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
  return `${dow} ${d} ${meses[m - 1]}`;
}

// Teléfono a formato WhatsApp (móvil colombiano).
function waLink(phone: string, msg: string): string | null {
  let d = (phone || "").replace(/\D/g, "");
  if (d.startsWith("00")) d = d.slice(2);
  if (d.length === 10 && d.startsWith("3")) d = "57" + d;
  if (!d) return null;
  return `https://wa.me/${d}?text=${encodeURIComponent(msg)}`;
}

export default function ReservasPage() {
  const { code, logout } = useStaff();
  const [day, setDay] = useState(todayBogota());
  const [list, setList] = useState<Reservation[]>([]);
  const [upcoming, setUpcoming] = useState<ReservationDay[]>([]);
  const [floor, setFloor] = useState<Floor | null>(null);
  const [connError, setConnError] = useState(false);
  const [noteEditId, setNoteEditId] = useState<string | null>(null);
  const [noteDraft, setNoteDraft] = useState("");
  const [showSettings, setShowSettings] = useState(false);
  const [showStats, setShowStats] = useState(false);
  const [showFloor, setShowFloor] = useState(false);
  const [walkinOpen, setWalkinOpen] = useState(false);
  const [walkinTable, setWalkinTable] = useState<string | null>(null);
  const [nuevaOpen, setNuevaOpen] = useState(false);

  const poll = useCallback(async () => {
    try {
      const [l, u, f] = await Promise.all([
        staffReservations(code, day),
        staffReservationsUpcoming(code),
        staffFloor(code, day),
      ]);
      setConnError(false);
      setList(l);
      setUpcoming(u);
      setFloor(f);
    } catch (e) {
      if (isAuthError(e)) logout();
      else setConnError(true);
    }
  }, [code, day, logout]);

  // Lista plana de mesas (con su zona) para los selectores de asignación.
  const tables = useMemo(
    () =>
      (floor?.zones ?? []).flatMap((z) =>
        z.tables.map((t) => ({ id: t.id, label: `${z.name} · ${t.name}`, seats: t.seats })),
      ),
    [floor],
  );

  const setSource = async (r: Reservation, source: ReservationSource) => {
    setList((prev) => prev.map((x) => (x.id === r.id ? { ...x, source } : x)));
    try {
      await staffSetReservationSource(code, r.id, source);
    } catch (e) {
      if (isAuthError(e)) logout();
      else poll();
    }
  };

  const assignTable = async (r: Reservation, tableId: string | null) => {
    setList((prev) =>
      prev.map((x) =>
        x.id === r.id
          ? { ...x, tableId, tableName: tables.find((t) => t.id === tableId)?.label.split(" · ")[1] ?? null }
          : x,
      ),
    );
    try {
      await staffAssignTable(code, r.id, tableId);
      poll();
    } catch (e) {
      if (isAuthError(e)) logout();
      else poll();
    }
  };

  useEffect(() => {
    poll();
    const iv = setInterval(() => {
      if (!document.hidden) poll();
    }, POLL_MS);
    return () => clearInterval(iv);
  }, [poll]);

  const setStatus = async (r: Reservation, status: ReservationStatusAdmin) => {
    setList((prev) => prev.map((x) => (x.id === r.id ? { ...x, status } : x)));
    try {
      await staffSetReservationStatus(code, r.id, status);
      poll();
    } catch (e) {
      if (isAuthError(e)) logout();
      else poll();
    }
  };

  const toggleDeposit = async (r: Reservation) => {
    const paid = !r.depositPaid;
    setList((prev) => prev.map((x) => (x.id === r.id ? { ...x, depositPaid: paid } : x)));
    try {
      await staffSetReservationDeposit(code, r.id, paid);
    } catch (e) {
      if (isAuthError(e)) logout();
      else poll();
    }
  };

  const saveNote = async (r: Reservation) => {
    const note = noteDraft.trim();
    setNoteEditId(null);
    setList((prev) => prev.map((x) => (x.id === r.id ? { ...x, staffNote: note } : x)));
    try {
      await staffSetReservationNote(code, r.id, note);
    } catch (e) {
      if (isAuthError(e)) logout();
      else poll();
    }
  };

  const active = list.filter((r) => r.status !== "cancelada");
  const totalPeople = active
    .filter((r) => r.status !== "no_show")
    .reduce((s, r) => s + r.party, 0);

  return (
    <div>
      <div className="mt-3 flex flex-wrap items-center justify-between gap-2 lg:mt-0">
        <div className="flex items-center gap-1.5">
          <h1 className="mr-2 hidden font-display text-[20px] text-navy lg:block">Reservas</h1>
          <button
            type="button"
            onClick={() => setDay(todayBogota())}
            className={`smallcaps h-9 border px-3.5 text-[10.5px] font-medium ${
              day === todayBogota() ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/60 bg-card text-ink-soft"
            }`}
          >
            Hoy
          </button>
          <input
            type="date"
            value={day}
            onChange={(e) => setDay(e.target.value || todayBogota())}
            aria-label="Ver reservas de un día"
            className="h-9 border border-gold-soft/60 bg-card px-2 text-[12.5px] text-ink-soft outline-none"
          />
        </div>
        <div className="flex flex-wrap items-center justify-end gap-1.5">
          <button
            type="button"
            onClick={() => setNuevaOpen(true)}
            className="smallcaps flex h-9 shrink-0 items-center whitespace-nowrap rounded-full bg-navy px-3.5 text-[10.5px] font-semibold text-gold-soft"
          >
            + Reserva
          </button>
          <button
            type="button"
            onClick={() => setWalkinOpen(true)}
            className="smallcaps flex h-9 shrink-0 items-center whitespace-nowrap rounded-full bg-verde px-3.5 text-[10.5px] font-semibold text-white"
          >
            + Walk-In
          </button>
          <button
            type="button"
            onClick={() => {
              setShowFloor((s) => !s);
              setShowStats(false);
              setShowSettings(false);
            }}
            className={`smallcaps flex h-9 shrink-0 items-center whitespace-nowrap rounded-full border px-3 text-[10.5px] font-medium ${
              showFloor ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/60 text-ink-soft"
            }`}
          >
            Plano
          </button>
          <button
            type="button"
            onClick={() => {
              setShowStats((s) => !s);
              setShowSettings(false);
              setShowFloor(false);
            }}
            className={`smallcaps flex h-9 shrink-0 items-center whitespace-nowrap rounded-full border px-3 text-[10.5px] font-medium ${
              showStats ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/60 text-ink-soft"
            }`}
          >
            Estadísticas
          </button>
          <button
            type="button"
            onClick={() => {
              setShowSettings((s) => !s);
              setShowStats(false);
              setShowFloor(false);
            }}
            className={`smallcaps flex h-9 shrink-0 items-center whitespace-nowrap rounded-full border px-3 text-[10.5px] font-medium ${
              showSettings ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/60 text-ink-soft"
            }`}
          >
            Ajustes
          </button>
        </div>
      </div>

      {showFloor && (
        <FloorPanel
          floor={floor}
          code={code}
          onChanged={poll}
          onAuth={logout}
          onPickTable={(tableId) => {
            setWalkinTable(tableId);
            setWalkinOpen(true);
          }}
        />
      )}
      {showStats && <StatsPanel code={code} onAuth={logout} />}

      {walkinOpen && (
        <WalkinModal
          code={code}
          tables={tables}
          initialTable={walkinTable}
          onClose={() => {
            setWalkinOpen(false);
            setWalkinTable(null);
          }}
          onDone={() => {
            setWalkinOpen(false);
            setWalkinTable(null);
            poll();
          }}
          onAuth={logout}
        />
      )}

      {nuevaOpen && (
        <NuevaReservaModal
          code={code}
          tables={tables}
          defaultDay={day}
          onClose={() => setNuevaOpen(false)}
          onDone={() => {
            setNuevaOpen(false);
            poll();
          }}
          onAuth={logout}
        />
      )}

      {/* Próximos días con reservas */}
      {upcoming.length > 0 && (
        <div className="chips-scroll -mx-1 mt-3 flex gap-1.5 overflow-x-auto px-1 pb-1">
          {upcoming.map((u) => (
            <button
              key={u.day}
              type="button"
              onClick={() => setDay(u.day)}
              className={`flex shrink-0 items-center gap-2 border px-3 py-1.5 text-[12px] ${
                day === u.day ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/60 bg-card text-ink-soft"
              }`}
            >
              <span>{fmtDay(u.day)}</span>
              <span className={`rounded-full px-1.5 text-[10px] font-semibold ${day === u.day ? "bg-gold-soft text-navy" : "bg-navy/10 text-navy"}`}>
                {u.total}
              </span>
              {u.pendientes > 0 && (
                <span className="rounded-full bg-gold px-1.5 text-[10px] font-semibold text-navy">
                  {u.pendientes} pend
                </span>
              )}
            </button>
          ))}
        </div>
      )}

      <p className="mt-3 text-[11px] text-ink-faint">
        {fmtDay(day)} · {active.length} reserva{active.length === 1 ? "" : "s"} · {totalPeople} personas
        {connError && <span className="text-[#b3261e]"> · sin conexión</span>}
      </p>

      {showSettings && <SettingsPanel code={code} onSaved={poll} />}

      {/* Lista de reservas */}
      {list.length === 0 ? (
        <p className="mt-16 text-center text-[13px] text-ink-faint">
          No hay reservas para este día.
        </p>
      ) : (
        <div className="mx-auto mt-4 flex max-w-2xl flex-col gap-3">
          {list.map((r) => {
            const wa = waLink(
              r.customer.phone,
              `¡Hola ${r.customer.name.split(" ")[0] || ""}! Sobre tu reserva en PANISSE para ${r.party} el ${fmtDay(r.date)} a las ${fmtTime(r.time)}.`,
            );
            return (
              <div key={r.id} className="border border-gold-soft/50 bg-card shadow-[0_1px_8px_rgba(4,27,49,0.06)]">
                <div className="flex items-start justify-between gap-3 px-4 pt-3.5">
                  <div className="min-w-0">
                    <p className="font-display text-[22px] leading-none text-navy">{fmtTime(r.time)}</p>
                    <p className="mt-1 text-[13px] font-medium text-ink">
                      {r.customer.name} · {r.party} {r.party === 1 ? "persona" : "personas"}
                    </p>
                    {r.customer.phone && (
                      <a href={`tel:${r.customer.phone}`} className="text-[12px] text-gold-deep underline">
                        {r.customer.phone}
                      </a>
                    )}
                    {r.customer.email && (
                      <p className="text-[11.5px] text-ink-faint">{r.customer.email}</p>
                    )}
                  </div>
                  <div className="flex shrink-0 flex-col items-end gap-1">
                    <span className={`smallcaps inline-block px-2 py-1 text-[10px] font-semibold ${STATUS_STYLE[r.status]}`}>
                      {STATUS_LABEL[r.status]}
                    </span>
                    {r.isWalkIn ? (
                      <span className="smallcaps inline-block bg-verde/15 px-2 py-0.5 text-[9px] font-semibold text-verde">
                        Walk-In
                      </span>
                    ) : (
                      <select
                        value={r.source === "walkin" ? "otro" : r.source}
                        onChange={(e) => setSource(r, e.target.value as ReservationSource)}
                        aria-label="Origen de la reserva"
                        className="smallcaps h-6 border border-gold-soft/60 bg-card px-1 text-[9px] font-medium text-ink-soft outline-none"
                      >
                        <option value="web">Página web</option>
                        <option value="telefono">Teléfono</option>
                        <option value="google">Google</option>
                        <option value="otro">Otro</option>
                      </select>
                    )}
                  </div>
                </div>

                {/* Mesa asignada */}
                <div className="mx-4 mt-2 flex items-center gap-2">
                  <span className="smallcaps text-[9px] text-gold-deep">Mesa</span>
                  <select
                    value={r.tableId ?? ""}
                    onChange={(e) => assignTable(r, e.target.value || null)}
                    className={`h-8 flex-1 border px-2 text-[12.5px] outline-none focus:border-navy ${
                      r.tableId ? "border-navy/40 bg-navy/[0.03] text-navy" : "border-gold-soft/60 bg-card text-ink-faint"
                    }`}
                  >
                    <option value="">Sin asignar</option>
                    {tables.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.label} ({t.seats})
                      </option>
                    ))}
                  </select>
                </div>

                {r.note && (
                  <p className="mx-4 mt-2 border-l-2 border-gold px-2.5 py-1 text-[12.5px] italic text-ink-soft">
                    <span className="smallcaps mr-1 text-[9px] not-italic text-gold-deep">Cliente:</span>
                    “{r.note}”
                  </p>
                )}

                {r.depositRequired > 0 && (
                  <div className="mx-4 mt-2 flex items-center justify-between gap-2 border border-gold-soft/50 bg-paper px-3 py-2">
                    <span className="text-[12px] text-ink-soft">
                      Abono {formatCOP(r.depositRequired)}
                    </span>
                    <button
                      type="button"
                      onClick={() => toggleDeposit(r)}
                      className={`smallcaps px-2 py-1 text-[10px] font-semibold ${r.depositPaid ? "bg-verde text-white" : "border border-gold-soft/70 text-ink-soft"}`}
                    >
                      {r.depositPaid ? "Abono pagado ✓" : "Marcar pagado"}
                    </button>
                  </div>
                )}

                {/* Nota interna */}
                <div className="px-4 py-2">
                  {noteEditId === r.id ? (
                    <div>
                      <textarea
                        value={noteDraft}
                        onChange={(e) => setNoteDraft(e.target.value)}
                        rows={2}
                        autoFocus
                        placeholder="Nota interna (ej. mesa junto a la ventana, cliente VIP…)"
                        className="w-full resize-none border border-gold-soft/70 bg-paper px-2.5 py-2 text-[13px] text-ink outline-none focus:border-navy"
                      />
                      <div className="mt-1.5 flex gap-2">
                        <button type="button" onClick={() => saveNote(r)} className="h-9 flex-1 bg-navy text-[12.5px] font-semibold text-gold-soft">
                          Guardar nota
                        </button>
                        <button type="button" onClick={() => setNoteEditId(null)} className="h-9 border border-gold-soft/60 px-4 text-[12.5px] text-ink-soft">
                          Cancelar
                        </button>
                      </div>
                    </div>
                  ) : r.staffNote ? (
                    <button type="button" onClick={() => { setNoteEditId(r.id); setNoteDraft(r.staffNote); }} className="flex w-full items-start gap-2 border-l-2 border-navy bg-navy/[0.03] px-2.5 py-1.5 text-left">
                      <span className="flex-1 text-[12.5px] text-navy">{r.staffNote}</span>
                      <span className="smallcaps shrink-0 text-[9px] text-gold-deep">Editar</span>
                    </button>
                  ) : (
                    <button type="button" onClick={() => { setNoteEditId(r.id); setNoteDraft(""); }} className="text-[12px] font-medium text-gold-deep">
                      + Agregar nota interna
                    </button>
                  )}
                </div>

                {wa && (
                  <a href={wa} target="_blank" rel="noopener noreferrer" className="flex h-11 w-full items-center justify-center gap-2 border-t border-gold-soft/25 bg-verde/10 text-[13.5px] font-semibold text-verde hover:bg-verde/15">
                    Escribir por WhatsApp
                  </a>
                )}

                {/* Acciones según estado */}
                <div className="flex flex-wrap gap-px border-t border-gold-soft/25 bg-gold-soft/25">
                  {r.status === "pendiente" && (
                    <ActionBtn primary onClick={() => setStatus(r, "confirmada")}>Confirmar</ActionBtn>
                  )}
                  {r.status === "confirmada" && (
                    <ActionBtn primary onClick={() => setStatus(r, "cumplida")}>Marcar cumplida</ActionBtn>
                  )}
                  {(r.status === "pendiente" || r.status === "confirmada") && (
                    <>
                      <ActionBtn onClick={() => setStatus(r, "no_show")}>No llegó</ActionBtn>
                      <ActionBtn onClick={() => setStatus(r, "cancelada")}>Cancelar</ActionBtn>
                    </>
                  )}
                  {(r.status === "cancelada" || r.status === "no_show" || r.status === "cumplida") && (
                    <ActionBtn onClick={() => setStatus(r, "pendiente")}>Reabrir</ActionBtn>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function ActionBtn({
  children,
  onClick,
  primary,
}: {
  children: React.ReactNode;
  onClick: () => void;
  primary?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`h-11 flex-1 whitespace-nowrap px-3 text-[13px] font-semibold ${
        primary ? "bg-navy text-gold-soft" : "bg-card text-ink-soft hover:bg-paper-deep"
      }`}
    >
      {children}
    </button>
  );
}

// ── Ajustes de reservas ──
function SettingsPanel({ code, onSaved }: { code: string; onSaved: () => void }) {
  const [s, setS] = useState<ReservationSettings | null>(null);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    staffReservationSettings(code).then(setS).catch(() => setMsg("No se pudo cargar."));
  }, [code]);

  const set = <K extends keyof ReservationSettings>(k: K, v: ReservationSettings[K]) =>
    setS((prev) => (prev ? { ...prev, [k]: v } : prev));

  const toggleDay = (iso: number) =>
    setS((prev) =>
      prev
        ? {
            ...prev,
            openDays: prev.openDays.includes(iso)
              ? prev.openDays.filter((d) => d !== iso)
              : [...prev.openDays, iso].sort(),
          }
        : prev,
    );

  const save = async () => {
    if (!s) return;
    setSaving(true);
    setMsg("");
    try {
      await staffUpdateReservationSettings(code, s);
      setMsg("Guardado ✓");
      onSaved();
    } catch {
      setMsg("No se pudo guardar.");
    } finally {
      setSaving(false);
    }
  };

  if (!s) return <p className="mt-3 text-[12px] text-ink-faint">{msg || "Cargando ajustes…"}</p>;

  const numField = (
    label: string,
    k: keyof ReservationSettings,
    hint?: string,
    suffix?: string,
  ) => (
    <label className="block">
      <span className="smallcaps text-[10px] text-gold-deep">{label}</span>
      <div className="mt-1 flex items-center gap-2">
        <input
          type="number"
          value={s[k] as number}
          onChange={(e) => set(k, Number(e.target.value) as never)}
          className="h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy"
        />
        {suffix && <span className="shrink-0 text-[12px] text-ink-faint">{suffix}</span>}
      </div>
      {hint && <span className="mt-1 block text-[10.5px] text-ink-faint">{hint}</span>}
    </label>
  );

  return (
    <div className="mt-4 border border-gold-soft/60 bg-paper p-4">
      <div className="flex items-center justify-between">
        <h2 className="font-display text-[16px] text-navy">Ajustes de reservas</h2>
        <label className="flex items-center gap-2 text-[12px] text-ink-soft">
          <input type="checkbox" checked={s.enabled} onChange={(e) => set("enabled", e.target.checked)} className="h-4 w-4 accent-[#04111D]" />
          Reservas activas
        </label>
      </div>

      <div className="mt-3">
        <span className="smallcaps text-[10px] text-gold-deep">Días abiertos</span>
        <div className="mt-1.5 flex flex-wrap gap-1.5">
          {DOW.map((d) => (
            <button
              key={d.iso}
              type="button"
              onClick={() => toggleDay(d.iso)}
              className={`h-9 w-12 border text-[12px] ${s.openDays.includes(d.iso) ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-card text-ink-soft"}`}
            >
              {d.label}
            </button>
          ))}
        </div>
      </div>

      <div className="mt-4 grid grid-cols-2 gap-3">
        <label className="block">
          <span className="smallcaps text-[10px] text-gold-deep">Abre a las</span>
          <input type="time" value={s.startTime} onChange={(e) => set("startTime", e.target.value)} className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy" />
        </label>
        <label className="block">
          <span className="smallcaps text-[10px] text-gold-deep">Última reserva</span>
          <input type="time" value={s.endTime} onChange={(e) => set("endTime", e.target.value)} className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy" />
        </label>
        {numField("Capacidad (aforo)", "capacity", "Personas que caben a la vez", "pers.")}
        {numField("Duración de mesa", "turnMinutes", "Cuánto ocupa una reserva", "min")}
        {numField("Cada cuánto una hora", "slotMinutes", "", "min")}
        {numField("Máx. personas en línea", "maxParty")}
        {numField("Días de anticipación", "advanceDays", "", "días")}
        {numField("Mínimo de anticipación", "minHours", "", "horas")}
      </div>

      <div className="mt-3">
        {numField("Abono por persona", "depositPerPerson", "0 = sin abono. Se cobra al confirmar (pendiente de pasarela).", "COP")}
      </div>

      <label className="mt-4 flex items-start gap-2.5 border-t border-gold-soft/40 pt-4">
        <input
          type="checkbox"
          checked={s.allowTableChoice}
          onChange={(e) => set("allowTableChoice", e.target.checked)}
          className="mt-0.5 h-4 w-4 shrink-0 accent-[#04111D]"
        />
        <span>
          <span className="text-[13.5px] font-medium text-navy">Dejar que el cliente escoja su mesa</span>
          <span className="mt-0.5 block text-[11px] text-ink-faint">
            Si lo apagas, el cliente reserva sin ver el mapa y tú le asignas la mesa.
          </span>
        </span>
      </label>

      <div className="mt-4 flex items-center gap-3">
        <button type="button" onClick={save} disabled={saving} className="h-11 flex-1 bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60">
          {saving ? "Guardando…" : "Guardar ajustes"}
        </button>
        {msg && <span className="text-[12px] text-ink-soft">{msg}</span>}
      </div>

      <BlocksPanel code={code} />
    </div>
  );
}

// ══ Estadísticas de reservas ══
const STATS_RANGES = [
  { key: "30d", label: "30 días", days: 30 },
  { key: "90d", label: "90 días", days: 90 },
  { key: "12m", label: "12 meses", days: 365 },
];

function bogotaTodayIso(): string {
  return new Date().toLocaleDateString("en-CA", { timeZone: "America/Bogota" });
}
function shiftIso(iso: string, days: number): string {
  const [y, m, d] = iso.split("-").map(Number);
  const dt = new Date(y, m - 1, d - days);
  return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
}

// Gráfica de barras vertical (SVG puro), con resaltado al pasar el dedo/mouse.
function MiniBars({
  values,
  labels,
  labelEvery = 1,
  height = 120,
}: {
  values: number[];
  labels: string[];
  labelEvery?: number;
  height?: number;
}) {
  const max = Math.max(1, ...values);
  const n = values.length || 1;
  const W = 100;
  const gap = n > 40 ? 0.4 : 1;
  const bw = (W - gap * (n - 1)) / n;
  const H = 100;
  const [hover, setHover] = useState<number | null>(null);
  return (
    <div>
      <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" style={{ height }} className="block w-full" role="img" aria-label="Gráfica de barras">
        {values.map((v, i) => {
          const h = (v / max) * (H - 4);
          return (
            <rect
              key={i}
              x={i * (bw + gap)}
              y={H - h}
              width={bw}
              height={h}
              rx={0.6}
              className={hover === i ? "fill-gold-deep" : "fill-navy/80"}
              onMouseEnter={() => setHover(i)}
              onMouseLeave={() => setHover(null)}
            />
          );
        })}
      </svg>
      <div className="mt-1 flex justify-between text-[9px] text-ink-faint">
        {labels.map((l, i) =>
          i % labelEvery === 0 ? (
            <span key={i} className="flex-1 text-center">{l}</span>
          ) : (
            <span key={i} className="flex-1" />
          ),
        )}
      </div>
      <p className="mt-1 text-center text-[10.5px] text-ink-soft">
        {hover != null ? `${labels[hover]}: ${values[hover]}` : `Máximo: ${values.every((v) => v === 0) ? 0 : max}`}
      </p>
    </div>
  );
}

function StatCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="border border-gold-soft/50 bg-card px-4 py-3.5">
      <h3 className="smallcaps mb-3 text-[10px] font-semibold text-gold-deep">{title}</h3>
      {children}
    </section>
  );
}

const MONTHS_SHORT = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
function monthLabel(ym: string): string {
  const [, m] = ym.split("-").map(Number);
  return MONTHS_SHORT[m - 1] ?? ym;
}

function StatsPanel({ code, onAuth }: { code: string; onAuth: () => void }) {
  const [range, setRange] = useState("30d");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [data, setData] = useState<ReservationStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const custom = Boolean(from && to);

  const load = useCallback(async () => {
    let f: string, t: string;
    if (from && to) {
      f = from <= to ? from : to;
      t = from <= to ? to : from;
    } else {
      const days = STATS_RANGES.find((r) => r.key === range)?.days ?? 30;
      t = bogotaTodayIso();
      f = shiftIso(t, days - 1);
    }
    setLoading(true);
    try {
      setData(await staffReservationStats(code, f, t));
      setError("");
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setError("No se pudieron cargar las estadísticas.");
    } finally {
      setLoading(false);
    }
  }, [code, range, from, to, onAuth]);

  useEffect(() => {
    load();
  }, [load]);

  const k = data?.kpis;
  const useMonths = !custom && range === "12m";
  const series = useMonths ? data?.byMonth ?? [] : data?.byDay ?? [];
  const meals = data
    ? [
        { key: "Desayuno", value: data.byMeal.desayuno },
        { key: "Almuerzo", value: data.byMeal.almuerzo },
        { key: "Cena", value: data.byMeal.cena },
      ]
    : [];
  const mealMax = Math.max(1, ...meals.map((m) => m.value));
  const originMax = Math.max(1, ...(data?.byOrigin ?? []).map((o) => o.count));

  return (
    <div className="mt-4 border border-gold-soft/60 bg-paper p-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="font-display text-[16px] text-navy">Estadísticas de reservas</h2>
        <div className="flex gap-1.5">
          {STATS_RANGES.map((r) => (
            <button
              key={r.key}
              type="button"
              onClick={() => {
                setRange(r.key);
                setFrom("");
                setTo("");
              }}
              className={`smallcaps h-8 border px-2.5 text-[10px] font-medium ${!custom && r.key === range ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/60 bg-card text-ink-soft"}`}
            >
              {r.label}
            </button>
          ))}
        </div>
      </div>

      {/* Filtro por fechas (de inicio a fin) */}
      <div className="mt-2 flex flex-wrap items-end gap-2">
        <label className="block">
          <span className="smallcaps text-[9px] text-gold-deep">Inicio</span>
          <input
            type="date"
            value={from}
            max={to || undefined}
            onChange={(e) => setFrom(e.target.value)}
            className="mt-0.5 block h-9 border border-gold-soft/60 bg-card px-2 text-[12px] text-ink outline-none focus:border-navy"
          />
        </label>
        <label className="block">
          <span className="smallcaps text-[9px] text-gold-deep">Fin</span>
          <input
            type="date"
            value={to}
            min={from || undefined}
            onChange={(e) => setTo(e.target.value)}
            className="mt-0.5 block h-9 border border-gold-soft/60 bg-card px-2 text-[12px] text-ink outline-none focus:border-navy"
          />
        </label>
        {custom && (
          <button
            type="button"
            onClick={() => {
              setFrom("");
              setTo("");
            }}
            className="smallcaps h-9 border border-gold-soft/60 px-2.5 text-[10px] font-medium text-ink-soft"
          >
            Quitar fechas
          </button>
        )}
      </div>

      {error && <p className="mt-3 text-[12.5px] text-[#b3261e]">{error}</p>}
      {loading && !data && <p className="mt-8 text-center text-[13px] text-ink-faint">Cargando…</p>}

      {data && k && (
        <div className={`mt-3 ${loading ? "opacity-60" : ""}`}>
          {/* Total y Total efectivas (con personas), como en Precompro */}
          <div className="grid grid-cols-2 gap-2">
            <div className="border border-gold-soft/50 bg-navy px-4 py-3 text-gold-soft">
              <p className="smallcaps text-[9px] text-gold-soft/70">Total</p>
              <p className="mt-1 font-display text-[26px] leading-none">{k.total}</p>
              <p className="mt-1 text-[11px] text-gold-soft/80">{k.totalPeople} personas</p>
            </div>
            <div className="border border-verde/40 bg-verde/10 px-4 py-3">
              <p className="smallcaps text-[9px] text-verde">Total efectivas</p>
              <p className="mt-1 font-display text-[26px] leading-none text-navy">{k.effective}</p>
              <p className="mt-1 text-[11px] text-ink-soft">{k.effectivePeople} personas</p>
            </div>
          </div>
          <div className="mt-2 grid grid-cols-3 gap-2">
            {[
              ["Pendientes", String(k.pending)],
              ["No llegaron", String(k.noShow)],
              ["Canceladas", String(k.cancelled)],
            ].map(([label, value]) => (
              <div key={label} className="border border-gold-soft/50 bg-card px-3 py-2.5">
                <p className="smallcaps text-[9px] text-gold-deep">{label}</p>
                <p className="mt-1 font-display text-[20px] leading-none text-navy">{value}</p>
              </div>
            ))}
          </div>

          <div className="mt-3 flex flex-col gap-3">
            <div className="grid gap-3 sm:grid-cols-2">
              <StatCard title="Qué se mueve más">
                <ul className="flex flex-col gap-2">
                  {meals.map((m) => (
                    <li key={m.key}>
                      <div className="flex items-baseline justify-between gap-2 text-[12px]">
                        <span className="text-ink">{m.key}</span>
                        <span className="font-medium text-navy">{m.value}</span>
                      </div>
                      <div className="mt-0.5 h-1.5 bg-paper-deep">
                        <div className="h-full bg-navy/80" style={{ width: `${(m.value / mealMax) * 100}%` }} />
                      </div>
                    </li>
                  ))}
                </ul>
              </StatCard>
              <StatCard title="Por dónde llegan">
                {(data.byOrigin ?? []).length === 0 ? (
                  <p className="py-4 text-center text-[12px] text-ink-faint">Sin datos en este rango.</p>
                ) : (
                  <ul className="flex flex-col gap-2">
                    {data.byOrigin.map((o) => (
                      <li key={o.source}>
                        <div className="flex items-baseline justify-between gap-2 text-[12px]">
                          <span className="text-ink">{SOURCE_LABEL[o.source] ?? o.source}</span>
                          <span className="font-medium text-navy">{o.count}</span>
                        </div>
                        <div className="mt-0.5 h-1.5 bg-paper-deep">
                          <div className="h-full bg-gold-deep/80" style={{ width: `${(o.count / originMax) * 100}%` }} />
                        </div>
                      </li>
                    ))}
                  </ul>
                )}
              </StatCard>
            </div>

            <StatCard title={useMonths ? "Reservas por mes" : "Reservas por día"}>
              <MiniBars
                values={series.map((s) => s.count)}
                labels={series.map((s) => (useMonths ? monthLabel((s as { month: string }).month) : (s as { day: string }).day.slice(8)))}
                labelEvery={series.length > 14 ? Math.ceil(series.length / 10) : 1}
              />
            </StatCard>
            <StatCard title={useMonths ? "Personas por mes" : "Personas por día"}>
              <MiniBars
                values={series.map((s) => s.people)}
                labels={series.map((s) => (useMonths ? monthLabel((s as { month: string }).month) : (s as { day: string }).day.slice(8)))}
                labelEvery={series.length > 14 ? Math.ceil(series.length / 10) : 1}
              />
            </StatCard>
            <StatCard title="Reservas por hora del día">
              <MiniBars
                values={Array.from({ length: 24 }, (_, h) => data.byHour.find((x) => x.hour === h)?.count ?? 0)}
                labels={Array.from({ length: 24 }, (_, h) => `${h}`)}
                labelEvery={3}
                height={100}
              />
            </StatCard>
            {data.byLocation.length > 1 && (
              <StatCard title="Reservas por sede">
                <ul className="flex flex-col gap-2">
                  {data.byLocation.map((l) => {
                    const max = Math.max(1, ...data.byLocation.map((x) => x.count));
                    return (
                      <li key={l.id}>
                        <div className="flex items-baseline justify-between gap-2 text-[12px]">
                          <span className="text-ink">{l.name}</span>
                          <span className="font-medium text-navy">{l.count}</span>
                        </div>
                        <div className="mt-0.5 h-1.5 bg-paper-deep">
                          <div className="h-full bg-gold-deep/80" style={{ width: `${(l.count / max) * 100}%` }} />
                        </div>
                      </li>
                    );
                  })}
                </ul>
              </StatCard>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ── Bloquear días y horas (calendario) ──
function fmtBlockDay(iso: string): string {
  const [y, m, d] = iso.split("-").map(Number);
  const dt = new Date(y, m - 1, d);
  const dow = ["dom", "lun", "mar", "mié", "jue", "vie", "sáb"][dt.getDay()];
  const meses = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
  return `${dow} ${d} ${meses[m - 1]} ${y}`;
}

function BlocksPanel({ code }: { code: string }) {
  const [ctx, setCtx] = useState<StaffContext | null>(null);
  const [blocks, setBlocks] = useState<ReservationBlock[] | null>(null);
  const [error, setError] = useState("");

  // Formulario de nuevo bloqueo
  const [date, setDate] = useState("");
  const [allDay, setAllDay] = useState(true);
  const [startTime, setStartTime] = useState("12:00");
  const [endTime, setEndTime] = useState("15:00");
  const [reason, setReason] = useState("");
  const [scope, setScope] = useState<string>(""); // "" = todas las sedes (dueño)
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    try {
      const [c, b] = await Promise.all([staffContext(code), staffReservationBlocks(code)]);
      setCtx(c);
      setBlocks(b);
      setError("");
    } catch {
      setError("No se pudieron cargar los bloqueos.");
    }
  }, [code]);

  useEffect(() => {
    load();
  }, [load]);

  const add = async () => {
    if (!date || saving) return;
    setSaving(true);
    setError("");
    try {
      await staffAddReservationBlock(code, {
        date,
        allDay,
        startTime: allDay ? undefined : startTime,
        endTime: allDay ? undefined : endTime,
        reason: reason.trim(),
        location: ctx?.allLocations ? (scope || null) : undefined,
      });
      setDate("");
      setReason("");
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudo bloquear.");
    } finally {
      setSaving(false);
    }
  };

  const remove = async (b: ReservationBlock) => {
    setBlocks((prev) => (prev ? prev.filter((x) => x.id !== b.id) : prev));
    try {
      await staffRemoveReservationBlock(code, b.id);
    } catch {
      load();
    }
  };

  return (
    <div className="mt-6 border-t border-gold-soft/40 pt-4">
      <h3 className="font-display text-[16px] text-navy">Bloquear días u horas</h3>
      <p className="mt-1 text-[11.5px] text-ink-faint">
        Cierra una fecha completa o un rango de horas. En ese momento el cliente no podrá reservar.
      </p>

      <div className="mt-3 grid gap-3 sm:grid-cols-2">
        <label className="block">
          <span className="smallcaps text-[10px] text-gold-deep">Fecha</span>
          <input
            type="date"
            value={date}
            min={todayBogota()}
            onChange={(e) => setDate(e.target.value)}
            className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy"
          />
        </label>
        {ctx?.allLocations && (
          <label className="block">
            <span className="smallcaps text-[10px] text-gold-deep">Sede</span>
            <select
              value={scope}
              onChange={(e) => setScope(e.target.value)}
              className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[14px] text-ink outline-none focus:border-navy"
            >
              <option value="">Todas las sedes</option>
              <option value="cerritos">Cerritos Mall</option>
              <option value="pilares">Pilares del Bosque</option>
            </select>
          </label>
        )}
      </div>

      <div className="mt-3 flex gap-1.5">
        <button
          type="button"
          onClick={() => setAllDay(true)}
          className={`smallcaps h-9 flex-1 border text-[10.5px] font-medium ${allDay ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-card text-ink-soft"}`}
        >
          Todo el día
        </button>
        <button
          type="button"
          onClick={() => setAllDay(false)}
          className={`smallcaps h-9 flex-1 border text-[10.5px] font-medium ${!allDay ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-card text-ink-soft"}`}
        >
          Un rango de horas
        </button>
      </div>

      {!allDay && (
        <div className="mt-3 grid grid-cols-2 gap-3">
          <label className="block">
            <span className="smallcaps text-[10px] text-gold-deep">Desde</span>
            <input type="time" value={startTime} onChange={(e) => setStartTime(e.target.value)} className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy" />
          </label>
          <label className="block">
            <span className="smallcaps text-[10px] text-gold-deep">Hasta</span>
            <input type="time" value={endTime} onChange={(e) => setEndTime(e.target.value)} className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy" />
          </label>
        </div>
      )}

      <label className="mt-3 block">
        <span className="smallcaps text-[10px] text-gold-deep">Motivo (opcional)</span>
        <input
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          placeholder="Ej. evento privado, mantenimiento…"
          className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[15px] text-ink outline-none focus:border-navy"
        />
      </label>

      <button
        type="button"
        onClick={add}
        disabled={!date || saving}
        className="mt-3 h-11 w-full bg-[#b3261e] text-[14px] font-semibold text-white disabled:opacity-50"
      >
        {saving ? "Bloqueando…" : "Bloquear"}
      </button>
      {error && <p className="mt-2 text-[12px] text-[#b3261e]">{error}</p>}

      {/* Lista de bloqueos vigentes */}
      <div className="mt-4">
        <span className="smallcaps text-[10px] text-gold-deep">Bloqueos activos</span>
        {blocks && blocks.length > 0 ? (
          <ul className="mt-2 flex flex-col gap-1.5">
            {blocks.map((b) => (
              <li key={b.id} className="flex items-center justify-between gap-2 border border-gold-soft/50 bg-card px-3 py-2">
                <div className="min-w-0">
                  <p className="text-[13px] font-medium text-ink">
                    {fmtBlockDay(b.date)}
                    <span className="ml-1.5 text-[12px] font-normal text-ink-soft">
                      {b.allDay ? "· todo el día" : `· ${fmtTime(b.startTime!)}–${fmtTime(b.endTime!)}`}
                    </span>
                  </p>
                  <p className="text-[10.5px] text-ink-faint">
                    {b.locationName}
                    {b.reason && ` · ${b.reason}`}
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => remove(b)}
                  className="smallcaps shrink-0 border border-gold-soft/60 px-2.5 py-1 text-[10px] font-medium text-ink-soft"
                >
                  Quitar
                </button>
              </li>
            ))}
          </ul>
        ) : (
          <p className="mt-2 text-[12px] text-ink-faint">
            {blocks ? "No hay días ni horas bloqueadas." : "Cargando…"}
          </p>
        )}
      </div>
    </div>
  );
}

// ══ Plano del salón (ver y editar) ══
// Reemplaza una mesa (por id) dentro del Floor, devolviendo una copia nueva.
function withTable(floor: Floor, id: string, patch: Partial<FloorTable>): Floor {
  return {
    ...floor,
    zones: floor.zones.map((z) => ({
      ...z,
      tables: z.tables.map((t) => (t.id === id ? { ...t, ...patch } : t)),
    })),
  };
}

const SIZE_PRESETS_RECT = [
  { label: "Pequeña", width: 80, height: 56 },
  { label: "Mediana", width: 96, height: 64 },
  { label: "Grande", width: 120, height: 76 },
  { label: "Larga", width: 150, height: 72 },
];
const SIZE_PRESETS_ROUND = [
  { label: "Pequeña", width: 64, height: 64 },
  { label: "Mediana", width: 84, height: 84 },
  { label: "Grande", width: 110, height: 110 },
];

function FloorPanel({
  floor,
  code,
  onChanged,
  onAuth,
  onPickTable,
}: {
  floor: Floor | null;
  code: string;
  onChanged: () => void;
  onAuth: () => void;
  onPickTable: (tableId: string) => void;
}) {
  const [editing, setEditing] = useState(false);
  const [zoneId, setZoneId] = useState<string | null>(null);
  const [local, setLocal] = useState<Floor | null>(floor);
  const [editTable, setEditTable] = useState<FloorTable | null>(null);
  const [busy, setBusy] = useState(false);
  const drag = useRef<{ id: string; sx: number; sy: number; ox: number; oy: number; moved: boolean } | null>(null);

  // Adopta lo que llega del servidor salvo mientras se arrastra una mesa.
  useEffect(() => {
    if (!drag.current) setLocal(floor);
  }, [floor]);

  const zones = local?.zones ?? [];
  const active = zones.find((z) => z.id === zoneId) ?? zones[0] ?? null;
  useEffect(() => {
    if (active && active.id !== zoneId) setZoneId(active.id);
  }, [active, zoneId]);

  const run = async (fn: () => Promise<unknown>) => {
    if (busy) return;
    setBusy(true);
    try {
      await fn();
      onChanged();
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else window.alert(e instanceof Error ? e.message : "No se pudo guardar.");
    } finally {
      setBusy(false);
    }
  };

  const addZone = () => {
    const name = window.prompt("Nombre de la nueva zona (ej. Terraza, VIP):", "");
    if (!name || !local) return;
    run(() => staffSaveZone(code, { locationId: local.locationId, name: name.trim() }));
  };
  const renameZone = () => {
    if (!active) return;
    const name = window.prompt("Nuevo nombre de la zona:", active.name);
    if (!name) return;
    run(() => staffSaveZone(code, { id: active.id, name: name.trim() }));
  };
  const deleteZone = () => {
    if (!active) return;
    if (!window.confirm(`¿Borrar la zona "${active.name}" y todas sus mesas?`)) return;
    run(() => staffDeleteZone(code, active.id));
  };
  const addTable = () => {
    if (!active) return;
    const n = active.tables.length + 1;
    run(() =>
      staffSaveTable(code, {
        zoneId: active.id,
        name: `M${n}`,
        seats: 4,
        shape: "rect",
        width: 96,
        height: 64,
        posX: 20,
        posY: 20,
      }),
    );
  };

  // ── Arrastre de una mesa (modo edición) ──
  const onDown = (t: FloorTable) => (e: React.PointerEvent) => {
    if (!editing) return;
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    drag.current = { id: t.id, sx: e.clientX, sy: e.clientY, ox: t.posX, oy: t.posY, moved: false };
  };
  const onMove = (t: FloorTable) => (e: React.PointerEvent) => {
    const d = drag.current;
    if (!d || d.id !== t.id || !local) return;
    const dx = e.clientX - d.sx;
    const dy = e.clientY - d.sy;
    if (Math.abs(dx) + Math.abs(dy) > 4) d.moved = true;
    setLocal(withTable(local, t.id, { posX: Math.max(0, d.ox + dx), posY: Math.max(0, d.oy + dy) }));
  };
  const onUp = (t: FloorTable) => (e: React.PointerEvent) => {
    const d = drag.current;
    drag.current = null;
    if (!d) return;
    try {
      (e.currentTarget as HTMLElement).releasePointerCapture(e.pointerId);
    } catch {
      /* noop */
    }
    if (d.moved) {
      const fx = Math.max(0, d.ox + (e.clientX - d.sx));
      const fy = Math.max(0, d.oy + (e.clientY - d.sy));
      staffMoveTable(code, t.id, fx, fy).catch(() => onChanged());
    } else {
      setEditTable(t);
    }
  };

  if (!local) {
    return (
      <div className="mt-4 border border-gold-soft/60 bg-paper p-4">
        <p className="text-center text-[13px] text-ink-faint">Cargando plano…</p>
      </div>
    );
  }

  const tables = active?.tables ?? [];
  const CW = Math.max(560, ...tables.map((t) => t.posX + t.width)) + 30;
  const CH = Math.max(340, ...tables.map((t) => t.posY + t.height)) + 30;

  return (
    <div className="mt-4 border border-gold-soft/60 bg-paper p-4">
      <div className="flex items-center justify-between gap-2">
        <p className="text-[11.5px] text-ink-faint">
          {editing
            ? "Arrastra las mesas para ubicarlas. Toca una mesa para cambiar nombre, cupo o forma."
            : "Toca una mesa libre para sentar un Walk-In. Las reservas del día se asignan desde cada tarjeta."}
        </p>
        <button
          type="button"
          onClick={() => setEditing((v) => !v)}
          className={`smallcaps h-8 shrink-0 rounded-full border px-3 text-[10px] font-semibold ${editing ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 text-ink-soft"}`}
        >
          {editing ? "Listo" : "Editar plano"}
        </button>
      </div>

      {/* Zonas */}
      <div className="chips-scroll mt-3 flex items-center gap-1.5 overflow-x-auto pb-1">
        {zones.map((z) => (
          <button
            key={z.id}
            type="button"
            onClick={() => setZoneId(z.id)}
            className={`smallcaps h-8 shrink-0 border px-3 text-[10.5px] font-medium ${z.id === active?.id ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/60 bg-card text-ink-soft"}`}
          >
            {z.name}
          </button>
        ))}
        {editing && (
          <button
            type="button"
            onClick={addZone}
            className="smallcaps h-8 shrink-0 border border-dashed border-gold-deep/60 px-3 text-[10.5px] font-medium text-gold-deep"
          >
            + Zona
          </button>
        )}
      </div>

      {editing && active && (
        <div className="mt-2 flex flex-wrap gap-1.5">
          <button type="button" onClick={addTable} className="smallcaps h-8 bg-navy px-3 text-[10px] font-semibold text-gold-soft">
            + Mesa
          </button>
          <button type="button" onClick={renameZone} className="smallcaps h-8 border border-gold-soft/70 px-3 text-[10px] font-medium text-ink-soft">
            Renombrar zona
          </button>
          <button type="button" onClick={deleteZone} className="smallcaps h-8 border border-[#b3261e]/50 px-3 text-[10px] font-medium text-[#b3261e]">
            Borrar zona
          </button>
        </div>
      )}

      {/* Lienzo del plano */}
      {!active ? (
        <p className="mt-6 text-center text-[13px] text-ink-faint">
          Esta sede no tiene zonas. {editing ? "Crea una con “+ Zona”." : "Toca “Editar plano” para crearlas."}
        </p>
      ) : (
        <div className="mt-3 max-h-[62vh] overflow-auto rounded border border-gold-soft/40 bg-[repeating-linear-gradient(0deg,transparent,transparent_23px,rgba(4,17,29,0.04)_24px),repeating-linear-gradient(90deg,transparent,transparent_23px,rgba(4,17,29,0.04)_24px)]">
          <div className="relative" style={{ width: CW, height: CH }}>
            {tables.length === 0 && (
              <p className="absolute left-1/2 top-8 -translate-x-1/2 text-[12px] text-ink-faint">
                {editing ? "Agrega mesas con “+ Mesa”." : "Sin mesas en esta zona."}
              </p>
            )}
            {tables.map((t) => {
              const seated = t.reservations.reduce((s, r) => s + r.party, 0);
              const occupied = t.reservations.length > 0;
              const common = "absolute flex flex-col items-center justify-center border text-center select-none";
              const style: React.CSSProperties = {
                left: t.posX,
                top: t.posY,
                width: t.width,
                height: t.height,
                borderRadius: t.shape === "round" ? "9999px" : "8px",
                touchAction: editing ? "none" : undefined,
              };
              const cls = occupied
                ? "border-navy bg-navy/[0.06] text-navy"
                : editing
                  ? "border-gold-deep/60 bg-card text-navy cursor-move"
                  : "border-gold-soft/70 bg-card text-navy hover:border-verde hover:bg-verde/5";
              const inner = (
                <>
                  <span className="font-display text-[15px] leading-none">{t.name}</span>
                  {occupied ? (
                    <span className="mt-0.5 text-[9px] text-navy/70">
                      {seated}/{t.seats}
                    </span>
                  ) : (
                    <span className="mt-0.5 text-[9px] text-ink-faint">{t.seats} pax</span>
                  )}
                </>
              );
              if (editing) {
                return (
                  <div
                    key={t.id}
                    role="button"
                    tabIndex={0}
                    onPointerDown={onDown(t)}
                    onPointerMove={onMove(t)}
                    onPointerUp={onUp(t)}
                    className={`${common} ${cls}`}
                    style={style}
                  >
                    {inner}
                  </div>
                );
              }
              return (
                <button
                  key={t.id}
                  type="button"
                  onClick={() => !occupied && onPickTable(t.id)}
                  className={`${common} ${cls} ${occupied ? "cursor-default" : ""}`}
                  style={style}
                >
                  {inner}
                </button>
              );
            })}
          </div>
        </div>
      )}

      {editTable && (
        <TableEditor
          code={code}
          table={editTable}
          onClose={() => setEditTable(null)}
          onSaved={() => {
            setEditTable(null);
            onChanged();
          }}
          onAuth={onAuth}
        />
      )}
    </div>
  );
}

// ══ Editor de una mesa (nombre, cupo, forma, tamaño, borrar) ══
function TableEditor({
  code,
  table,
  onClose,
  onSaved,
  onAuth,
}: {
  code: string;
  table: FloorTable;
  onClose: () => void;
  onSaved: () => void;
  onAuth: () => void;
}) {
  const [name, setName] = useState(table.name);
  const [seats, setSeats] = useState(table.seats);
  const [shape, setShape] = useState<"rect" | "round">(table.shape);
  const [width, setWidth] = useState(table.width);
  const [height, setHeight] = useState(table.height);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const presets = shape === "round" ? SIZE_PRESETS_ROUND : SIZE_PRESETS_RECT;
  const pickShape = (s: "rect" | "round") => {
    setShape(s);
    const def = (s === "round" ? SIZE_PRESETS_ROUND : SIZE_PRESETS_RECT)[1];
    setWidth(def.width);
    setHeight(def.height);
  };

  const save = async () => {
    if (!name.trim()) {
      setError("Ponle un nombre a la mesa.");
      return;
    }
    setSaving(true);
    try {
      await staffSaveTable(code, { id: table.id, name: name.trim(), seats, shape, width, height });
      onSaved();
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setError(e instanceof Error ? e.message : "No se pudo guardar.");
      setSaving(false);
    }
  };

  const remove = async () => {
    if (!window.confirm(`¿Borrar la mesa "${table.name}"?`)) return;
    setSaving(true);
    try {
      await staffDeleteTable(code, table.id);
      onSaved();
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setError("No se pudo borrar.");
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end lg:items-center lg:justify-center lg:p-6" role="dialog" aria-modal="true" aria-label="Editar mesa">
      <button type="button" aria-label="Cerrar" onClick={onClose} className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]" />
      <div className="anim-sheet-up relative mx-auto w-full max-w-sm">
        <div className="rounded-t-3xl bg-card px-5 pb-[calc(env(safe-area-inset-bottom)+20px)] pt-4 shadow-[0_-12px_40px_rgba(4,17,29,0.25)] lg:rounded-2xl lg:pb-6">
          <h3 className="font-display text-[18px] text-navy">Mesa</h3>

          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Nombre</span>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy"
            />
          </label>

          <div className="mt-3">
            <span className="smallcaps text-[10px] text-gold-deep">Personas</span>
            <div className="mt-1 flex items-center gap-3">
              <button type="button" onClick={() => setSeats((s) => Math.max(1, s - 1))} className="h-11 w-11 border border-gold-soft/70 bg-paper text-[20px] text-navy">−</button>
              <span className="min-w-[2ch] text-center font-display text-[22px] text-navy">{seats}</span>
              <button type="button" onClick={() => setSeats((s) => Math.min(40, s + 1))} className="h-11 w-11 border border-gold-soft/70 bg-paper text-[20px] text-navy">+</button>
            </div>
          </div>

          <div className="mt-3">
            <span className="smallcaps text-[10px] text-gold-deep">Forma</span>
            <div className="mt-1 flex gap-1.5">
              <button type="button" onClick={() => pickShape("rect")} className={`h-10 flex-1 border text-[12.5px] font-medium ${shape === "rect" ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-paper text-ink-soft"}`}>
                Rectangular
              </button>
              <button type="button" onClick={() => pickShape("round")} className={`h-10 flex-1 border text-[12.5px] font-medium ${shape === "round" ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-paper text-ink-soft"}`}>
                Redonda
              </button>
            </div>
          </div>

          <div className="mt-3">
            <span className="smallcaps text-[10px] text-gold-deep">Tamaño</span>
            <div className="mt-1 flex gap-1.5">
              {presets.map((p) => (
                <button
                  key={p.label}
                  type="button"
                  onClick={() => {
                    setWidth(p.width);
                    setHeight(p.height);
                  }}
                  className={`h-10 flex-1 border text-[11.5px] font-medium ${width === p.width && height === p.height ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-paper text-ink-soft"}`}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          {error && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{error}</p>}

          <div className="mt-4 flex gap-2">
            <button type="button" onClick={save} disabled={saving} className="h-12 flex-1 bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60">
              {saving ? "Guardando…" : "Guardar"}
            </button>
            <button type="button" onClick={remove} disabled={saving} className="h-12 border border-[#b3261e]/60 px-4 text-[13px] font-medium text-[#b3261e]">
              Borrar
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ══ Registrar Walk-In ══
function WalkinModal({
  code,
  tables,
  initialTable,
  onClose,
  onDone,
  onAuth,
}: {
  code: string;
  tables: { id: string; label: string; seats: number }[];
  initialTable: string | null;
  onClose: () => void;
  onDone: () => void;
  onAuth: () => void;
}) {
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [party, setParty] = useState(2);
  const [note, setNote] = useState("");
  const [table, setTable] = useState<string>(initialTable ?? "");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const submit = async () => {
    if (saving) return;
    setSaving(true);
    setError("");
    try {
      await staffWalkin(code, {
        name: name.trim(),
        phone: phone.trim(),
        party,
        note: note.trim(),
        table: table || null,
      });
      onDone();
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setError(e instanceof Error ? e.message : "No se pudo registrar.");
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end lg:items-center lg:justify-center lg:p-6" role="dialog" aria-modal="true" aria-label="Registrar Walk-In">
      <button type="button" aria-label="Cerrar" onClick={onClose} className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]" />
      <div className="anim-sheet-up relative mx-auto w-full max-w-md">
        <div className="max-h-[92dvh] overflow-y-auto rounded-t-3xl bg-card px-5 pb-[calc(env(safe-area-inset-bottom)+20px)] pt-4 shadow-[0_-12px_40px_rgba(4,17,29,0.25)] lg:max-h-[85vh] lg:rounded-2xl lg:pb-6">
          <h3 className="font-display text-[18px] text-navy">Registrar Walk-In</h3>
          <p className="mt-0.5 text-[11.5px] text-ink-faint">Cliente que llega sin reserva. Entra ya sentado.</p>

          <div className="mt-3">
            <span className="smallcaps text-[10px] text-gold-deep">Personas</span>
            <div className="mt-1 flex items-center gap-3">
              <button type="button" onClick={() => setParty((p) => Math.max(1, p - 1))} className="h-11 w-11 border border-gold-soft/70 bg-paper text-[20px] text-navy">−</button>
              <span className="min-w-[2ch] text-center font-display text-[24px] text-navy">{party}</span>
              <button type="button" onClick={() => setParty((p) => Math.min(50, p + 1))} className="h-11 w-11 border border-gold-soft/70 bg-paper text-[20px] text-navy">+</button>
            </div>
          </div>

          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Nombre (opcional)</span>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Walk-In" className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy" />
          </label>
          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Celular (opcional)</span>
            <input value={phone} onChange={(e) => setPhone(e.target.value)} inputMode="tel" placeholder="+57 300 123 4567" className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy" />
          </label>
          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Mesa (opcional)</span>
            <select value={table} onChange={(e) => setTable(e.target.value)} className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[14px] text-ink outline-none focus:border-navy">
              <option value="">Sin asignar</option>
              {tables.map((t) => (
                <option key={t.id} value={t.id}>{t.label} ({t.seats})</option>
              ))}
            </select>
          </label>
          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Nota (opcional)</span>
            <input value={note} onChange={(e) => setNote(e.target.value)} placeholder="Ej. junto a la ventana" className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy" />
          </label>

          {error && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{error}</p>}
          <div className="mt-4 flex gap-2">
            <button type="button" onClick={submit} disabled={saving} className="h-12 flex-1 bg-verde text-[14px] font-semibold text-white disabled:opacity-60">
              {saving ? "Registrando…" : "Sentar Walk-In"}
            </button>
            <button type="button" onClick={onClose} className="h-12 border border-gold-soft/70 px-5 text-[13px] text-ink-soft">Cancelar</button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ══ Crear una reserva a mano (teléfono, Google, web, otro) ══
const NUEVA_SOURCES: { key: ReservationSource; label: string }[] = [
  { key: "telefono", label: "Teléfono" },
  { key: "google", label: "Google" },
  { key: "web", label: "Página web" },
  { key: "otro", label: "Otro" },
];

function NuevaReservaModal({
  code,
  tables,
  defaultDay,
  onClose,
  onDone,
  onAuth,
}: {
  code: string;
  tables: { id: string; label: string; seats: number }[];
  defaultDay: string;
  onClose: () => void;
  onDone: () => void;
  onAuth: () => void;
}) {
  const [source, setSource] = useState<ReservationSource>("telefono");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [party, setParty] = useState(2);
  const [date, setDate] = useState(defaultDay);
  const [time, setTime] = useState("19:00");
  const [note, setNote] = useState("");
  const [table, setTable] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const submit = async () => {
    if (saving) return;
    if (!name.trim()) {
      setError("Escribe el nombre de quien reserva.");
      return;
    }
    if (!date || !time) {
      setError("Elige la fecha y la hora.");
      return;
    }
    setSaving(true);
    setError("");
    try {
      await staffCreateReservation(code, {
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        party,
        date,
        time,
        note: note.trim(),
        source,
        table: table || null,
      });
      onDone();
    } catch (e) {
      if (isAuthError(e)) onAuth();
      else setError(e instanceof Error ? e.message : "No se pudo crear la reserva.");
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end lg:items-center lg:justify-center lg:p-6" role="dialog" aria-modal="true" aria-label="Nueva reserva">
      <button type="button" aria-label="Cerrar" onClick={onClose} className="anim-fade-in absolute inset-0 bg-navy/45 backdrop-blur-[2px]" />
      <div className="anim-sheet-up relative mx-auto w-full max-w-md">
        <div className="max-h-[92dvh] overflow-y-auto rounded-t-3xl bg-card px-5 pb-[calc(env(safe-area-inset-bottom)+20px)] pt-4 shadow-[0_-12px_40px_rgba(4,17,29,0.25)] lg:max-h-[85vh] lg:rounded-2xl lg:pb-6">
          <h3 className="font-display text-[18px] text-navy">Nueva reserva</h3>
          <p className="mt-0.5 text-[11.5px] text-ink-faint">Para cuando llaman, llega por Google o la anotas tú.</p>

          <div className="mt-3">
            <span className="smallcaps text-[10px] text-gold-deep">¿Por dónde llegó?</span>
            <div className="mt-1 grid grid-cols-4 gap-1.5">
              {NUEVA_SOURCES.map((s) => (
                <button
                  key={s.key}
                  type="button"
                  onClick={() => setSource(s.key)}
                  className={`h-9 border text-[11px] font-medium ${source === s.key ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-paper text-ink-soft"}`}
                >
                  {s.label}
                </button>
              ))}
            </div>
          </div>

          <div className="mt-3 grid grid-cols-2 gap-2">
            <label className="block">
              <span className="smallcaps text-[10px] text-gold-deep">Fecha</span>
              <input type="date" value={date} onChange={(e) => setDate(e.target.value)} className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-2.5 text-[14px] text-ink outline-none focus:border-navy" />
            </label>
            <label className="block">
              <span className="smallcaps text-[10px] text-gold-deep">Hora</span>
              <input type="time" value={time} onChange={(e) => setTime(e.target.value)} className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-2.5 text-[14px] text-ink outline-none focus:border-navy" />
            </label>
          </div>

          <div className="mt-3">
            <span className="smallcaps text-[10px] text-gold-deep">Personas</span>
            <div className="mt-1 flex items-center gap-3">
              <button type="button" onClick={() => setParty((p) => Math.max(1, p - 1))} className="h-11 w-11 border border-gold-soft/70 bg-paper text-[20px] text-navy">−</button>
              <span className="min-w-[2ch] text-center font-display text-[24px] text-navy">{party}</span>
              <button type="button" onClick={() => setParty((p) => Math.min(50, p + 1))} className="h-11 w-11 border border-gold-soft/70 bg-paper text-[20px] text-navy">+</button>
            </div>
          </div>

          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Nombre *</span>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Quien reserva" className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy" />
          </label>
          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Celular (opcional)</span>
            <input value={phone} onChange={(e) => setPhone(e.target.value)} inputMode="tel" placeholder="+57 300 123 4567" className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy" />
          </label>
          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Correo (opcional)</span>
            <input value={email} onChange={(e) => setEmail(e.target.value)} inputMode="email" placeholder="correo@ejemplo.com" className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy" />
          </label>
          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Mesa (opcional)</span>
            <select value={table} onChange={(e) => setTable(e.target.value)} className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[14px] text-ink outline-none focus:border-navy">
              <option value="">Sin asignar</option>
              {tables.map((t) => (
                <option key={t.id} value={t.id}>{t.label} ({t.seats})</option>
              ))}
            </select>
          </label>
          <label className="mt-3 block">
            <span className="smallcaps text-[10px] text-gold-deep">Nota (opcional)</span>
            <input value={note} onChange={(e) => setNote(e.target.value)} placeholder="Ej. cumpleaños, junto a la ventana" className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3 text-[15px] text-ink outline-none focus:border-navy" />
          </label>

          {error && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{error}</p>}
          <div className="mt-4 flex gap-2">
            <button type="button" onClick={submit} disabled={saving} className="h-12 flex-1 bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60">
              {saving ? "Creando…" : "Crear reserva"}
            </button>
            <button type="button" onClick={onClose} className="h-12 border border-gold-soft/70 px-5 text-[13px] text-ink-soft">Cancelar</button>
          </div>
        </div>
      </div>
    </div>
  );
}

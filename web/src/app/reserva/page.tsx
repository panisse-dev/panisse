"use client";

// Pantalla a la que llega el cliente desde el botón "Modificar o cancelar"
// del correo. Con el enlace (que lleva el id de su reserva) puede cambiar
// fecha, hora y número de personas, o cancelarla.

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { restaurant } from "@/lib/menu";
import {
  formatDateLabel,
  formatTime,
  reservationAvailability,
  reservationCancel,
  reservationConfig,
  reservationUpdate,
  reservationView,
  type ManagedReservation,
  type ReservationConfig,
  type Slot,
} from "@/lib/reservations";

function todayBogota(): string {
  return new Date().toLocaleDateString("en-CA", { timeZone: "America/Bogota" });
}

function addDays(iso: string, n: number): string {
  const [y, m, d] = iso.split("-").map(Number);
  const dt = new Date(y, m - 1, d + n);
  return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
}

function isoDow(iso: string): number {
  const [y, m, d] = iso.split("-").map(Number);
  return ((new Date(y, m - 1, d).getDay() + 6) % 7) + 1; // 1=lun … 7=dom
}

type Mode = "ver" | "editar" | "cancelar";

export default function ReservaPage() {
  const [id, setId] = useState<string | null>(null);
  const [res, setRes] = useState<ManagedReservation | null>(null);
  const [cfg, setCfg] = useState<ReservationConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);
  const [mode, setMode] = useState<Mode>("ver");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [savedMsg, setSavedMsg] = useState("");

  // Campos del cambio
  const [party, setParty] = useState(2);
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");
  const [slots, setSlots] = useState<Slot[] | null>(null);
  const [dayClosed, setDayClosed] = useState("");
  const [loadingSlots, setLoadingSlots] = useState(false);

  useEffect(() => {
    const v = new URLSearchParams(window.location.search).get("id");
    setId(v);
    if (!v) {
      setNotFound(true);
      setLoading(false);
      return;
    }
    Promise.all([reservationView(v), reservationConfig()])
      .then(([r, c]) => {
        if (!r) {
          setNotFound(true);
        } else {
          setRes(r);
          setParty(r.party);
          setDate(r.date);
          setTime(r.time);
        }
        setCfg(c);
      })
      .catch(() => setNotFound(true))
      .finally(() => setLoading(false));
  }, []);

  const loadSlots = useCallback(
    async (d: string, p: number, loc: string) => {
      setLoadingSlots(true);
      setDayClosed("");
      try {
        const av = await reservationAvailability(d, p, loc);
        if (!av.open) {
          setSlots([]);
          setDayClosed(av.reason || "Ese día no recibimos reservas");
        } else {
          setSlots(av.slots);
        }
      } catch {
        setSlots([]);
        setDayClosed("No pudimos cargar los horarios. Revisa tu internet.");
      } finally {
        setLoadingSlots(false);
      }
    },
    [],
  );

  useEffect(() => {
    if (mode === "editar" && date && res) loadSlots(date, party, res.location);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mode, date, party, res?.location]);

  if (loading) {
    return (
      <Shell>
        <p className="mt-10 text-center text-[13.5px] text-ink-faint">Cargando tu reserva…</p>
      </Shell>
    );
  }

  if (notFound || !res || !cfg) {
    return (
      <Shell title="No encontramos tu reserva">
        <p className="mt-3 text-center text-[13.5px] leading-relaxed text-ink-soft">
          El enlace no es válido o la reserva ya no existe. Escríbenos y te ayudamos.
        </p>
        <a
          href={`https://wa.me/${restaurant.whatsapp.replace(/\D/g, "")}`}
          className="mt-5 flex h-12 w-full items-center justify-center bg-verde text-[14px] font-semibold text-white"
        >
          Escríbenos por WhatsApp
        </a>
      </Shell>
    );
  }

  const cancelled = res.status === "cancelada";
  const days = Array.from({ length: 8 }, (_, i) => addDays(todayBogota(), i)).filter((d) =>
    cfg.openDays.includes(isoDow(d)),
  );

  const doCancel = async () => {
    setError("");
    setSaving(true);
    try {
      setRes(await reservationCancel(id!));
      setMode("ver");
      setSavedMsg("Tu reserva quedó cancelada.");
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudo cancelar");
    } finally {
      setSaving(false);
    }
  };

  const doSave = async () => {
    setError("");
    if (!time) {
      setError("Elige una hora");
      return;
    }
    setSaving(true);
    try {
      setRes(await reservationUpdate(id!, { date, time, party }));
      setMode("ver");
      setSavedMsg("Listo, cambiamos tu reserva. Te enviamos el correo con los datos nuevos.");
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudo cambiar la reserva");
    } finally {
      setSaving(false);
    }
  };

  // ── Confirmar la cancelación ──
  if (mode === "cancelar") {
    return (
      <Shell title="¿Cancelar tu reserva?" onBack={() => setMode("ver")}>
        <div className="mt-3 border border-gold-soft/60 bg-paper p-4 text-center">
          <p className="text-[13.5px] leading-relaxed text-ink-soft">
            Vas a cancelar la reserva de <b className="text-navy">{res.party}</b>{" "}
            {res.party === 1 ? "persona" : "personas"} del{" "}
            <b className="text-navy">{formatDateLabel(res.date)}</b> a las{" "}
            <b className="text-navy">{formatTime(res.time)}</b>.
          </p>
        </div>
        {error && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{error}</p>}
        <button
          type="button"
          onClick={doCancel}
          disabled={saving}
          className="mt-4 h-12 w-full bg-[#b3261e] text-[14px] font-semibold text-white disabled:opacity-60"
        >
          {saving ? "Cancelando…" : "Sí, cancelar mi reserva"}
        </button>
        <button
          type="button"
          onClick={() => setMode("ver")}
          className="mt-2 h-12 w-full border border-gold-soft/70 bg-paper text-[14px] font-semibold text-navy"
        >
          No, dejarla como está
        </button>
      </Shell>
    );
  }

  // ── Cambiar fecha, hora o personas ──
  if (mode === "editar") {
    return (
      <Shell title="Cambiar tu reserva" onBack={() => setMode("ver")}>
        <p className="smallcaps mt-4 text-[10px] text-gold-deep">Personas</p>
        <div className="mt-2 grid grid-cols-6 gap-1.5">
          {Array.from({ length: cfg.maxParty }, (_, i) => i + 1).map((n) => (
            <button
              key={n}
              type="button"
              onClick={() => setParty(n)}
              className={`h-11 border text-[14px] transition-colors ${party === n ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-paper text-ink"}`}
            >
              {n}
            </button>
          ))}
        </div>

        <p className="smallcaps mt-5 text-[10px] text-gold-deep">Fecha</p>
        <div className="mt-2 grid grid-cols-4 gap-1.5">
          {days.map((d) => {
            const [, , dd] = d.split("-");
            const dow = ["LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB", "DOM"][isoDow(d) - 1];
            return (
              <button
                key={d}
                type="button"
                onClick={() => {
                  setDate(d);
                  setTime("");
                }}
                className={`flex h-14 flex-col items-center justify-center border transition-colors ${date === d ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-paper text-ink"}`}
              >
                <span className="text-[9px] tracking-wider">{dow}</span>
                <span className="text-[16px] leading-tight">{Number(dd)}</span>
              </button>
            );
          })}
        </div>

        <p className="smallcaps mt-5 text-[10px] text-gold-deep">Hora</p>
        {loadingSlots ? (
          <p className="mt-2 text-[12.5px] text-ink-faint">Buscando horarios…</p>
        ) : dayClosed ? (
          <p className="mt-2 text-[12.5px] text-ink-faint">{dayClosed}</p>
        ) : (
          <div className="mt-2 grid grid-cols-3 gap-1.5">
            {(slots ?? []).map((s) => (
              <button
                key={s.time}
                type="button"
                disabled={!s.available}
                onClick={() => setTime(s.time)}
                className={`h-11 border text-[13px] transition-colors ${time === s.time ? "border-navy bg-navy text-gold-soft" : s.available ? "border-gold-soft/70 bg-paper text-ink" : "border-gold-soft/40 bg-paper-deep text-ink-faint line-through"}`}
              >
                {formatTime(s.time)}
              </button>
            ))}
          </div>
        )}

        {error && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{error}</p>}
        <button
          type="button"
          onClick={doSave}
          disabled={saving}
          className="mt-5 h-12 w-full bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60"
        >
          {saving ? "Guardando…" : "Guardar los cambios"}
        </button>
      </Shell>
    );
  }

  // ── Vista principal: qué quieres hacer con tu reserva ──
  const firstName = res.name.trim().split(" ")[0] || "";
  return (
    <Shell>
      <div className="pt-4 text-center">
        <h1 className="font-display text-[24px] leading-tight text-navy">
          Hola{firstName ? ` ${firstName}` : ""}
        </h1>
        <p className="mt-1 text-[13.5px] text-ink-soft">
          {cancelled ? "Esta reserva está cancelada" : "¿Qué deseas hacer con tu reserva?"}
        </p>

        <div className="mt-4 grid grid-cols-3 divide-x divide-gold-soft/40 border border-gold-soft/50 bg-paper">
          <Cell value={`${res.party}`} label={res.party === 1 ? "Persona" : "Personas"} />
          <Cell value={formatDateLabel(res.date)} label="Día" />
          <Cell value={formatTime(res.time)} label="Hora" />
        </div>
        {res.locationName && (
          <p className="mt-2 text-[12px] text-ink-faint">Sede: {res.locationName}</p>
        )}

        {savedMsg && (
          <p className="mt-4 border-l-2 border-verde bg-verde/10 px-3 py-2.5 text-left text-[12.5px] text-ink">
            {savedMsg}
          </p>
        )}

        {!cancelled && res.editable && (
          <div className="mt-5 grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => {
                setSavedMsg("");
                setMode("editar");
              }}
              className="h-12 bg-navy text-[14px] font-semibold text-gold-soft"
            >
              Editar reserva
            </button>
            <button
              type="button"
              onClick={() => {
                setSavedMsg("");
                setMode("cancelar");
              }}
              className="h-12 border border-gold-soft/70 bg-paper text-[14px] font-semibold text-navy"
            >
              Cancelar reserva
            </button>
          </div>
        )}

        {!cancelled && !res.editable && (
          <p className="mt-5 text-[12.5px] leading-relaxed text-ink-faint">
            Esta reserva ya está muy cerca (o ya pasó) para cambiarla desde aquí. Escríbenos y te
            ayudamos.
          </p>
        )}

        <a
          href={`https://wa.me/${restaurant.whatsapp.replace(/\D/g, "")}?text=Hola,%20es%20por%20mi%20reserva%20%23${res.code}`}
          className="mt-3 flex h-12 w-full items-center justify-center gap-2 border border-verde bg-paper text-[13.5px] font-semibold text-verde"
        >
          ¿Tienes alguna duda? Escríbenos
        </a>
        <Link
          href="/"
          className="mt-2 flex h-11 w-full items-center justify-center text-[13px] text-ink-faint"
        >
          Volver al inicio
        </Link>
      </div>
    </Shell>
  );
}

function Cell({ value, label }: { value: string; label: string }) {
  return (
    <div className="px-2 py-3">
      <div className="text-[13.5px] font-semibold text-navy">{value}</div>
      <div className="smallcaps mt-0.5 text-[9px] text-ink-faint">{label}</div>
    </div>
  );
}

function Shell({
  children,
  title,
  onBack,
}: {
  children: React.ReactNode;
  title?: string;
  onBack?: () => void;
}) {
  return (
    <div className="page-col relative mx-auto min-h-dvh w-full max-w-md px-5 pb-10 pt-4">
      <div className="marble-fixed" aria-hidden />
      <div className="relative z-10">
        <header className="flex items-center justify-between pb-2 pt-2">
          {onBack ? (
            <button
              type="button"
              onClick={onBack}
              aria-label="Volver"
              className="flex h-9 w-9 items-center justify-center rounded-full text-ink-soft active:bg-paper-deep"
            >
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                <path d="M15 5l-7 7 7 7" />
              </svg>
            </button>
          ) : (
            <span className="w-9" />
          )}
          <p className="smallcaps text-[10px] text-gold-deep">PANISSE</p>
          <span className="w-9" />
        </header>
        {title && <h1 className="mt-1 text-center font-display text-[24px] text-navy">{title}</h1>}
        {children}
      </div>
    </div>
  );
}

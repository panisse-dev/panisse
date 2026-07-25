"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { restaurant } from "@/lib/menu";
import { checkClient, EMAIL_RE, type ClientCheck } from "@/lib/api";
import {
  createReservation,
  formatDateLabel,
  formatTime,
  publicDecorationDesserts,
  publicDecorations,
  publicFloor,
  reservationAvailability,
  reservationConfig,
  reservationSetDecoration,
  type CreatedReservation,
  type Decoration,
  type DecorationDessert,
  type PublicFloor,
  type PublicTable,
  type ReservationConfig,
  type Slot,
} from "@/lib/reservations";
import { formatCOP } from "@/lib/format";
import { useLocation } from "@/lib/location";

type Step = "elige" | "mesa" | "datos" | "listo";

// Fecha de hoy en Bogotá como YYYY-MM-DD (sin líos de zona horaria).
function todayBogota(): string {
  return new Date().toLocaleDateString("en-CA", { timeZone: "America/Bogota" });
}

// Suma días a un YYYY-MM-DD y devuelve YYYY-MM-DD.
function addDays(iso: string, n: number): string {
  const [y, m, d] = iso.split("-").map(Number);
  const dt = new Date(y, m - 1, d + n);
  return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
}

// El campo del celular muestra "+57" aparte; aquí se arma el número completo.
function fullPhone(raw: string): string {
  const t = raw.trim();
  if (t.startsWith("+")) return t;
  const digits = t.replace(/\D/g, "");
  return digits ? `+57${digits}` : "";
}

// ¿Esta decoración necesita que el cliente escoja algo antes de agregarla?
function hasOptions(d: Decoration): boolean {
  return d.colorOptions.length > 0 || d.dessertMode !== "none";
}

// "1 día" / "3 horas" — con cuánta anticipación se pide, en palabras.
function antelacion(d: Decoration): string {
  if (d.advanceDays > 0) return `${d.advanceDays} día${d.advanceDays === 1 ? "" : "s"}`;
  if (d.advanceHours > 0) return `${d.advanceHours} hora${d.advanceHours === 1 ? "" : "s"}`;
  return "";
}

function isoDow(iso: string): number {
  const [y, m, d] = iso.split("-").map(Number);
  return ((new Date(y, m - 1, d).getDay() + 6) % 7) + 1; // 1=lun … 7=dom
}

export default function ReservarPage() {
  const { sedes, sede, sedeId, setSede, ready: sedeReady } = useLocation();
  const [cfg, setCfg] = useState<ReservationConfig | null>(null);
  const [loadErr, setLoadErr] = useState(false);

  const [step, setStep] = useState<Step>("elige");
  const [party, setParty] = useState(2);
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");

  const [slots, setSlots] = useState<Slot[] | null>(null);
  const [dayClosed, setDayClosed] = useState<string>("");
  const [loadingSlots, setLoadingSlots] = useState(false);

  // Mapa de mesas (opcional): el cliente elige su mesa
  const [floor, setFloor] = useState<PublicFloor | null>(null);
  const [loadingFloor, setLoadingFloor] = useState(false);
  const [tableId, setTableId] = useState<string | null>(null);
  const [tableName, setTableName] = useState<string>("");
  const [zoneName, setZoneName] = useState<string>("");

  const [email, setEmail] = useState("");
  const [known, setKnown] = useState<ClientCheck | null>(null);
  const [checking, setChecking] = useState(false);
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [birthday, setBirthday] = useState("");
  const [note, setNote] = useState("");
  const [pet, setPet] = useState(false);
  const [mobility, setMobility] = useState(false);

  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  const [done, setDone] = useState<CreatedReservation | null>(null);

  // Decoraciones de celebración: son de ROKA, que opera en Pilares. Se ofrecen
  // en toda reserva de Pilares (llegue el cliente por donde llegue) y también
  // cuando entra desde la carta de ROKA (?marca=roka).
  const [isRoka, setIsRoka] = useState(false);
  const [decorations, setDecorations] = useState<Decoration[]>([]);
  const [decorationId, setDecorationId] = useState<string>(""); // "" = sin decoración
  // Lo que el cliente escoge sobre esa decoración.
  const [desserts, setDesserts] = useState<DecorationDessert[]>([]);
  const [decoColor, setDecoColor] = useState("");
  const [decoDessert, setDecoDessert] = useState("");
  const [decoMessage, setDecoMessage] = useState("");

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    setIsRoka(params.get("marca") === "roka");
    // Enlace/QR directo a una sede: /reservar?sede=pilares salta la pregunta.
    const s = params.get("sede");
    if (s) setSede(s);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Las decoraciones dependen de la sede y de la fecha elegida: con la fecha
  // se sabe cuáles alcanzan a prepararse (algunas piden un día de anticipación).
  useEffect(() => {
    if (!sedeId) return;
    publicDecorations(sedeId, date || null, time || null)
      .then(setDecorations)
      .catch(() => setDecorations([]));
  }, [sedeId, date, time]);

  useEffect(() => {
    publicDecorationDesserts().then(setDesserts).catch(() => setDesserts([]));
  }, []);

  const showDecorations = decorations.length > 0;
  // Se separan las que alcanzan para su reserva de las que no.
  const decoReady = decorations.filter((d) => d.available);
  const decoLate = decorations.filter((d) => !d.available);
  const chosenDecoration =
    (showDecorations && decorations.find((d) => d.id === decorationId && d.available)) || null;
  // Si el cliente cambia la fecha y su decoración ya no alcanza, se suelta.
  useEffect(() => {
    if (decorationId && decorations.length > 0 && !chosenDecoration) setDecorationId("");
  }, [decorationId, decorations, chosenDecoration]);
  // La lista larga vive en una ventana aparte para no alargar el formulario.
  const [decoOpen, setDecoOpen] = useState(false);
  // Decoración cuyo detalle (tono, postre, mensaje) se está llenando.
  const [decoDetail, setDecoDetail] = useState<Decoration | null>(null);
  // Foto ampliada de la decoración que el cliente acaba de tocar
  const [zoomDeco, setZoomDeco] = useState<Decoration | null>(null);

  // Cargar configuración
  useEffect(() => {
    reservationConfig()
      .then(setCfg)
      .catch(() => setLoadErr(true));
  }, []);

  // Próximos días abiertos (chips rápidos)
  const quickDays = useMemo(() => {
    if (!cfg) return [];
    const today = todayBogota();
    const out: string[] = [];
    for (let i = 0; i < cfg.advanceDays && out.length < 8; i++) {
      const d = addDays(today, i);
      if (cfg.openDays.includes(isoDow(d))) out.push(d);
    }
    return out;
  }, [cfg]);

  // Cargar horas cuando hay fecha + personas
  const loadSlots = useCallback(async (d: string, p: number, loc: string) => {
    setLoadingSlots(true);
    setSlots(null);
    setDayClosed("");
    setTime("");
    try {
      const av = await reservationAvailability(d, p, loc);
      if (!av.open) setDayClosed(av.reason || "Ese día no recibimos reservas.");
      else setSlots(av.slots);
    } catch {
      setDayClosed("No se pudo cargar la disponibilidad. Revisa tu internet.");
    } finally {
      setLoadingSlots(false);
    }
  }, []);

  useEffect(() => {
    if (date && sedeId) loadSlots(date, party, sedeId);
  }, [date, party, sedeId, loadSlots]);

  // Si cambian fecha, hora o personas, se olvida la mesa elegida.
  useEffect(() => {
    setTableId(null);
    setTableName("");
    setZoneName("");
  }, [date, time, party, sedeId]);

  // Del paso "elige" al siguiente: si la sede tiene plano, muestra el mapa.
  const goToTables = useCallback(async () => {
    if (!date || !time || !sedeId) return;
    // Si el restaurante no permite escoger mesa, se salta el mapa.
    if (!cfg?.allowTableChoice) {
      setStep("datos");
      return;
    }
    setLoadingFloor(true);
    try {
      const f = await publicFloor(sedeId, date, time);
      setFloor(f);
      const hasTables = (f?.zones ?? []).some((z) => z.tables.length > 0);
      setStep(hasTables ? "mesa" : "datos");
    } catch {
      setStep("datos"); // si el mapa falla, se sigue sin elegir mesa
    } finally {
      setLoadingFloor(false);
    }
  }, [date, time, sedeId, cfg]);

  const pickTable = (t: PublicTable, zone: string) => {
    if (!t.available) return;
    if (tableId === t.id) {
      setTableId(null);
      setTableName("");
      setZoneName("");
    } else {
      setTableId(t.id);
      setTableName(t.name);
      setZoneName(zone);
    }
  };

  // Al salir del campo del correo miramos si ya es cliente: si lo es, lo
  // saludamos y no le pedimos el cumpleaños; si es nuevo, aparece ese campo.
  const checkEmail = async () => {
    const e = email.trim();
    if (!EMAIL_RE.test(e) || known) return;
    setChecking(true);
    try {
      const c = await checkClient(e);
      setKnown(c);
      if (c.known && c.name && !name.trim()) setName(c.name);
    } catch {
      /* si falla, se vuelve a intentar al confirmar la reserva */
    } finally {
      setChecking(false);
    }
  };

  const submit = async () => {
    setError("");
    // Los tres datos se piden siempre, en un solo bloque.
    if (!name.trim()) {
      setError("Escribe tu nombre para la reserva");
      return;
    }
    if (!phone.trim()) {
      setError("Escribe tu celular");
      return;
    }
    if (!EMAIL_RE.test(email.trim())) {
      setError("Escribe un correo válido");
      return;
    }
    // ¿Ya lo conocemos? Si no se alcanzó a verificar al salir del correo, se
    // verifica ahora: al cliente nuevo se le pide además el cumpleaños.
    let client = known;
    if (!client) {
      setChecking(true);
      try {
        client = await checkClient(email.trim());
        setKnown(client);
      } catch {
        setError("No se pudo verificar el correo. Revisa tu internet.");
        return;
      } finally {
        setChecking(false);
      }
    }
    if (!client.known && !birthday) {
      setError("Escribe tu fecha de cumpleaños");
      return;
    }
    setSending(true);
    try {
      const created = await createReservation({
        name: name.trim(),
        email: email.trim(),
        phone: fullPhone(phone),
        party,
        date,
        time,
        note: note.trim(),
        location: sedeId ?? "",
        table: tableId,
        petFriendly: pet,
        reducedMobility: mobility,
        birthday: birthday || undefined,
      });
      // Decoración de celebración (ROKA): se guarda aparte para no tocar la
      // creación de la reserva. Si falla, la reserva ya quedó igual.
      if (showDecorations && decorationId) {
        try {
          await reservationSetDecoration(created.id, decorationId, {
            color: decoColor || undefined,
            dessert: decoDessert || undefined,
            message: decoMessage.trim() || undefined,
          });
        } catch {
          /* la reserva ya se creó; la decoración se puede agregar luego */
        }
      }
      setDone(created);
      setStep("listo");
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudo crear la reserva");
    } finally {
      setSending(false);
    }
  };

  const deposit = cfg ? cfg.depositPerPerson * party : 0;

  // ── Pantalla de carga / error ──
  if (loadErr) {
    return (
      <Shell>
        <p className="mt-20 text-center text-[14px] text-ink-soft">
          No se pudieron cargar las reservas. Revisa tu internet e inténtalo de nuevo.
        </p>
      </Shell>
    );
  }
  if (!cfg) {
    return (
      <Shell>
        <p className="mt-20 text-center text-[13px] text-ink-faint">Cargando…</p>
      </Shell>
    );
  }
  if (!cfg.enabled) {
    return (
      <Shell>
        <p className="mt-20 text-center text-[14px] text-ink-soft">
          Por ahora no estamos recibiendo reservas en línea. Escríbenos por WhatsApp y con gusto te
          ayudamos.
        </p>
        <WhatsAppButton />
      </Shell>
    );
  }

  // ── Elegir sede primero (si hay varias y no ha escogido) ──
  if (sedeReady && sedes.length > 1 && !sedeId && step !== "listo") {
    return (
      <Shell title="Reservar mesa">
        <p className="mt-6 text-center font-display text-[17px] text-navy">¿En cuál sede quieres reservar?</p>
        <div className="mt-6 flex flex-col gap-4">
          {sedes.map((s) => (
            <button
              key={s.id}
              type="button"
              onClick={() => setSede(s.id)}
              className="flex items-center gap-3 border border-gold-soft bg-card px-5 py-5 text-left shadow-[0_2px_14px_rgba(4,27,49,0.08)] active:scale-[0.985]"
            >
              <svg viewBox="0 0 24 24" className="h-6 w-6 shrink-0 text-gold-deep" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" />
                <circle cx="12" cy="10" r="3" />
              </svg>
              <span>
                <span className="block font-display text-[18px] text-navy">{s.name}</span>
                {s.address && <span className="mt-0.5 block text-[11.5px] text-ink-faint">{s.address}</span>}
              </span>
            </button>
          ))}
        </div>
      </Shell>
    );
  }

  // ── Confirmación ──
  if (step === "listo" && done) {
    const clientName = name.trim() || known?.name || "";
    const firstName = clientName.split(" ")[0] || "";
    const shortDate = new Date(`${date}T12:00:00`).toLocaleDateString("es-CO", {
      day: "numeric",
      month: "long",
    });
    return (
      <Shell>
        <div className="px-1 pt-4 text-center">
          {/* Sello de confirmación */}
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-verde text-white shadow-[0_8px_22px_rgba(17,87,46,0.28)]">
            <svg viewBox="0 0 24 24" className="h-8 w-8" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <path d="M20 6 9 17l-5-5" />
            </svg>
          </div>
          <p className="smallcaps mt-4 text-[10px] text-gold-deep">Panisse</p>
          <h1 className="mt-1 font-display text-[27px] font-semibold leading-tight text-verde">
            {done.status === "confirmada" ? "¡Reserva confirmada" : "¡Reserva recibida"}
            {firstName ? `, ${firstName}` : ""}!
          </h1>
          <p className="mx-auto mt-2 max-w-[19rem] text-[13.5px] leading-relaxed text-ink-soft">
            {done.status === "confirmada" ? (
              <>
                Tu mesa quedó apartada. Te acabamos de enviar la confirmación a tu{" "}
                <b className="text-navy">correo</b>. ¡Te esperamos!
              </>
            ) : (
              <>
                Tu reserva quedó registrada. Te enviamos los detalles a tu{" "}
                <b className="text-navy">correo</b> y te confirmamos muy pronto.
              </>
            )}
          </p>

          {/* Información de la reserva, en fila de íconos */}
          <p className="smallcaps mt-6 text-[10px] text-gold-deep">Información de tu reserva</p>
          {/* La casilla de la mesa solo va si ya hay una asignada */}
          <div
            className={`mt-2 grid divide-x divide-gold-soft/40 border border-gold-soft/50 bg-paper ${tableName ? "grid-cols-4" : "grid-cols-3"}`}
          >
            <InfoCell
              d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2|M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8"
              value={`${party}`}
              label={party === 1 ? "Persona" : "Personas"}
            />
            <InfoCell
              d="M8 2v4M16 2v4M3 10h18|M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z"
              value={shortDate}
              label="Día"
            />
            <InfoCell
              d="M12 7v5l3 2|M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
              value={formatTime(time)}
              label="Hora"
            />
            {tableName && (
              <InfoCell
                d="M5 5h14a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"
                value={tableName}
                label={zoneName || "Mesa"}
              />
            )}
          </div>

          {chosenDecoration && (
            <div className="mx-auto mt-4 max-w-[20rem] border border-gold-soft/50 bg-paper px-4 py-3 text-left">
              <p className="smallcaps text-[10px] text-gold-deep">Decoración 🎉</p>
              <div className="mt-1 flex items-start gap-3">
                {chosenDecoration.image && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={chosenDecoration.image}
                    alt={`Decoración ${chosenDecoration.name}`}
                    className="h-16 w-16 shrink-0 rounded border border-gold-soft/40 object-cover"
                  />
                )}
                <div className="min-w-0">
                  <p className="text-[13.5px] font-medium text-navy">
                    {chosenDecoration.name} · {formatCOP(chosenDecoration.price)}
                  </p>
                  <p className="mt-0.5 text-[11.5px] leading-snug text-ink-soft">
                    {chosenDecoration.description}
                  </p>
                  {(decoColor || decoDessert) && (
                    <p className="mt-1 text-[11.5px] text-navy">
                      {decoColor && `Rosas ${decoColor.toLowerCase()}`}
                      {decoColor && decoDessert && " · "}
                      {decoDessert && desserts.find((p) => p.id === decoDessert)?.name}
                    </p>
                  )}
                  {decoMessage.trim() && (
                    <p className="mt-1 border-l-2 border-gold pl-1.5 text-[11.5px] italic text-gold-deep">
                      “{decoMessage.trim()}”
                    </p>
                  )}
                </div>
              </div>
              {chosenDecoration.prepaid && (
                <p className="mt-2 text-[11px] leading-relaxed text-gold-deep">
                  Te escribimos para confirmarla y cobrarla: se paga por adelantado.
                </p>
              )}
            </div>
          )}

          <p className="mx-auto mt-5 max-w-[19rem] text-[13px] leading-relaxed text-ink-soft">
            ¡Te esperamos! Revisa tu correo con los datos de tu reserva.
          </p>
          {deposit > 0 && (
            <p className="mt-2 text-[12.5px] leading-relaxed text-gold-deep">
              Para separar la mesa se pide un abono de <b>{formatCOP(deposit)}</b>. Te escribimos para
              contarte cómo pagarlo y dejar tu mesa separada.
            </p>
          )}
          <Link
            href="/"
            className="mt-5 flex h-12 w-full items-center justify-center bg-navy text-[14px] font-semibold text-gold-soft"
          >
            Volver al inicio
          </Link>
          {/* Sin botón de "confirmar": la reserva ya se envió al panel y el
              correo sale solo. Solo dejamos cómo escribirnos si hay dudas. */}
          <WhatsAppButton phone={sede?.whatsapp} label="¿Tienes alguna duda? Escríbenos" />
        </div>
      </Shell>
    );
  }

  // ── Paso: elegir mesa en el mapa ──
  if (step === "mesa") {
    return (
      <Shell onBack={() => setStep("elige")} title="Elige tu mesa">
        <div className="px-1 pt-2">
          <div className="mb-3 border-l-2 border-gold bg-gold-soft/10 px-3 py-2.5 text-[12.5px] text-ink-soft">
            {party} {party === 1 ? "persona" : "personas"} · {formatDateLabel(date)} · {formatTime(time)}
          </div>
          <p className="text-[12.5px] text-ink-faint">
            Toca una mesa libre para escogerla, o continúa y nosotros te asignamos la mejor.
          </p>
          {floor && <FloorMap floor={floor} selectedId={tableId} onPick={pickTable} />}
          {tableId && (
            <p className="mt-3 border-l-2 border-navy bg-navy/[0.03] px-3 py-2 text-[12.5px] text-navy">
              Elegiste la mesa <b>{tableName}</b>
              {zoneName ? ` · ${zoneName}` : ""}.
            </p>
          )}
          <button
            type="button"
            onClick={() => setStep("datos")}
            className="mt-5 h-12 w-full bg-navy text-[14px] font-semibold text-gold-soft transition-transform active:scale-[0.98]"
          >
            {tableId ? `Continuar con la mesa ${tableName}` : "Continuar (que me asignen mesa)"}
          </button>
        </div>
      </Shell>
    );
  }

  // ── Paso 2: datos ──
  if (step === "datos") {
    const hasMap = (floor?.zones ?? []).some((z) => z.tables.length > 0);
    return (
      <Shell onBack={() => setStep(hasMap ? "mesa" : "elige")} title="Tus datos">
        <div className="px-1 pt-3">
          <div className="mb-4 border-l-2 border-gold bg-gold-soft/10 px-3 py-2.5 text-[12.5px] text-ink-soft">
            {party} {party === 1 ? "persona" : "personas"} · {formatDateLabel(date)} ·{" "}
            {formatTime(time)}
            {tableName && <> · mesa {tableName}</>}
          </div>

          {/* Los tres datos, juntos y compactos */}
          <div className="border border-gold-soft/60 bg-paper p-3">
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Nombre y apellido"
              autoComplete="name"
              autoFocus
              className="h-11 w-full border border-gold-soft/70 bg-card px-3 text-[14px] text-ink outline-none focus:border-navy"
            />
            <div className="mt-2 flex">
              <span className="flex h-11 shrink-0 items-center gap-1.5 border border-r-0 border-gold-soft/70 bg-card px-2.5 text-[14px] text-ink-soft">
                <span aria-hidden>🇨🇴</span> +57
              </span>
              <input
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="300 000 0000"
                inputMode="tel"
                autoComplete="tel"
                className="h-11 w-full min-w-0 border border-gold-soft/70 bg-card px-3 text-[14px] text-ink outline-none focus:border-navy"
              />
            </div>
            <input
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                setKnown(null);
              }}
              onBlur={checkEmail}
              placeholder="Correo"
              type="email"
              inputMode="email"
              autoComplete="email"
              autoCapitalize="none"
              spellCheck={false}
              className="mt-2 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[14px] text-ink outline-none focus:border-navy"
            />

            {known?.known && (
              <p className="mt-2 text-[11.5px] text-verde">
                ¡Hola de nuevo{known.name ? `, ${known.name.trim().split(" ")[0]}` : ""}! 👋
              </p>
            )}

            {known && !known.known && (
              <>
                <label className="mt-2 block">
                  <span className="smallcaps text-[10px] text-gold-deep">Fecha de cumpleaños *</span>
                  <input
                    type="date"
                    value={birthday}
                    onChange={(e) => setBirthday(e.target.value)}
                    autoComplete="bday"
                    className="mt-1 h-11 w-full border border-gold-soft/70 bg-card px-3 text-[14px] text-ink outline-none focus:border-navy"
                  />
                </label>
                <p className="mt-1.5 text-[11px] leading-snug text-ink-faint">
                  Solo la primera vez, para saludarte en tu cumpleaños.
                </p>
              </>
            )}
          </div>

              <label className="mt-3 block">
                <span className="smallcaps text-[10px] text-gold-deep">Nota (opcional)</span>
                <input
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="Ej. cumpleaños, silla para bebé…"
                  className="mt-1 h-11 w-full border border-gold-soft/70 bg-paper px-3.5 text-[14px] text-ink outline-none focus:border-navy"
                />
              </label>

              {/* Mascota y movilidad, en una sola fila debajo de la nota */}
              <div className="mt-2 grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setPet((v) => !v)}
                  aria-pressed={pet}
                  className={`flex items-center justify-between gap-1.5 border px-2.5 py-2.5 text-left transition-colors ${pet ? "border-verde bg-verde/8" : "border-gold-soft/70 bg-paper"}`}
                >
                  <span className="flex min-w-0 items-center gap-1.5 text-[12px] leading-snug text-ink">
                    <span aria-hidden className="shrink-0">🐾</span>
                    <span className="min-w-0">Con mascota</span>
                  </span>
                  <span className={`smallcaps flex h-5 w-7 shrink-0 items-center justify-center border text-[9px] font-semibold ${pet ? "border-verde bg-verde text-white" : "border-gold-soft/70 text-ink-faint"}`}>
                    {pet ? "Sí" : "No"}
                  </span>
                </button>
                <button
                  type="button"
                  onClick={() => setMobility((v) => !v)}
                  aria-pressed={mobility}
                  className={`flex items-center justify-between gap-1.5 border px-2.5 py-2.5 text-left transition-colors ${mobility ? "border-verde bg-verde/8" : "border-gold-soft/70 bg-paper"}`}
                >
                  <span className="flex min-w-0 items-center gap-1.5 text-[12px] leading-snug text-ink">
                    <span aria-hidden className="shrink-0">♿</span>
                    <span className="min-w-0">Movilidad reducida</span>
                  </span>
                  <span className={`smallcaps flex h-5 w-7 shrink-0 items-center justify-center border text-[9px] font-semibold ${mobility ? "border-verde bg-verde text-white" : "border-gold-soft/70 text-ink-faint"}`}>
                    {mobility ? "Sí" : "No"}
                  </span>
                </button>
              </div>

              {/* Agregar decoración: una sola línea; la lista se abre aparte */}
              {showDecorations && (
                <button
                  type="button"
                  onClick={() => setDecoOpen(true)}
                  className="mt-4 flex w-full items-center gap-3 border border-gold-soft/60 bg-paper px-3 py-3 text-left"
                >
                  {chosenDecoration?.image ? (
                    /* eslint-disable-next-line @next/next/no-img-element */
                    <img
                      src={chosenDecoration.image}
                      alt={`Decoración ${chosenDecoration.name}`}
                      loading="lazy"
                      className="h-11 w-11 shrink-0 rounded border border-gold-soft/40 object-cover"
                    />
                  ) : (
                    <span aria-hidden className="text-[20px] leading-none">🎉</span>
                  )}
                  <span className="min-w-0 flex-1">
                    {chosenDecoration ? (
                      <>
                        <span className="block text-[13.5px] font-medium text-navy">
                          {chosenDecoration.name}
                        </span>
                        {(decoColor || decoDessert) && (
                          <span className="mt-0.5 block text-[11px] leading-snug text-ink-soft">
                            {decoColor && `Rosas ${decoColor.toLowerCase()}`}
                            {decoColor && decoDessert && " · "}
                            {decoDessert && desserts.find((p) => p.id === decoDessert)?.name}
                          </span>
                        )}
                        <span className="mt-0.5 block text-[12px] font-semibold text-gold-deep">
                          {formatCOP(
                            chosenDecoration.price +
                              (chosenDecoration.dessertMode === "optional" && decoDessert
                                ? chosenDecoration.dessertPrice
                                : 0),
                          )}
                        </span>
                      </>
                    ) : (
                      <>
                        <span className="block text-[13.5px] text-ink">¿Celebras algo?</span>
                        <span className="mt-0.5 block text-[11.5px] text-ink-faint">
                          Agrega una decoración a tu mesa (opcional)
                        </span>
                      </>
                    )}
                  </span>
                  <span className="smallcaps shrink-0 text-[10px] font-semibold text-gold-deep">
                    {chosenDecoration ? "Cambiar" : "Ver"}
                  </span>
                </button>
              )}

              {deposit > 0 && (
                <p className="mt-4 border border-gold-soft/50 bg-paper px-3 py-2.5 text-[12px] leading-relaxed text-ink-soft">
                  Para separar la mesa se pide un abono de <b>{formatCOP(deposit)}</b>. Te contamos
                  cómo pagarlo cuando confirmemos.
                </p>
              )}

              {error && <p className="mt-3 text-center text-[12.5px] text-[#b3261e]">{error}</p>}

              <button
                type="button"
                onClick={submit}
                disabled={sending}
                className="mt-4 h-12 w-full bg-navy text-[14px] font-semibold text-gold-soft disabled:opacity-60"
              >
                {sending ? "Reservando…" : checking ? "Verificando…" : "Confirmar reserva"}
              </button>
        </div>

        {/* Detalle de una decoración: tono de las rosas, postre y mensaje */}
        {decoDetail && (
          <div className="fixed inset-0 z-40 flex items-end justify-center sm:items-center" role="dialog" aria-modal="true" aria-label={`Opciones de ${decoDetail.name}`}>
            <button
              type="button"
              aria-label="Cerrar"
              onClick={() => setDecoDetail(null)}
              className="anim-fade-in absolute inset-0 bg-navy/70 backdrop-blur-[2px]"
            />
            <div className="anim-fade-up relative flex max-h-[88dvh] w-full max-w-md flex-col border border-gold-soft/60 bg-card shadow-[0_12px_40px_rgba(4,17,29,0.4)]">
              <header className="flex items-start justify-between gap-3 border-b border-gold-soft/40 px-4 py-3">
                <div className="min-w-0">
                  <p className="font-display text-[17px] leading-tight text-navy">{decoDetail.name}</p>
                  <p className="mt-0.5 text-[12px] font-semibold text-gold-deep">
                    {formatCOP(decoDetail.price)}
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => setDecoDetail(null)}
                  aria-label="Volver"
                  className="-mr-1 flex h-8 w-8 shrink-0 items-center justify-center text-ink-soft"
                >
                  <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
                    <path d="M6 6l12 12M18 6 6 18" />
                  </svg>
                </button>
              </header>

              <div className="flex-1 overflow-y-auto px-4 py-3">
                {decoDetail.image && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={decoDetail.image}
                    alt={`Decoración ${decoDetail.name}`}
                    className="max-h-[30vh] w-full rounded border border-gold-soft/40 bg-paper object-contain"
                  />
                )}
                <p className="mt-2 text-[11.5px] leading-snug text-ink-soft">{decoDetail.description}</p>

                {/* Tono de las rosas */}
                {decoDetail.colorOptions.length > 0 && (
                  <>
                    <p className="smallcaps mt-4 text-[10px] text-gold-deep">
                      {decoDetail.optionLabel || "Elige una opción"}
                    </p>
                    <div className="mt-1.5 grid grid-cols-3 gap-1.5">
                      {decoDetail.colorOptions.map((c) => (
                        <button
                          key={c}
                          type="button"
                          onClick={() => setDecoColor(c)}
                          className={`h-10 border text-[12.5px] transition-colors ${decoColor === c ? "border-navy bg-navy text-gold-soft" : "border-gold-soft/70 bg-paper text-ink"}`}
                        >
                          {c}
                        </button>
                      ))}
                    </div>
                  </>
                )}

                {/* Postre: incluido (elige cuál) u opcional (lo suma) */}
                {decoDetail.dessertMode !== "none" && desserts.length > 0 && (
                  <>
                    <p className="smallcaps mt-4 text-[10px] text-gold-deep">
                      {decoDetail.dessertMode === "included"
                        ? "Postre incluido · elige cuál"
                        : `Agregar postre · ${formatCOP(decoDetail.dessertPrice)}`}
                    </p>
                    <div className="mt-1.5 flex flex-col gap-1.5">
                      {decoDetail.dessertMode === "optional" && (
                        <button
                          type="button"
                          onClick={() => setDecoDessert("")}
                          className={`flex h-10 items-center justify-between border px-3 text-left text-[12.5px] transition-colors ${decoDessert === "" ? "border-navy bg-navy/[0.04]" : "border-gold-soft/70 bg-paper"}`}
                        >
                          <span className="text-ink">Sin postre</span>
                          <span className={`h-4 w-4 shrink-0 rounded-full border ${decoDessert === "" ? "border-navy bg-navy" : "border-gold-soft/70"}`} />
                        </button>
                      )}
                      {desserts.map((p) => (
                        <button
                          key={p.id}
                          type="button"
                          onClick={() => setDecoDessert(p.id)}
                          className={`flex items-center gap-2.5 border px-3 py-2 text-left transition-colors ${decoDessert === p.id ? "border-navy bg-navy/[0.04]" : "border-gold-soft/70 bg-paper"}`}
                        >
                          {p.image && (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img
                              src={p.image}
                              alt={p.name}
                              loading="lazy"
                              className="h-12 w-12 shrink-0 rounded border border-gold-soft/40 bg-card object-cover"
                            />
                          )}
                          <span className="min-w-0 flex-1 text-[12.5px] text-ink">{p.name}</span>
                          <span className={`h-4 w-4 shrink-0 rounded-full border ${decoDessert === p.id ? "border-navy bg-navy" : "border-gold-soft/70"}`} />
                        </button>
                      ))}
                    </div>
                  </>
                )}

                {/* Mensaje de la tarjeta */}
                <label className="mt-4 block">
                  <span className="smallcaps text-[10px] text-gold-deep">Mensaje de la tarjeta</span>
                  <textarea
                    value={decoMessage}
                    onChange={(e) => setDecoMessage(e.target.value.slice(0, 200))}
                    rows={3}
                    placeholder="Ej. Feliz aniversario, mi amor…"
                    className="mt-1 w-full resize-none border border-gold-soft/70 bg-paper px-3 py-2 text-[14px] text-ink outline-none focus:border-navy"
                  />
                  <span className="mt-0.5 block text-right text-[10px] text-ink-faint">
                    {decoMessage.length}/200
                  </span>
                </label>
              </div>

              <footer className="border-t border-gold-soft/40 px-4 py-3">
                <button
                  type="button"
                  onClick={() => {
                    setDecorationId(decoDetail.id);
                    setDecoDetail(null);
                    setDecoOpen(false);
                  }}
                  className="h-11 w-full bg-navy text-[13.5px] font-semibold text-gold-soft"
                >
                  Agregar ·{" "}
                  {formatCOP(
                    decoDetail.price +
                      (decoDetail.dessertMode === "optional" && decoDessert
                        ? decoDetail.dessertPrice
                        : 0),
                  )}
                </button>
              </footer>
            </div>
          </div>
        )}

        {/* Ventana con las decoraciones, para no alargar el formulario */}
        {decoOpen && !decoDetail && (
          <div className="fixed inset-0 z-40 flex items-end justify-center sm:items-center" role="dialog" aria-modal="true" aria-label="Elegir decoración">
            <button
              type="button"
              aria-label="Cerrar"
              onClick={() => setDecoOpen(false)}
              className="anim-fade-in absolute inset-0 bg-navy/70 backdrop-blur-[2px]"
            />
            <div className="anim-fade-up relative flex max-h-[88dvh] w-full max-w-md flex-col border border-gold-soft/60 bg-card shadow-[0_12px_40px_rgba(4,17,29,0.4)]">
              <header className="flex items-start justify-between gap-3 border-b border-gold-soft/40 px-4 py-3">
                <div className="min-w-0">
                  <p className="font-display text-[17px] leading-tight text-navy">Decoraciones 🎉</p>
                  <p className="mt-0.5 text-[11.5px] leading-snug text-ink-faint">
                    Se pagan aparte de la comida. Te confirmamos la disponibilidad.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => setDecoOpen(false)}
                  aria-label="Cerrar"
                  className="-mr-1 flex h-8 w-8 shrink-0 items-center justify-center text-ink-soft"
                >
                  <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
                    <path d="M6 6l12 12M18 6 6 18" />
                  </svg>
                </button>
              </header>

              <div className="flex-1 overflow-y-auto px-4 py-3">
                {/* Primero las que sí alcanzan para su reserva; después, las
                    que necesitan más tiempo, para que se entienda por qué. */}
                {decoReady.length > 0 && decoLate.length > 0 && (
                  <p className="smallcaps mb-1.5 text-[10px] text-verde">
                    Puedes pedir ahora
                  </p>
                )}
                <div className="flex flex-col gap-2">
                  {[...decoReady, ...decoLate].map((d, i) => (
                    <div key={`w-${d.id}`} className="contents">
                    {i === decoReady.length && decoReady.length > 0 && (
                      <p className="smallcaps mb-0.5 mt-3 text-[10px] text-ink-faint">
                        Necesitan más tiempo
                      </p>
                    )}
                    <button
                      key={d.id}
                      type="button"
                      disabled={!d.available}
                      onClick={() => {
                        // Con opciones (tono, postre, mensaje) se abre su detalle;
                        // si no tiene, se elige de una.
                        if (hasOptions(d)) {
                          setDecoColor(d.colorOptions[0] ?? "");
                          setDecoDessert(d.dessertMode === "included" ? desserts[0]?.id ?? "" : "");
                          setDecoMessage("");
                          setDecoDetail(d);
                        } else {
                          setDecorationId(d.id);
                          setDecoOpen(false);
                        }
                      }}
                      className={`flex items-start gap-2.5 border px-3 py-2.5 text-left transition-colors ${
                        !d.available
                          ? "border-gold-soft/40 bg-paper-deep/60"
                          : decorationId === d.id
                            ? "border-navy bg-navy/[0.04]"
                            : "border-gold-soft/70 bg-paper"
                      }`}
                    >
                      {d.image && (
                        // Tocar la foto la abre en grande; tocar el resto elige.
                        <span
                          role="button"
                          tabIndex={0}
                          aria-label={`Ver la foto de ${d.name} en grande`}
                          onClick={(e) => {
                            e.stopPropagation();
                            setZoomDeco(d);
                          }}
                          onKeyDown={(e) => {
                            if (e.key === "Enter" || e.key === " ") {
                              e.preventDefault();
                              e.stopPropagation();
                              setZoomDeco(d);
                            }
                          }}
                          className="relative h-16 w-16 shrink-0"
                        >
                          {/* eslint-disable-next-line @next/next/no-img-element */}
                          <img
                            src={d.image}
                            alt={`Decoración ${d.name}`}
                            loading="lazy"
                            className="h-16 w-16 rounded border border-gold-soft/40 object-cover"
                          />
                          <span className="absolute bottom-0.5 right-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-navy/80 text-gold-soft" aria-hidden>
                            <svg viewBox="0 0 24 24" className="h-3 w-3" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
                              <circle cx="11" cy="11" r="7" />
                              <path d="m20 20-3.5-3.5M11 8v6M8 11h6" />
                            </svg>
                          </span>
                        </span>
                      )}
                      <span className="min-w-0 flex-1">
                        <span className="block text-[13.5px] font-medium text-navy">{d.name}</span>
                        <span className="mt-0.5 block text-[11px] leading-snug text-ink-soft">{d.description}</span>
                        <span className="mt-1 block text-[12.5px] font-semibold text-gold-deep">{formatCOP(d.price)}</span>
                        {d.available ? (
                          (antelacion(d) || d.prepaid) && (
                            <span className="mt-1 block text-[10.5px] leading-snug text-ink-faint">
                              {antelacion(d) && `Se pide con ${antelacion(d)} de anticipación`}
                              {antelacion(d) && d.prepaid && " · "}
                              {d.prepaid && "Se paga por adelantado"}
                            </span>
                          )
                        ) : (
                          <span className="mt-1 block text-[10.5px] font-medium leading-snug text-[#b3261e]">
                            Para esa hora ya no alcanza: se pide con {antelacion(d)} de
                            anticipación.
                          </span>
                        )}
                      </span>
                      {d.available && (
                        <span className={`mt-0.5 h-4 w-4 shrink-0 rounded-full border ${decorationId === d.id ? "border-navy bg-navy" : "border-gold-soft/70"}`} />
                      )}
                    </button>
                    </div>
                  ))}
                </div>
              </div>

              <footer className="border-t border-gold-soft/40 px-4 py-3">
                {/* Si algo no alcanza para esa fecha, se ofrece WhatsApp */}
                {decorations.some((d) => !d.available) && (
                  <a
                    href={`https://wa.me/${(sede?.whatsapp || restaurant.whatsapp).replace(/\D/g, "")}?text=${encodeURIComponent(
                      `Hola, quiero una decoración para mi reserva del ${formatDateLabel(date)} y es para pronto. ¿Se puede organizar?`,
                    )}`}
                    className="mb-2 flex h-11 w-full items-center justify-center border border-verde bg-verde/5 text-[12.5px] font-semibold text-verde"
                  >
                    ¿La quieres para hoy o mañana? Escríbenos
                  </a>
                )}
                <button
                  type="button"
                  onClick={() => {
                    setDecorationId("");
                    setDecoOpen(false);
                  }}
                  className="h-11 w-full border border-gold-soft/70 bg-paper text-[13.5px] font-semibold text-navy"
                >
                  Sin decoración
                </button>
              </footer>
            </div>
          </div>
        )}

        {/* Foto grande de la decoración elegida */}
        {zoomDeco?.image && (
          <div
            className="fixed inset-0 z-50 flex items-center justify-center p-4"
            role="dialog"
            aria-modal="true"
            aria-label={`Foto de la decoración ${zoomDeco.name}`}
          >
            <button
              type="button"
              aria-label="Cerrar"
              onClick={() => setZoomDeco(null)}
              className="anim-fade-in absolute inset-0 bg-navy/70 backdrop-blur-[2px]"
            />
            <div className="anim-fade-up relative w-full max-w-sm overflow-hidden border border-gold-soft/60 bg-card shadow-[0_12px_40px_rgba(4,17,29,0.4)]">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={zoomDeco.image}
                alt={`Decoración ${zoomDeco.name}`}
                className="max-h-[58vh] w-full bg-navy object-contain"
              />
              <button
                type="button"
                onClick={() => setZoomDeco(null)}
                aria-label="Cerrar"
                className="absolute right-2 top-2 flex h-9 w-9 items-center justify-center rounded-full bg-navy/70 text-gold-soft"
              >
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
                  <path d="M6 6l12 12M18 6 6 18" />
                </svg>
              </button>
              <div className="px-4 py-3.5">
                <p className="font-display text-[18px] text-navy">{zoomDeco.name}</p>
                <p className="mt-0.5 text-[12px] leading-snug text-ink-soft">{zoomDeco.description}</p>
                <p className="mt-1 text-[14px] font-semibold text-gold-deep">{formatCOP(zoomDeco.price)}</p>
                {decorationId === zoomDeco.id ? (
                  <>
                    <p className="mt-2 flex items-center gap-1.5 text-[12px] font-medium text-verde">
                      <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                        <path d="M20 6 9 17l-5-5" />
                      </svg>
                      Elegiste esta decoración
                    </p>
                    <button
                      type="button"
                      onClick={() => setZoomDeco(null)}
                      className="mt-3 h-11 w-full bg-navy text-[14px] font-semibold text-gold-soft"
                    >
                      Listo
                    </button>
                  </>
                ) : (
                  <>
                    <button
                      type="button"
                      onClick={() => {
                        setDecorationId(zoomDeco.id);
                        setZoomDeco(null);
                        setDecoOpen(false);
                      }}
                      className="mt-3 h-11 w-full bg-navy text-[14px] font-semibold text-gold-soft"
                    >
                      Elegir esta decoración
                    </button>
                    <button
                      type="button"
                      onClick={() => setZoomDeco(null)}
                      className="mt-2 h-11 w-full border border-gold-soft/70 bg-paper text-[13.5px] font-semibold text-navy"
                    >
                      Volver
                    </button>
                  </>
                )}
              </div>
            </div>
          </div>
        )}
      </Shell>
    );
  }

  // ── Paso 1: personas + fecha + hora ──
  const maxDate = addDays(todayBogota(), cfg.advanceDays);
  return (
    <Shell title="Reservar mesa">
      <div className="px-1 pt-2">
        {sede && sedes.length > 1 && (
          <p className="mt-1 flex items-center justify-center gap-1.5 text-[12px] text-ink-soft">
            <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 text-gold-deep" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" />
              <circle cx="12" cy="10" r="3" />
            </svg>
            <span className="font-medium text-navy">{sede.name}</span>
          </p>
        )}
        {/* Personas */}
        <section className="mt-3">
          <h2 className="font-display text-[17px] text-navy">Personas</h2>
          <div className="mt-3 flex flex-wrap gap-2.5">
            {Array.from({ length: cfg.maxParty }, (_, i) => i + 1).map((n) => (
              <button
                key={n}
                type="button"
                onClick={() => setParty(n)}
                className={`flex h-12 w-12 items-center justify-center rounded-full border text-[16px] font-medium transition-colors ${
                  party === n
                    ? "border-navy bg-navy text-gold-soft"
                    : "border-gold-soft/70 bg-card text-ink-soft"
                }`}
              >
                {n}
              </button>
            ))}
          </div>
          <p className="mt-2.5 text-[11.5px] text-ink-faint">
            ¿Grupo más grande o evento?{" "}
            <a
              href={`https://wa.me/${restaurant.whatsapp.replace(/\D/g, "")}`}
              target="_blank"
              rel="noopener noreferrer"
              className="font-medium text-gold-deep underline"
            >
              Escríbenos
            </a>
          </p>
        </section>

        {/* Fecha */}
        <section className="mt-7">
          <h2 className="font-display text-[17px] text-navy">Fecha</h2>
          <div className="chips-scroll -mx-1 mt-3 flex gap-2 overflow-x-auto px-1 pb-1">
            {quickDays.map((d) => (
              <button
                key={d}
                type="button"
                onClick={() => setDate(d)}
                className={`flex h-16 w-16 shrink-0 flex-col items-center justify-center rounded-lg border text-center transition-colors ${
                  date === d
                    ? "border-navy bg-navy text-gold-soft"
                    : "border-gold-soft/70 bg-card text-ink-soft"
                }`}
              >
                <span className="smallcaps text-[9px] opacity-80">{formatDateLabel(d).split(" ")[0]}</span>
                <span className="font-display text-[19px] leading-none">{d.split("-")[2]}</span>
              </button>
            ))}
          </div>
          <label className="mt-3 flex items-center gap-2 text-[12.5px] text-ink-soft">
            <span className="smallcaps text-[10px] text-gold-deep">Otra fecha</span>
            <input
              type="date"
              value={date}
              min={todayBogota()}
              max={maxDate}
              onChange={(e) => setDate(e.target.value)}
              className="h-11 flex-1 border border-gold-soft/70 bg-paper px-3 text-[14px] text-ink outline-none focus:border-navy"
            />
          </label>
        </section>

        {/* Hora */}
        {date && (
          <section className="mt-7">
            <h2 className="font-display text-[17px] text-navy">Hora</h2>
            {loadingSlots ? (
              <p className="mt-4 text-center text-[13px] text-ink-faint">Cargando horas…</p>
            ) : dayClosed ? (
              <p className="mt-4 border-l-2 border-gold bg-gold-soft/10 px-3 py-2.5 text-[13px] text-ink-soft">
                {dayClosed}
              </p>
            ) : slots ? (
              slots.some((s) => s.available) ? (
                <>
                  <div className="mt-3 grid grid-cols-3 gap-2">
                    {slots.map((s) => (
                      <button
                        key={s.time}
                        type="button"
                        disabled={!s.available}
                        onClick={() => setTime(s.time)}
                        className={`h-11 rounded-lg border text-[13.5px] transition-colors ${
                          time === s.time
                            ? "border-navy bg-navy text-gold-soft"
                            : s.available
                              ? "border-gold-soft/70 bg-card text-ink-soft"
                              : "cursor-not-allowed border-gold-soft/20 bg-paper-deep/40 text-ink-faint/40 line-through"
                        }`}
                      >
                        {formatTime(s.time)}
                      </button>
                    ))}
                  </div>
                  <div className="mt-3 flex items-center gap-4 text-[10.5px] text-ink-faint">
                    <span className="flex items-center gap-1.5">
                      <span className="h-3 w-3 rounded border border-gold-soft/70 bg-card" /> Disponible
                    </span>
                    <span className="flex items-center gap-1.5">
                      <span className="h-3 w-3 rounded border border-gold-soft/20 bg-paper-deep/40" /> Ocupada
                    </span>
                  </div>
                </>
              ) : (
                <p className="mt-4 border-l-2 border-gold bg-gold-soft/10 px-3 py-2.5 text-[13px] text-ink-soft">
                  No quedan horas disponibles ese día. Prueba con otra fecha.
                </p>
              )
            ) : null}
          </section>
        )}

        <button
          type="button"
          disabled={!date || !time || loadingFloor}
          onClick={goToTables}
          className="mt-8 h-12 w-full bg-navy text-[14px] font-semibold text-gold-soft transition-transform active:scale-[0.98] disabled:opacity-50"
        >
          {loadingFloor ? "Cargando…" : "Continuar"}
        </button>
      </div>
    </Shell>
  );
}

// ── Mapa del salón: el cliente toca una mesa libre ──
function FloorMap({
  floor,
  selectedId,
  onPick,
}: {
  floor: PublicFloor;
  selectedId: string | null;
  onPick: (t: PublicTable, zone: string) => void;
}) {
  return (
    <div className="mt-3 flex flex-col gap-5">
      {floor.zones.map((z) => {
        const cw = Math.max(320, ...z.tables.map((t) => t.posX + t.width)) + 20;
        const ch = Math.max(180, ...z.tables.map((t) => t.posY + t.height)) + 20;
        return (
          <div key={z.id}>
            <h3 className="smallcaps text-[11px] font-semibold text-gold-deep">{z.name}</h3>
            <div className="mt-1.5 overflow-x-auto rounded border border-gold-soft/40 bg-[repeating-linear-gradient(0deg,transparent,transparent_23px,rgba(4,17,29,0.04)_24px),repeating-linear-gradient(90deg,transparent,transparent_23px,rgba(4,17,29,0.04)_24px)]">
              <div className="relative" style={{ width: cw, height: ch }}>
                {z.tables.map((t) => {
                  const selected = selectedId === t.id;
                  const style: React.CSSProperties = {
                    left: t.posX,
                    top: t.posY,
                    width: t.width,
                    height: t.height,
                    borderRadius: t.shape === "round" ? "9999px" : "8px",
                  };
                  const cls = selected
                    ? "border-navy bg-navy text-gold-soft"
                    : t.available
                      ? "border-verde/60 bg-card text-navy hover:bg-verde/5"
                      : "cursor-not-allowed border-gold-soft/25 bg-paper-deep/50 text-ink-faint/50";
                  return (
                    <button
                      key={t.id}
                      type="button"
                      disabled={!t.available}
                      onClick={() => onPick(t, z.name)}
                      style={style}
                      className={`absolute flex flex-col items-center justify-center border text-center ${cls}`}
                    >
                      <span className="font-display text-[15px] leading-none">{t.name}</span>
                      <span className="mt-0.5 text-[9px] opacity-80">{t.seats} pers.</span>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        );
      })}
      <div className="flex items-center gap-4 text-[10.5px] text-ink-faint">
        <span className="flex items-center gap-1.5">
          <span className="h-3 w-3 rounded border border-verde/60 bg-card" /> Libre
        </span>
        <span className="flex items-center gap-1.5">
          <span className="h-3 w-3 rounded border border-gold-soft/25 bg-paper-deep/50" /> Ocupada
        </span>
      </div>
    </div>
  );
}

// ── Envoltura con marca ──
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
            <Link
              href="/"
              aria-label="Inicio"
              className="flex h-9 w-9 items-center justify-center rounded-full text-ink-soft active:bg-paper-deep"
            >
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                <path d="M15 5l-7 7 7 7" />
              </svg>
            </Link>
          )}
          <p className="smallcaps text-[10px] text-gold-deep">PANISSE</p>
          <span className="w-9" />
        </header>
        {title && (
          <h1 className="mt-1 text-center font-display text-[24px] text-navy">{title}</h1>
        )}
        {children}
      </div>
    </div>
  );
}

// Celda de la fila de información de la confirmación (ícono + valor + etiqueta).
function InfoCell({ d, value, label }: { d: string; value: string; label: string }) {
  return (
    <div className="flex flex-col items-center gap-1 px-1 py-3.5 text-center">
      <svg
        viewBox="0 0 24 24"
        className="h-5 w-5 text-gold-deep"
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
      <span className="font-display text-[14px] font-medium leading-tight text-navy">{value}</span>
      <span className="smallcaps text-[7.5px] text-ink-faint">{label}</span>
    </div>
  );
}

function WhatsAppButton({ text, label, phone }: { text?: string; label?: string; phone?: string }) {
  const number = (phone || restaurant.whatsapp).replace(/\D/g, "");
  const href = `https://wa.me/${number}${text ? `?text=${encodeURIComponent(text)}` : ""}`;
  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      className="mt-4 flex h-12 w-full items-center justify-center gap-2 bg-verde text-[14px] font-semibold text-white"
    >
      <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor" aria-hidden>
        <path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2Zm0 18.2c-1.5 0-3-.4-4.2-1.1l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2Zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8-.2-.1-.4-.1-.6.1-.2.2-.6.8-.8 1-.1.2-.3.2-.5.1a6.7 6.7 0 0 1-3.4-3c-.3-.4 0-.5.1-.7l.4-.5c.1-.2.2-.3.3-.5v-.5c0-.1-.5-1.4-.7-1.9-.2-.5-.4-.4-.6-.4h-.5c-.2 0-.5.1-.7.3-.2.3-.9.9-.9 2.2s.9 2.5 1.1 2.7c.1.2 1.9 2.9 4.6 4a15 15 0 0 0 1.5.6c.6.2 1.2.2 1.7.1.5-.1 1.5-.6 1.7-1.2.2-.6.2-1.1.2-1.2l-.4-.3Z" />
      </svg>
      {label || "WhatsApp"}
    </a>
  );
}

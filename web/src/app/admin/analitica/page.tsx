"use client";

// Analítica: KPIs y gráficas sobre visitas al menú, productos más vistos
// y más pedidos, horarios y dispositivos. Datos de la tabla de eventos
// y de los pedidos en Supabase, agregados por staff_analytics.
import { useCallback, useEffect, useState } from "react";
import { isAuthError, staffAnalytics, type Analytics } from "@/lib/admin";
import { useStaff } from "@/components/admin/AdminShell";
import { formatCOP } from "@/lib/format";

const RANGES = [
  { key: "hoy", label: "Hoy", days: 1 },
  { key: "7d", label: "7 días", days: 7 },
  { key: "30d", label: "30 días", days: 30 },
  { key: "90d", label: "90 días", days: 90 },
];

function bogotaToday(): Date {
  const s = new Date().toLocaleDateString("en-CA", { timeZone: "America/Bogota" });
  return new Date(s + "T12:00:00");
}

function iso(d: Date): string {
  return d.toISOString().slice(0, 10);
}

// ── Gráfica de barras vertical (SVG puro) ──
function Bars({
  values,
  labels,
  labelEvery = 1,
  height = 120,
  format = (v: number) => String(v),
}: {
  values: number[];
  labels: string[];
  labelEvery?: number;
  height?: number;
  format?: (v: number) => string;
}) {
  const max = Math.max(1, ...values);
  const n = values.length;
  const W = 100;
  const gap = n > 40 ? 0.4 : 1;
  const bw = (W - gap * (n - 1)) / n;
  const H = 100;
  const [hover, setHover] = useState<number | null>(null);

  return (
    <div>
      <svg
        viewBox={`0 0 ${W} ${H}`}
        preserveAspectRatio="none"
        style={{ height }}
        className="block w-full"
        role="img"
        aria-label="Gráfica de barras"
      >
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
            <span key={i} className="flex-1 text-center">
              {l}
            </span>
          ) : (
            <span key={i} className="flex-1" />
          ),
        )}
      </div>
      <p className="mt-1 text-center text-[10.5px] text-ink-soft">
        {hover != null
          ? `${labels[hover]}: ${format(values[hover])}`
          : `Máximo: ${format(max === 1 && values.every((v) => v === 0) ? 0 : max)}`}
      </p>
    </div>
  );
}

// ── Lista con barras horizontales ──
function HBarList({
  items,
  format = (v: number) => String(v),
}: {
  items: { name: string; value: number; extra?: string }[];
  format?: (v: number) => string;
}) {
  const max = Math.max(1, ...items.map((i) => i.value));
  if (items.length === 0)
    return <p className="py-6 text-center text-[12px] text-ink-faint">Sin datos en este rango.</p>;
  return (
    <ul className="flex flex-col gap-2">
      {items.map((it, i) => (
        <li key={i}>
          <div className="flex items-baseline justify-between gap-2 text-[12px]">
            <span className="min-w-0 truncate text-ink">{it.name}</span>
            <span className="shrink-0 font-medium text-navy">
              {format(it.value)}
              {it.extra && <span className="ml-1 text-[10.5px] text-ink-faint">{it.extra}</span>}
            </span>
          </div>
          <div className="mt-0.5 h-1.5 bg-paper-deep">
            <div className="h-full bg-gold-deep/80" style={{ width: `${(it.value / max) * 100}%` }} />
          </div>
        </li>
      ))}
    </ul>
  );
}

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="border border-gold-soft/50 bg-card px-4 py-3.5">
      <h3 className="smallcaps mb-3 text-[10px] font-semibold text-gold-deep">{title}</h3>
      {children}
    </section>
  );
}

const DOW_LABELS = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];

export default function AnaliticaPage() {
  const { code, logout } = useStaff();
  const [range, setRange] = useState("7d");
  const [data, setData] = useState<Analytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    const days = RANGES.find((r) => r.key === range)?.days ?? 7;
    const to = bogotaToday();
    const from = new Date(to);
    from.setDate(from.getDate() - (days - 1));
    setLoading(true);
    try {
      setData(await staffAnalytics(code, iso(from), iso(to)));
      setError("");
    } catch (e) {
      if (isAuthError(e)) logout();
      else setError("No se pudo cargar la analítica. Revisa tu internet.");
    } finally {
      setLoading(false);
    }
  }, [code, range, logout]);

  useEffect(() => {
    load();
  }, [load]);

  const kpis = data?.kpis;
  const conversion =
    kpis && kpis.menuVisits > 0 ? Math.round((kpis.orders / kpis.menuVisits) * 100) : null;

  const dow = Array.from({ length: 7 }, (_, i) => {
    const found = data?.visitsByDow.find((d) => d.dow === i + 1);
    return found?.visits ?? 0;
  });
  const hours = Array.from({ length: 24 }, (_, h) => {
    const found = data?.visitsByHour.find((d) => d.hour === h);
    return found?.visits ?? 0;
  });
  const days = data?.visitsByDay ?? [];

  return (
    <div className="mx-auto max-w-5xl">
      <h1 className="mt-3 hidden font-display text-[20px] text-navy lg:block">Analítica</h1>
      <div className="chips-scroll -mx-1 mt-3 flex gap-1.5 overflow-x-auto px-1">
        {RANGES.map((r) => (
          <button
            key={r.key}
            type="button"
            onClick={() => setRange(r.key)}
            className={`smallcaps h-9 shrink-0 border px-4 text-[10.5px] font-medium ${
              r.key === range
                ? "border-navy bg-navy text-gold-soft"
                : "border-gold-soft/60 bg-card text-ink-soft"
            }`}
          >
            {r.label}
          </button>
        ))}
      </div>

      {error && <p className="mt-4 text-center text-[12.5px] text-[#b3261e]">{error}</p>}
      {loading && !data && (
        <p className="mt-16 text-center text-[13px] text-ink-faint">Cargando…</p>
      )}

      {data && kpis && (
        <div className={loading ? "opacity-60" : ""}>
          {/* KPIs */}
          <div className="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-6">
            {[
              ["Visitas al menú", String(kpis.menuVisits)],
              ["Sesiones", String(kpis.sessions)],
              ["Vistas de producto", String(kpis.productViews)],
              ["Pedidos", String(kpis.orders)],
              ["Ingresos por pedidos", formatCOP(kpis.revenue)],
              ["Conversión visita→pedido", conversion != null ? `${conversion}%` : "—"],
            ].map(([label, value]) => (
              <div key={label} className="border border-gold-soft/50 bg-card px-3 py-3">
                <p className="smallcaps text-[9px] text-gold-deep">{label}</p>
                <p className="mt-1 font-display text-[22px] leading-none text-navy">{value}</p>
              </div>
            ))}
          </div>

          <div className="mt-3 flex flex-col gap-3">
            <Card title="Visitas al menú por día">
              <Bars
                values={days.map((d) => d.visits)}
                labels={days.map((d) => d.day.slice(8))}
                labelEvery={days.length > 14 ? Math.ceil(days.length / 10) : 1}
              />
            </Card>

            <Card title="Ingresos por día (pedidos)">
              <Bars
                values={days.map((d) => d.revenue)}
                labels={days.map((d) => d.day.slice(8))}
                labelEvery={days.length > 14 ? Math.ceil(days.length / 10) : 1}
                format={(v) => formatCOP(v)}
              />
            </Card>

            <div className="grid gap-3 sm:grid-cols-2">
              <Card title="Visitas por día de la semana">
                <Bars values={dow} labels={DOW_LABELS} />
              </Card>
              <Card title="Visitas por hora del día">
                <Bars
                  values={hours}
                  labels={hours.map((_, h) => `${h}`)}
                  labelEvery={3}
                  height={100}
                />
              </Card>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Card title="Productos más pedidos">
                <HBarList
                  items={data.topProductsOrders.map((p) => ({
                    name: p.name,
                    value: p.qty,
                    extra: formatCOP(p.revenue),
                  }))}
                />
              </Card>
              <Card title="Productos más vistos">
                <HBarList
                  items={data.topProductsViews.map((p) => ({ name: p.name, value: p.views }))}
                />
              </Card>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Card title="Categorías más vistas">
                <HBarList
                  items={data.topCategories.map((c) => ({ name: c.name, value: c.views }))}
                />
              </Card>
              <div className="flex flex-col gap-3">
                <Card title="Visitas por carta">
                  <HBarList
                    items={data.menuVisits.map((m) => ({ name: m.menu, value: m.visits }))}
                  />
                </Card>
                <Card title="Dispositivos (sesiones)">
                  <HBarList
                    items={data.devices.map((d) => ({
                      name: d.device === "movil" ? "Móvil" : d.device === "escritorio" ? "Escritorio" : "Otro",
                      value: d.sessions,
                    }))}
                  />
                </Card>
              </div>
            </div>
          </div>

          <p className="mt-4 text-center text-[10.5px] text-ink-faint">
            Zona horaria: Bogotá · Los datos se registran desde la carta pública en tiempo real.
          </p>
        </div>
      )}
    </div>
  );
}

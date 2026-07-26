"use client";

// Botón "Excel": descarga lo que se está viendo como archivo para abrir
// en Excel. Se usa igual en todas las pantallas del panel.

import { downloadCsv, type CsvValue } from "@/lib/csv";

export default function ExportButton({
  name,
  headers,
  rows,
  label = "Excel",
  className = "",
}: {
  /** Nombre del archivo, sin fecha ni extensión (se agregan solas). */
  name: string;
  headers: string[];
  rows: CsvValue[][];
  label?: string;
  className?: string;
}) {
  const vacío = rows.length === 0;
  return (
    <button
      type="button"
      disabled={vacío}
      title={vacío ? "No hay datos para exportar" : "Descargar para abrir en Excel"}
      onClick={() => downloadCsv(name, headers, rows)}
      className={`smallcaps flex h-9 shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full border px-3 text-[10.5px] font-medium disabled:opacity-40 ${
        vacío ? "border-gold-soft/40 text-ink-faint" : "border-verde/50 bg-verde/10 text-verde"
      } ${className}`}
    >
      <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <path d="M12 3v12m0 0 4-4m-4 4-4-4" />
        <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" />
      </svg>
      {label}
    </button>
  );
}

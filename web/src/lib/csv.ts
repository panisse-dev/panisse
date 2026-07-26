// Exportar tablas del panel a un archivo que abre Excel (Windows).
//
// Tres cosas lo hacen abrir bien de doble clic:
//   · punto y coma como separador (lo que espera Excel en español),
//   · la línea "sep=;" al inicio, que se lo dice a Excel explícitamente
//     por si el computador está configurado en inglés,
//   · la marca UTF-8, para que las tildes y la ñ no salgan rotas.

export type CsvValue = string | number | boolean | null | undefined;

function cell(v: CsvValue): string {
  if (v === null || v === undefined) return "";
  if (typeof v === "boolean") return v ? "Sí" : "No";
  const s = String(v);
  // Excel interpreta como fórmula lo que empiece por = + - @: se neutraliza.
  const safe = /^[=+\-@]/.test(s) ? `'${s}` : s;
  return /[";\n]/.test(safe) ? `"${safe.replace(/"/g, '""')}"` : safe;
}

export function toCsv(headers: string[], rows: CsvValue[][]): string {
  return [headers.map(cell).join(";"), ...rows.map((r) => r.map(cell).join(";"))].join("\r\n");
}

/** Descarga la tabla como archivo. `name` sin extensión. */
export function downloadCsv(name: string, headers: string[], rows: CsvValue[][]) {
  // ﻿ = marca UTF-8 · "sep=;" = separador explícito para Excel
  const csv = "﻿sep=;\r\n" + toCsv(headers, rows);
  const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8;" }));
  const a = document.createElement("a");
  a.href = url;
  // Si el nombre ya trae fecha (p. ej. "reservas-2026-07-25"), no se repite.
  const hoy = new Date().toLocaleDateString("en-CA", { timeZone: "America/Bogota" });
  a.download = /\d{4}-\d{2}-\d{2}$/.test(name) ? `${name}.csv` : `${name}-${hoy}.csv`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

/** Fecha y hora legibles para las columnas de los reportes. */
export const csvDateTime = (iso: string | null | undefined): string =>
  iso
    ? new Date(iso).toLocaleString("es-CO", {
        timeZone: "America/Bogota",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
      })
    : "";

// Client-safe helpers (no data imports — keeps the menu JSON out of the JS bundle)
export function formatCOP(value: number): string {
  return "$" + value.toLocaleString("es-CO");
}

export function normalize(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "");
}

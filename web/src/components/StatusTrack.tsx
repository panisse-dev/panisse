import { STATUS_LABEL, type OrderStatus } from "@/lib/orders";

// Barra de progreso del pedido: Recibido → En preparación → Listo para recoger
export default function StatusTrack({ status }: { status: OrderStatus }) {
  const steps: OrderStatus[] = ["recibido", "preparacion", "listo"];
  const active = status === "recogido" ? 2 : steps.indexOf(status);
  return (
    <div className="mt-3 flex items-center">
      {steps.map((s, i) => (
        <div key={s} className="flex flex-1 flex-col items-center">
          <div className="flex w-full items-center">
            <span className={`h-0.5 flex-1 ${i === 0 ? "opacity-0" : i <= active ? "bg-verde" : "bg-gold-soft/40"}`} />
            <span
              className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-[11px] ${
                i <= active ? "bg-verde text-white" : "bg-gold-soft/30 text-ink-faint"
              }`}
            >
              {i < active || status === "recogido" ? "✓" : i + 1}
            </span>
            <span className={`h-0.5 flex-1 ${i === steps.length - 1 ? "opacity-0" : i < active ? "bg-verde" : "bg-gold-soft/40"}`} />
          </div>
          <span className={`mt-1.5 text-center text-[10px] leading-tight ${i <= active ? "text-navy" : "text-ink-faint"}`}>
            {STATUS_LABEL[s]}
          </span>
        </div>
      ))}
    </div>
  );
}

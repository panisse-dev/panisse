"use client";

// Lista que se reordena arrastrando, con el dedo o con el mouse.
//
// Se agarra por la manija (⠿) para no pelear con el toque normal de la
// fila (que abre el plato) ni con el desplazamiento de la página. Mientras
// se arrastra, la lista se reacomoda en vivo; al soltar, se guarda el
// orden completo.

import { useRef, useState, type ReactNode } from "react";

export interface SortableItem {
  id: string;
}

export default function Sortable<T extends SortableItem>({
  items,
  onReorder,
  className,
  itemClassName,
  renderItem,
}: {
  items: T[];
  onReorder: (ids: string[]) => void;
  className?: string;
  itemClassName?: string;
  /** `handle` son las props que hay que poner en el elemento del que se agarra. */
  renderItem: (
    item: T,
    handle: { onPointerDown: (e: React.PointerEvent) => void },
    dragging: boolean,
  ) => ReactNode;
}) {
  // Mientras se arrastra se muestra un orden "de mentiras"; al soltar se
  // suelta ese orden y manda la lista real. Así, si la pantalla se refresca
  // en medio, nunca queda mostrando un orden viejo pegado.
  const [preview, setPreview] = useState<string[] | null>(null);
  const [dragId, setDragId] = useState<string | null>(null);
  const rows = useRef(new Map<string, HTMLDivElement>());

  const order: T[] = preview
    ? (preview.map((id) => items.find((i) => i.id === id)).filter(Boolean) as T[])
    : items;
  const orderRef = useRef<T[]>(order);
  orderRef.current = order;

  const start = (id: string) => (e: React.PointerEvent) => {
    e.preventDefault();
    e.stopPropagation();
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    setDragId(id);
    setPreview(items.map((i) => i.id));
  };

  const move = (e: React.PointerEvent) => {
    if (!dragId) return;
    const y = e.clientY;
    const list = orderRef.current;
    const from = list.findIndex((i) => i.id === dragId);
    if (from < 0) return;

    // ¿Sobre cuál fila está el dedo?
    let to = from;
    for (let i = 0; i < list.length; i++) {
      const el = rows.current.get(list[i].id);
      if (!el) continue;
      const r = el.getBoundingClientRect();
      if (y >= r.top && y <= r.bottom) {
        to = i;
        break;
      }
    }
    if (to === from) return;
    const next = list.map((i) => i.id);
    const [it] = next.splice(from, 1);
    next.splice(to, 0, it);
    setPreview(next);
  };

  const end = () => {
    if (!dragId) return;
    const nuevo = orderRef.current.map((i) => i.id);
    const viejo = items.map((i) => i.id);
    setDragId(null);
    setPreview(null);
    if (nuevo.join(",") !== viejo.join(",")) onReorder(nuevo);
  };

  return (
    <div className={className} onPointerMove={move} onPointerUp={end} onPointerCancel={end}>
      {order.map((item) => (
        <div
          key={item.id}
          ref={(el) => {
            if (el) rows.current.set(item.id, el);
            else rows.current.delete(item.id);
          }}
          className={`${itemClassName ?? ""} ${dragId === item.id ? "relative z-10 opacity-90 shadow-[0_6px_18px_rgba(4,17,29,0.18)]" : ""}`}
        >
          {renderItem(item, { onPointerDown: start(item.id) }, dragId === item.id)}
        </div>
      ))}
    </div>
  );
}

/** Manija de arrastre: seis puntos, el símbolo universal de "muéveme". */
export function DragHandle({
  onPointerDown,
  label,
}: {
  onPointerDown: (e: React.PointerEvent) => void;
  label: string;
}) {
  return (
    <span
      role="button"
      tabIndex={0}
      aria-label={label}
      title="Arrastra para mover"
      onPointerDown={onPointerDown}
      onClick={(e) => e.stopPropagation()}
      style={{ touchAction: "none" }}
      className="flex h-8 w-7 shrink-0 cursor-grab items-center justify-center text-ink-faint active:cursor-grabbing"
    >
      <svg viewBox="0 0 24 24" className="h-4 w-4" fill="currentColor" aria-hidden>
        <circle cx="9" cy="6" r="1.6" />
        <circle cx="15" cy="6" r="1.6" />
        <circle cx="9" cy="12" r="1.6" />
        <circle cx="15" cy="12" r="1.6" />
        <circle cx="9" cy="18" r="1.6" />
        <circle cx="15" cy="18" r="1.6" />
      </svg>
    </span>
  );
}

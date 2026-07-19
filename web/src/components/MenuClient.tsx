"use client";

import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import type { Menu, Product, Section } from "@/lib/menu";
import { useFavorites } from "@/lib/useFavorites";
import ProductRow from "./ProductRow";
import ProductSheet from "./ProductSheet";
import SearchOverlay from "./SearchOverlay";
import FavoritesSheet from "./FavoritesSheet";

const HEADER_OFFSET = 128; // alto aprox. del encabezado sticky (barra + chips)

function SectionBlock({
  section,
  onOpen,
}: {
  section: Section;
  onOpen: (p: Product) => void;
}) {
  return (
    <section
      id={section.slug}
      aria-label={section.name}
      className="mx-3 mt-7 scroll-mt-[124px] border border-gold-soft/35 bg-white/65 px-5 pb-4 pt-7 shadow-[0_1px_10px_rgba(4,27,49,0.05)]"
    >
      <header className="mb-2 text-center">
        <div className="ornament text-gold">
          <h2 className="font-display text-[22px] leading-tight text-navy">{section.name}</h2>
        </div>
        {section.description && (
          <p className="mt-1.5 font-display text-[13.5px] italic text-ink-soft">
            {section.description}
          </p>
        )}
      </header>

      {section.products.length > 0 && (
        <div className="divide-y divide-gold-soft/25">
          {section.products.map((p) => (
            <ProductRow key={p.id} product={p} onOpen={onOpen} />
          ))}
        </div>
      )}

      {section.subsections.map((ss) => (
        <div key={ss.id} className="pt-5">
          <header className="mb-1 text-center">
            <h3 className="smallcaps text-[12.5px] font-semibold text-gold-deep">{ss.name}</h3>
            {ss.description && (
              <p className="mt-1 font-display text-[13px] italic leading-snug text-ink-soft">
                {ss.description}
              </p>
            )}
          </header>
          <div className="divide-y divide-gold-soft/25">
            {ss.products.map((p) => (
              <ProductRow key={p.id} product={p} onOpen={onOpen} />
            ))}
          </div>
        </div>
      ))}
    </section>
  );
}

export default function MenuClient({ menu }: { menu: Menu }) {
  const [active, setActive] = useState(menu.sections[0]?.slug ?? "");
  const [sheetProduct, setSheetProduct] = useState<Product | null>(null);
  const [searchOpen, setSearchOpen] = useState(false);
  const [favsOpen, setFavsOpen] = useState(false);
  const { favorites, toggle } = useFavorites();
  const chipsRef = useRef<HTMLDivElement>(null);
  const chipRefs = useRef<Record<string, HTMLButtonElement | null>>({});
  const suppressSpy = useRef(false);

  // ── Scroll-spy: resalta la sección visible ──
  useEffect(() => {
    const slugs = menu.sections.map((s) => s.slug);
    let raf = 0;
    const onScroll = () => {
      if (suppressSpy.current) return;
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        // Una sección se considera activa cuando su inicio entra al tercio superior
        const threshold = HEADER_OFFSET + window.innerHeight * 0.22;
        let current = slugs[0];
        for (const slug of slugs) {
          const el = document.getElementById(slug);
          if (el && el.getBoundingClientRect().top <= threshold) current = slug;
        }
        setActive(current);
      });
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    return () => {
      window.removeEventListener("scroll", onScroll);
      cancelAnimationFrame(raf);
    };
  }, [menu.sections]);

  // ── Centra el chip activo en su carril ──
  useEffect(() => {
    const chip = chipRefs.current[active];
    const rail = chipsRef.current;
    if (chip && rail) {
      rail.scrollTo({
        left: chip.offsetLeft - rail.clientWidth / 2 + chip.clientWidth / 2,
        behavior: "smooth",
      });
    }
  }, [active]);

  // ── Bloquea el scroll del fondo cuando hay un overlay abierto ──
  useEffect(() => {
    const locked = !!sheetProduct || searchOpen || favsOpen;
    document.documentElement.classList.toggle("scroll-locked", locked);
    return () => document.documentElement.classList.remove("scroll-locked");
  }, [sheetProduct, searchOpen, favsOpen]);

  const goTo = useCallback((slug: string) => {
    setActive(slug);
    suppressSpy.current = true;
    const el = document.getElementById(slug);
    if (el) {
      const target = el.getBoundingClientRect().top + window.scrollY - (HEADER_OFFSET - 4);
      // Distancias largas saltan directo (un smooth de miles de px marea);
      // solo las cortas se animan.
      const distance = Math.abs(target - window.scrollY);
      window.scrollTo({
        top: target,
        behavior: distance > window.innerHeight * 2.5 ? "instant" : "smooth",
      });
    }
    // Reactiva el spy cuando el desplazamiento termina
    setTimeout(() => {
      suppressSpy.current = false;
    }, 700);
  }, []);

  const openProduct = useCallback((p: Product) => setSheetProduct(p), []);

  return (
    <div className="page-col relative mx-auto min-h-dvh w-full max-w-md">
      {/* Mármol fijo: no scrollea, igual que en menupp */}
      <div className="marble-fixed" aria-hidden />
      {/* ── Encabezado sticky: barra + pestañas de secciones ── */}
      <div className="sticky top-0 z-30 border-b border-gold-soft/60 bg-card/92 backdrop-blur-md">
        <div className="flex items-center justify-between px-3 pb-1 pt-[calc(env(safe-area-inset-top)+10px)]">
          <Link
            href="/"
            aria-label="Volver al inicio"
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink-soft active:bg-paper-deep"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <path d="M15 5l-7 7 7 7" />
            </svg>
          </Link>
          <div className="text-center">
            <p className="smallcaps text-[9px] text-gold-deep">Panisse</p>
            <h1 className="font-display text-[19px] leading-tight text-navy">{menu.label}</h1>
          </div>
          <button
            type="button"
            onClick={() => setSearchOpen(true)}
            aria-label="Buscar en la carta"
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink-soft active:bg-paper-deep"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
              <circle cx="11" cy="11" r="7" />
              <path d="m20 20-3.5-3.5" />
            </svg>
          </button>
        </div>

        <div ref={chipsRef} className="chips-scroll flex gap-2 overflow-x-auto px-4 pb-3 pt-1.5">
          {menu.sections.map((s) => (
            <button
              key={s.slug}
              ref={(el) => {
                chipRefs.current[s.slug] = el;
              }}
              type="button"
              onClick={() => goTo(s.slug)}
              className={`smallcaps h-9 shrink-0 whitespace-nowrap border px-4 text-[10.5px] font-medium transition-colors ${
                active === s.slug
                  ? "border-navy bg-navy text-gold-soft"
                  : "border-gold-soft/60 bg-card text-ink-soft"
              }`}
            >
              {s.name}
            </button>
          ))}
        </div>
      </div>

      {/* ── Contenido ── */}
      <main className="relative z-10 pb-[calc(env(safe-area-inset-bottom)+120px)]">
        <p className="px-5 pt-4 text-center font-display text-[13.5px] italic text-ink-soft">
          {menu.tagline}
        </p>
        {menu.sections.map((s) => (
          <SectionBlock key={s.id} section={s} onOpen={openProduct} />
        ))}

        <footer className="mt-14 px-5 text-center">
          <div className="ornament w-full text-gold">
            <span className="text-[10px]">❦</span>
          </div>
          <p className="mt-4 text-[11px] leading-relaxed text-ink-faint">
            Precios en pesos colombianos (COP) · Impuestos incluidos
          </p>
        </footer>
      </main>

      {/* ── Botón flotante: mi selección ── */}
      {favorites.size > 0 && (
        <button
          type="button"
          onClick={() => setFavsOpen(true)}
          aria-label={`Mi selección: ${favorites.size} platos`}
          className="anim-fade-up fixed bottom-[calc(env(safe-area-inset-bottom)+20px)] right-5 z-30 flex h-13 items-center gap-2 rounded-full bg-navy px-5 text-gold-soft shadow-[0_10px_28px_-8px_rgba(4,17,29,0.5)]"
        >
          <svg viewBox="0 0 24 24" className="h-4.5 w-4.5" fill="currentColor" aria-hidden>
            <path d="M12 21s-7.5-4.6-10-9.3C.6 8.6 2.6 5 6.2 5c2.2 0 3.6 1.2 4.4 2.5L12 9l1.4-1.5C14.2 6.2 15.6 5 17.8 5c3.6 0 5.6 3.6 4.2 6.7C19.5 16.4 12 21 12 21Z" />
          </svg>
          <span className="text-[13px] font-semibold">{favorites.size}</span>
        </button>
      )}

      {/* ── Overlays ── */}
      <SearchOverlay
        menu={menu}
        open={searchOpen}
        onClose={() => setSearchOpen(false)}
        onOpenProduct={openProduct}
      />
      <FavoritesSheet
        menu={menu}
        favorites={favorites}
        open={favsOpen}
        onClose={() => setFavsOpen(false)}
        onOpenProduct={openProduct}
        onRemove={toggle}
      />
      <ProductSheet
        product={sheetProduct}
        isFavorite={sheetProduct ? favorites.has(sheetProduct.id) : false}
        onToggleFavorite={() => sheetProduct && toggle(sheetProduct.id)}
        onClose={() => setSheetProduct(null)}
      />
    </div>
  );
}

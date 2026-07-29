"use client";

import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import { fetchMenuData, type Layout, type Menu, type Product, type Section } from "@/lib/menu";
import {
  menuThemeFor,
  menuThemeVars,
  publicMenuThemes,
  type MenuTheme,
} from "@/lib/menuTheme";
import { brandName, ishiroSkin, isIshiro, ISHIRO_LOGO, PREVIEW_ISHIRO, sinRoka } from "@/lib/ishiro";
import { track } from "@/lib/track";
import { useScrollLock } from "@/lib/scrollLock";
import ProductRow from "./ProductRow";
import ProductCard from "./ProductCard";
import ProductSheet from "./ProductSheet";
import SearchOverlay from "./SearchOverlay";
import CartBar from "./CartBar";
import MyOrders from "./MyOrders";

const HEADER_OFFSET = 128; // alto aprox. del encabezado sticky (barra + chips)

function ProductGroup({
  products,
  layout,
  onOpen,
}: {
  products: Product[];
  layout: Layout;
  onOpen: (p: Product) => void;
}) {
  if (layout === "cards") {
    return (
      <div className="grid grid-cols-2 gap-2.5 pt-1">
        {products.map((p) => (
          <ProductCard key={p.id} product={p} onOpen={onOpen} />
        ))}
      </div>
    );
  }
  return (
    <div className="divide-y divide-gold-soft/25">
      {products.map((p) => (
        <ProductRow key={p.id} product={p} onOpen={onOpen} />
      ))}
    </div>
  );
}

function SectionBlock({
  section,
  onOpen,
}: {
  section: Section;
  onOpen: (p: Product) => void;
}) {
  const cards = section.layout === "cards";
  return (
    <section
      id={section.slug}
      aria-label={section.name}
      className={`mx-3 mt-7 scroll-mt-[124px] px-4 pb-4 pt-7 ${
        cards
          ? ""
          : "border border-gold-soft/35 bg-white/65 shadow-[0_1px_10px_rgba(4,27,49,0.05)]"
      }`}
    >
      <header className="mb-3 px-1 text-center">
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
        <ProductGroup products={section.products} layout={section.layout} onOpen={onOpen} />
      )}

      {section.subsections.map((ss) => (
        <div key={ss.id} className="pt-5">
          <header className="mb-2 px-1 text-center">
            <h3 className="smallcaps text-[12.5px] font-semibold text-gold-deep">{ss.name}</h3>
            {ss.description && (
              <p className="mt-1 font-display text-[13px] italic leading-snug text-ink-soft">
                {ss.description}
              </p>
            )}
          </header>
          <ProductGroup products={ss.products} layout={ss.layout} onOpen={onOpen} />
        </div>
      ))}
    </section>
  );
}

export default function MenuClient({ menu: initialMenu }: { menu: Menu }) {
  // El HTML llega con el menú del build (pinta al instante); al montar se
  // reemplaza con el menú vivo de la base de datos (Supabase).
  const [menu, setMenu] = useState(initialMenu);
  const [active, setActive] = useState(initialMenu.sections[0]?.slug ?? "");

  useEffect(() => {
    track("menu_view", { menuSlug: initialMenu.slug });
    let cancelled = false;
    fetchMenuData()
      .then((data) => {
        const fresh = data.menus.find((m) => m.slug === initialMenu.slug);
        // La marca no cambia; se conserva la del build por si la base aún no la trae.
        if (fresh && !cancelled) setMenu({ ...fresh, brand: initialMenu.brand });
      })
      .catch(() => {
        /* sin conexión: se queda el menú del build */
      });
    return () => {
      cancelled = true;
    };
  }, [initialMenu.slug]);
  const [sheetProduct, setSheetProduct] = useState<Product | null>(null);
  const [searchOpen, setSearchOpen] = useState(false);
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

  // ── Congela el fondo cuando hay un overlay abierto ──
  useScrollLock(!!sheetProduct || searchOpen);

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

  const openProduct = useCallback(
    (p: Product) => {
      setSheetProduct(p);
      track("product_view", { productId: p.id, menuSlug: initialMenu.slug });
    },
    [initialMenu.slug],
  );

  const isRoka = menu.brand === "roka";

  // Apariencia de la carta: se edita en el panel y se aplica en vivo.
  // (En la marca nueva manda ISHIRO, no lo guardado en el panel.)
  const [skin, setSkin] = useState<MenuTheme>(ishiroSkin(menu.brand, menuThemeFor(menu.brand)));
  useEffect(() => {
    if (PREVIEW_ISHIRO && isIshiro(menu.brand)) return;
    publicMenuThemes()
      .then((all) => {
        const mine = all?.[isRoka ? "roka" : "panisse"];
        if (mine) setSkin({ ...menuThemeFor(menu.brand), ...mine });
      })
      .catch(() => {
        /* si falla, se queda el aspecto por defecto */
      });
  }, [menu.brand, isRoka]);

  return (
    <div
      data-menu-skin
      data-section-style={skin.sectionStyle}
      style={menuThemeVars(skin)}
      className="page-col relative mx-auto min-h-dvh w-full max-w-md"
    >
      {/* Fondo de la carta: mármol, color liso o una foto */}
      <div
        className={`marble-fixed ${skin.background === "sand" ? "sand-fixed" : ""}`}
        style={
          skin.background === "marble" || skin.background === "sand"
            ? undefined
            : skin.background === "image" && skin.bgImage
              ? {
                  backgroundImage: `linear-gradient(rgba(255,255,255,0.72), rgba(255,255,255,0.72)), url(${skin.bgImage})`,
                  backgroundSize: "cover",
                  backgroundPosition: "center",
                }
              : { backgroundImage: "none", backgroundColor: "var(--color-paper)" }
        }
        aria-hidden
      />
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
          <div className="flex items-center gap-2.5 text-center">
            {PREVIEW_ISHIRO && isRoka && (
              /* Logo circular de ISHIRO, en la barra de la carta */
              // eslint-disable-next-line @next/next/no-img-element
              <img src={ISHIRO_LOGO} alt="" aria-hidden className="h-9 w-9 shrink-0 object-contain" />
            )}
            <div>
              <p className="smallcaps text-[9px] text-gold-deep">{brandName(menu.brand)}</p>
              <h1 className="font-display text-[19px] leading-tight text-navy">{sinRoka(menu.label)}</h1>
            </div>
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

        {/* Seguimiento del pedido del cliente */}
        <MyOrders />
      </div>

      {/* ── Contenido ── */}
      <main className="relative z-10 pt-2 pb-[calc(env(safe-area-inset-bottom)+120px)]">
        {menu.sections.map((s) => (
          <SectionBlock key={s.id} section={s} onOpen={openProduct} />
        ))}

        <footer className="mt-14 px-5 text-center">
          {/* Reservar desde la carta. En Roka, la reserva ofrece decoración. */}
          <Link
            href={isRoka ? "/reservar?marca=roka" : "/reservar"}
            className="mx-auto flex max-w-xs items-center justify-center gap-2.5 bg-navy px-6 py-4 text-gold-soft shadow-[0_2px_14px_rgba(4,27,49,0.12)] transition-transform active:scale-[0.985]"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5 text-gold" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <rect x="3" y="4" width="18" height="18" rx="2" />
              <path d="M16 2v4M8 2v4M3 10h18" />
            </svg>
            <span className="smallcaps text-[14px] font-medium tracking-[0.12em]">Reservar una mesa</span>
          </Link>
          {PREVIEW_ISHIRO && isRoka ? (
            /* Cierre de la carta con el logo de la marca */
            // eslint-disable-next-line @next/next/no-img-element
            <img src={ISHIRO_LOGO} alt="ISHIRO" className="mx-auto mt-14 h-11 w-11 object-contain opacity-70" />
          ) : (
            <div className="ornament mt-14 w-full text-gold">
              <span className="text-[10px]">❦</span>
            </div>
          )}
          <p className="mt-4 text-[11px] leading-relaxed text-ink-faint">
            Precios en pesos colombianos (COP) · Impuestos incluidos
          </p>
        </footer>
      </main>

      {/* ── Overlays ── */}
      <SearchOverlay
        menu={menu}
        open={searchOpen}
        onClose={() => setSearchOpen(false)}
        onOpenProduct={openProduct}
      />
      <ProductSheet product={sheetProduct} onClose={() => setSheetProduct(null)} />
      <CartBar />
    </div>
  );
}

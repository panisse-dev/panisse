import Image from "next/image";
import Link from "next/link";
import { menus, restaurant } from "@/lib/menu";

export default function Home() {
  return (
    <div className="page-col relative mx-auto flex min-h-dvh w-full max-w-md flex-col px-7 pb-8 pt-4">
      {/* Mármol fijo: no scrollea, igual que en menupp */}
      <div className="marble-fixed" aria-hidden />
      <main className="relative z-10 flex flex-1 flex-col">
        {/* Cabecera de marca */}
        <header className="anim-fade-up flex flex-col items-center pt-16 text-center">
          <p className="smallcaps text-[11px] font-medium text-gold-deep">Ristorante · Caffè</p>
          <div className="relative mt-5 h-16 w-64">
            <Image
              src={restaurant.logo}
              alt="PANISSE"
              fill
              priority
              sizes="256px"
              className="object-contain"
            />
          </div>
          <p className="mt-5 font-display text-[15px] italic text-ink-soft">
            Cocina italiana en {restaurant.city}
          </p>
          <div className="ornament mt-6 w-40 text-gold">
            <span className="text-[10px]">❦</span>
          </div>
        </header>

        {/* Botones de menú — cuadrados, blancos, borde dorado (estilo carta) */}
        <nav aria-label="Menús" className="mt-12 flex flex-col gap-5">
          {menus.map((menu, i) => (
            <Link
              key={menu.slug}
              href={`/menu/${menu.slug}`}
              className="anim-fade-up group relative block border border-gold-soft bg-card px-6 py-5 text-center shadow-[0_2px_14px_rgba(4,27,49,0.08)] outline outline-1 outline-offset-[3px] outline-gold-soft/40 transition-transform active:scale-[0.985]"
              style={{ animationDelay: `${0.12 + i * 0.09}s` }}
            >
              <span className="smallcaps block font-display text-[19px] font-medium leading-tight tracking-[0.12em] text-navy">
                {menu.label}
              </span>
              <span className="mt-1 block text-[12px] text-gold-deep">{menu.tagline}</span>
            </Link>
          ))}
        </nav>

        {/* Pie: contacto */}
        <footer
          className="anim-fade-up mt-auto pt-14 text-center"
          style={{ animationDelay: "0.45s" }}
        >
          <p className="text-[12px] leading-relaxed text-ink-faint">
            {restaurant.address} · {restaurant.city}
          </p>
          <div className="mt-4 flex items-center justify-center gap-3">
            <a
              href={`https://wa.me/${restaurant.whatsapp.replace(/\D/g, "")}`}
              target="_blank"
              rel="noopener noreferrer"
              className="flex h-10 items-center gap-2 border border-gold-soft bg-card px-4 text-[12px] font-medium text-ink-soft"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4 text-verde" fill="currentColor" aria-hidden>
                <path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2Zm0 18.2c-1.5 0-3-.4-4.2-1.1l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2Zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8-.2-.1-.4-.1-.6.1-.2.2-.6.8-.8 1-.1.2-.3.2-.5.1a6.7 6.7 0 0 1-3.4-3c-.3-.4 0-.5.1-.7l.4-.5c.1-.2.2-.3.3-.5v-.5c0-.1-.5-1.4-.7-1.9-.2-.5-.4-.4-.6-.4h-.5c-.2 0-.5.1-.7.3-.2.3-.9.9-.9 2.2s.9 2.5 1.1 2.7c.1.2 1.9 2.9 4.6 4a15 15 0 0 0 1.5.6c.6.2 1.2.2 1.7.1.5-.1 1.5-.6 1.7-1.2.2-.6.2-1.1.2-1.2l-.4-.3Z" />
              </svg>
              WhatsApp
            </a>
            <a
              href={`https://instagram.com/${restaurant.instagram}`}
              target="_blank"
              rel="noopener noreferrer"
              className="flex h-10 items-center gap-2 border border-gold-soft bg-card px-4 text-[12px] font-medium text-ink-soft"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4 text-gold-deep" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden>
                <rect x="3" y="3" width="18" height="18" rx="5" />
                <circle cx="12" cy="12" r="4" />
                <circle cx="17.2" cy="6.8" r="0.6" fill="currentColor" stroke="none" />
              </svg>
              @{restaurant.instagram}
            </a>
          </div>
        </footer>
      </main>
    </div>
  );
}

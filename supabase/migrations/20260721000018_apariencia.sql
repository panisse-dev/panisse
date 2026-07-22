-- ══════════════════════════════════════════════════════════════════
-- Apariencia de la pantalla del cliente (editable desde el panel)
--
-- El restaurante ajusta los tres títulos de la portada (la línea de arriba
-- "Ristorante · Caffè", el nombre PANISSE y la frase de abajo) — texto, tipo
-- de letra, tamaño y color — más el color de fondo. La portada del cliente
-- lee esto en vivo, así los cambios se ven sin volver a publicar. Los valores
-- por defecto son los actuales, para que nada cambie hasta que se toque.
-- ══════════════════════════════════════════════════════════════════

create table if not exists public.home_theme (
  id boolean primary key default true check (id),

  -- Línea de arriba ("Ristorante · Caffè")
  eyebrow_text text not null default 'Ristorante · Caffè',
  eyebrow_font text not null default 'outfit',
  eyebrow_size int not null default 11,
  eyebrow_color text not null default '#8f7434',

  -- Nombre PANISSE: 'logo' (imagen actual) o 'text' (texto editable)
  brand_mode text not null default 'logo' check (brand_mode in ('logo','text')),
  brand_text text not null default 'PANISSE',
  brand_font text not null default 'playfair',
  brand_size int not null default 46,
  brand_color text not null default '#041b31',

  -- Frase de abajo ("Cocina italiana en Pereira")
  tagline_text text not null default 'Cocina italiana en Pereira',
  tagline_font text not null default 'playfair',
  tagline_size int not null default 15,
  tagline_color text not null default '#47535e',

  -- Fondo
  bg_color text not null default '#f6f6f5',
  show_marble boolean not null default true,

  updated_at timestamptz not null default now()
);
insert into public.home_theme (id) values (true) on conflict (id) do nothing;

alter table public.home_theme enable row level security;
-- Lectura pública (la portada del cliente la necesita)
drop policy if exists home_theme_read on public.home_theme;
create policy home_theme_read on public.home_theme for select using (true);

-- Arma el objeto de tema (se reutiliza en la lectura pública y la del panel).
create or replace function public.home_theme_json()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'eyebrow', jsonb_build_object('text', t.eyebrow_text, 'font', t.eyebrow_font, 'size', t.eyebrow_size, 'color', t.eyebrow_color),
    'brand', jsonb_build_object('mode', t.brand_mode, 'text', t.brand_text, 'font', t.brand_font, 'size', t.brand_size, 'color', t.brand_color),
    'tagline', jsonb_build_object('text', t.tagline_text, 'font', t.tagline_font, 'size', t.tagline_size, 'color', t.tagline_color),
    'bgColor', t.bg_color,
    'showMarble', t.show_marble
  )
  from home_theme t where t.id;
$$;

create or replace function public.public_home_theme()
returns jsonb language sql stable security definer set search_path = public
as $$ select home_theme_json() $$;

create or replace function public.staff_home_theme(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return home_theme_json();
end
$$;

create or replace function public.staff_update_home_theme(p_code text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_fonts text[] := array['playfair','outfit','cormorant','montserrat','dancing'];
begin
  perform assert_staff(p_code);
  update home_theme set
    eyebrow_text = left(btrim(coalesce(p->'eyebrow'->>'text', eyebrow_text)), 80),
    eyebrow_font = case when (p->'eyebrow'->>'font') = any(v_fonts) then p->'eyebrow'->>'font' else eyebrow_font end,
    eyebrow_size = greatest(8, least(40, coalesce((p->'eyebrow'->>'size')::int, eyebrow_size))),
    eyebrow_color = left(coalesce(p->'eyebrow'->>'color', eyebrow_color), 9),
    brand_mode = case when (p->'brand'->>'mode') in ('logo','text') then p->'brand'->>'mode' else brand_mode end,
    brand_text = left(btrim(coalesce(p->'brand'->>'text', brand_text)), 40),
    brand_font = case when (p->'brand'->>'font') = any(v_fonts) then p->'brand'->>'font' else brand_font end,
    brand_size = greatest(20, least(120, coalesce((p->'brand'->>'size')::int, brand_size))),
    brand_color = left(coalesce(p->'brand'->>'color', brand_color), 9),
    tagline_text = left(btrim(coalesce(p->'tagline'->>'text', tagline_text)), 120),
    tagline_font = case when (p->'tagline'->>'font') = any(v_fonts) then p->'tagline'->>'font' else tagline_font end,
    tagline_size = greatest(10, least(48, coalesce((p->'tagline'->>'size')::int, tagline_size))),
    tagline_color = left(coalesce(p->'tagline'->>'color', tagline_color), 9),
    bg_color = left(coalesce(p->>'bgColor', bg_color), 9),
    show_marble = coalesce((p->>'showMarble')::boolean, show_marble),
    updated_at = now()
  where id;
end
$$;

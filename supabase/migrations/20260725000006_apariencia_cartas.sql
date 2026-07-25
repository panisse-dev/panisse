-- ══════════════════════════════════════════════════════════════════
-- Apariencia de las cartas, editable desde el panel
--
-- El aspecto de cada carta (fondo, colores, tipo y tamaño de letra)
-- estaba escrito en el código: para cambiarlo tocaba publicar el sitio.
-- Ahora vive en la base, una configuración por marca, y se edita desde
-- Ajustes sin que nadie tenga que tocar código.
-- ══════════════════════════════════════════════════════════════════

create table if not exists public.menu_themes (
  brand text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.menu_themes enable row level security;

-- Valores iniciales: exactamente el aspecto que tienen hoy, para que
-- nada cambie hasta que alguien lo edite a propósito.
insert into public.menu_themes (brand, data) values
  ('panisse', jsonb_build_object(
    'bgColor', '#f6f6f5', 'cardColor', '#ffffff',
    'titleColor', '#041b31', 'textColor', '#10202f', 'goldColor', '#b28f4c',
    'titleFont', 'playfair', 'bodyFont', 'outfit',
    'scale', 1, 'background', 'marble', 'bgImage', null,
    'sectionStyle', 'ornament'
  )),
  ('roka', jsonb_build_object(
    'bgColor', '#f2ecdd', 'cardColor', '#f8f3e6',
    'titleColor', '#2f2415', 'textColor', '#352c1e', 'goldColor', '#a3894f',
    'titleFont', 'playfair', 'bodyFont', 'outfit',
    'scale', 1, 'background', 'plain', 'bgImage', null,
    'sectionStyle', 'boxed'
  ))
on conflict (brand) do nothing;

-- Lo que lee la carta del cliente.
create or replace function public.public_menu_themes()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_object_agg(t.brand, t.data), '{}'::jsonb) from menu_themes t;
$$;

-- Lo que ve y guarda el panel.
create or replace function public.staff_menu_themes(p_code text)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return public_menu_themes();
end
$$;

create or replace function public.staff_save_menu_theme(p_code text, p_brand text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  if p_brand not in ('panisse','roka') then raise exception 'Marca no válida'; end if;
  insert into menu_themes (brand, data, updated_at) values (p_brand, p, now())
  on conflict (brand) do update set data = excluded.data, updated_at = now();
end
$$;

grant execute on function public.public_menu_themes() to anon, authenticated;
grant execute on function public.staff_menu_themes(text) to anon, authenticated;
grant execute on function public.staff_save_menu_theme(text, text, jsonb) to anon, authenticated;

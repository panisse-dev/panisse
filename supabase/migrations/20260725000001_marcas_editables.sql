-- ══════════════════════════════════════════════════════════════════
-- Los botones de marca de la portada (Carta Panisse / Carta Roka) y su
-- frase de abajo estaban escritos en el código, así que borrarlos o
-- cambiarlos desde Ajustes no servía de nada. Ahora viven en la base.
-- ══════════════════════════════════════════════════════════════════

create table if not exists public.brands (
  id text primary key,
  label text not null default '',
  tagline text not null default '',
  sort int not null default 0
);

insert into public.brands (id, label, tagline, sort) values
  ('panisse', 'Carta Panisse', 'Nuestra cocina de siempre', 0),
  ('roka', 'Carta Roka', 'Nikkei, peruana y parrilla', 1)
on conflict (id) do nothing;

alter table public.brands enable row level security;

-- Lo que ve el cliente en la portada.
create or replace function public.public_brands()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', b.id, 'label', b.label, 'tagline', b.tagline
  ) order by b.sort), '[]'::jsonb)
  from brands b;
$$;

-- Edición desde Ajustes. La frase puede quedar vacía a propósito.
create or replace function public.staff_update_brand(p_code text, p_id text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update brands set
    label = coalesce(left(btrim(p->>'label'), 60), label),
    tagline = coalesce(left(btrim(p->>'tagline'), 120), tagline)
  where id = p_id;
end
$$;

create or replace function public.staff_brands(p_code text)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return public_brands();
end
$$;

grant execute on function public.public_brands() to anon, authenticated;
grant execute on function public.staff_brands(text) to anon, authenticated;
grant execute on function public.staff_update_brand(text, text, jsonb) to anon, authenticated;

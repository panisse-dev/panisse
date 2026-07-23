-- Decoraciones de celebración de ROKA: el cliente puede agregar una a su
-- reserva. Editables desde el panel. Se guardan en la reserva y se ven en el
-- panel y en la confirmación del cliente.

create table if not exists public.decorations (
  id text primary key,
  name text not null,
  description text not null default '',
  price int not null default 0,
  sort int not null default 0,
  active boolean not null default true
);

insert into public.decorations (id, name, description, price, sort) values
  ('rose', 'Rose', 'Bouquet de globos rosados · Postre ROKA · Aviso Feliz Cumpleaños', 60000, 1),
  ('silver', 'Silver', 'Bouquet de globos plateados · Postre ROKA · Aviso Feliz Cumpleaños', 60000, 2),
  ('rose_cocktail', 'Rose Cocktail', 'Bouquet de globos rosados · Cóctel ROKA · Aviso Feliz Cumpleaños', 60000, 3),
  ('silver_cocktail', 'Silver Cocktail', 'Bouquet de globos plateados · Cóctel ROKA · Aviso Feliz Cumpleaños', 60000, 4)
on conflict (id) do nothing;

alter table public.decorations enable row level security;
drop policy if exists decorations_read on public.decorations;
create policy decorations_read on public.decorations for select using (active);

-- La reserva guarda la decoración elegida (nombre y precio al momento de elegir).
alter table public.reservations add column if not exists decoration jsonb;

-- ── Lista pública (para el flujo del cliente) ──
create or replace function public.public_decorations()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', d.id, 'name', d.name, 'description', d.description, 'price', d.price
  ) order by d.sort), '[]'::jsonb)
  from decorations d where d.active;
$$;

-- ── Guardar la decoración en una reserva recién creada ──
-- Se llama justo después de crear la reserva. Valida que exista y esté activa.
create or replace function public.reservation_set_decoration(p_id uuid, p_decoration_id text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_dec decorations%rowtype;
begin
  if coalesce(p_decoration_id, '') = '' then
    update reservations set decoration = null where id = p_id;
    return;
  end if;
  select * into v_dec from decorations where id = p_decoration_id and active;
  if not found then
    raise exception 'Esa decoración no está disponible';
  end if;
  update reservations set decoration = jsonb_build_object(
    'id', v_dec.id, 'name', v_dec.name, 'description', v_dec.description, 'price', v_dec.price
  ) where id = p_id;
end
$$;

-- ── Panel: leer y editar las decoraciones ──
create or replace function public.staff_decorations(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', d.id, 'name', d.name, 'description', d.description, 'price', d.price, 'active', d.active
    ) order by d.sort)
    from decorations d
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_update_decoration(p_code text, p_id text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update decorations set
    name = case when p ? 'name' then left(btrim(p->>'name'), 60) else name end,
    description = case when p ? 'description' then left(btrim(p->>'description'), 200) else description end,
    price = case when p ? 'price' then greatest(0, (p->>'price')::int) else price end,
    active = case when p ? 'active' then (p->>'active')::boolean else active end
  where id = p_id;
  if not found then raise exception 'Decoración no encontrada'; end if;
end
$$;

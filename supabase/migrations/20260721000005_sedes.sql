-- ══════════════════════════════════════════════════════════════════
-- Dos sedes (Cerritos Mall y Pilares del Bosque)
--
-- Cimiento: cada pedido y cada reserva queda marcado con su sede, y cada
-- código del personal ve SOLO su sede (el código "dueño" ve todas). No se
-- toca create_order todavía: la columna trae valor por defecto, así lo que
-- ya está en vivo sigue funcionando igual hasta que publiquemos el selector.
-- ══════════════════════════════════════════════════════════════════

-- ── Sedes (datos editables luego desde el panel) ──
create table if not exists public.locations (
  id text primary key,             -- 'cerritos', 'pilares'
  name text not null,
  address text not null default '',
  phone text not null default '',
  whatsapp text not null default '',
  sort int not null default 0,
  active boolean not null default true
);
insert into public.locations (id, name, address, whatsapp, sort) values
  ('cerritos', 'Cerritos Mall', 'Cerritos Mall 29RS Local 113, Pereira', '+573128179235', 1),
  ('pilares', 'Pilares del Bosque', 'Mall Pilares del Bosque, Local 2, Pereira', '+573128179235', 2)
on conflict (id) do nothing;

alter table public.locations enable row level security;
-- Lectura pública de las sedes (el cliente elige en el inicio)
drop policy if exists locations_read on public.locations;
create policy locations_read on public.locations for select using (true);

-- ── Personal por sede ──
-- location_id null = ve TODAS las sedes (dueño/administrador general).
create table if not exists public.staff_members (
  code text primary key,
  location_id text references public.locations(id) on delete cascade,
  name text not null default ''
);
insert into public.staff_members (code, location_id, name) values
  ('cerritos2026', 'cerritos', 'Cerritos'),
  ('pilares2026', 'pilares', 'Pilares')
on conflict (code) do nothing;
alter table public.staff_members enable row level security; -- sin políticas: sólo por RPC

-- El código antiguo (app_config.staff_code) sigue siendo el "dueño" que ve todo.
create or replace function public.assert_staff(p_code text)
returns void
language plpgsql stable
security definer set search_path = public
as $$
begin
  if coalesce(p_code,'') = '' or not (
    exists (select 1 from app_config where key = 'staff_code' and value = p_code)
    or exists (select 1 from staff_members where code = p_code)
  ) then
    raise exception 'No autorizado' using errcode = '42501';
  end if;
end
$$;

-- Sede de un código (null = todas). El código dueño no está en staff_members → null.
create or replace function public.staff_location(p_code text)
returns text
language sql stable
security definer set search_path = public
as $$
  select location_id from staff_members where code = p_code
$$;

-- Qué sede está usando el personal (para mostrarlo en el panel)
create or replace function public.staff_context(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  if v_loc is null then
    return jsonb_build_object('locationId', null, 'locationName', 'Todas las sedes', 'allLocations', true);
  end if;
  return (
    select jsonb_build_object('locationId', l.id, 'locationName', l.name, 'allLocations', false)
    from locations l where l.id = v_loc
  );
end
$$;

-- ── Marca de sede en pedidos y reservas ──
alter table public.orders add column if not exists location_id text references public.locations(id) default 'pilares';
update public.orders set location_id = 'pilares' where location_id is null;
alter table public.reservations add column if not exists location_id text references public.locations(id) default 'cerritos';
update public.reservations set location_id = 'cerritos' where location_id is null;

-- ── Cocina: cada sede ve sólo sus pedidos pagados ──
create or replace function public.staff_orders(p_code text, p_day date default null)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', o.id, 'code', o.code, 'createdAt', o.created_at, 'status', o.status,
      'statusAt', o.status_at, 'paid', o.paid, 'locationId', o.location_id,
      'customer', jsonb_build_object('name', o.customer_name, 'phone', o.customer_phone, 'note', o.customer_note),
      'billing', o.billing, 'staffNote', o.staff_note, 'total', o.total,
      'items', coalesce((
        select jsonb_agg(jsonb_build_object(
          'productId', i.product_id, 'name', i.name, 'variant', i.variant,
          'note', i.note, 'unitPrice', i.unit_price, 'qty', i.qty))
        from order_items i where i.order_id = o.id), '[]'::jsonb)
    ) order by o.created_at)
    from orders o
    where o.paid
      and (v_loc is null or o.location_id = v_loc)
      and case when p_day is null then
        o.status <> 'recogido' or o.status_at > now() - interval '6 hours'
      else (o.created_at at time zone 'America/Bogota')::date = p_day end
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_pending_orders(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', o.id, 'code', o.code, 'createdAt', o.created_at, 'status', o.status,
      'statusAt', o.status_at, 'paid', o.paid, 'locationId', o.location_id,
      'customer', jsonb_build_object('name', o.customer_name, 'phone', o.customer_phone, 'note', o.customer_note),
      'billing', o.billing, 'staffNote', o.staff_note, 'total', o.total,
      'items', coalesce((
        select jsonb_agg(jsonb_build_object(
          'productId', i.product_id, 'name', i.name, 'variant', i.variant,
          'note', i.note, 'unitPrice', i.unit_price, 'qty', i.qty))
        from order_items i where i.order_id = o.id), '[]'::jsonb)
    ) order by o.created_at desc)
    from orders o
    where not o.paid and o.status <> 'recogido'
      and o.created_at > now() - interval '24 hours'
      and (v_loc is null or o.location_id = v_loc)
  ), '[]'::jsonb);
end
$$;

-- ── Reservas: cada sede ve sólo las suyas ──
create or replace function public.staff_reservations(p_code text, p_day date default null)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_day date := coalesce(p_day, (now() at time zone 'America/Bogota')::date);
  v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', r.id, 'code', r.code, 'date', r.reserved_date, 'time', to_char(r.reserved_time, 'HH24:MI'),
      'party', r.party_size, 'status', r.status, 'createdAt', r.created_at, 'locationId', r.location_id,
      'customer', jsonb_build_object('name', r.customer_name, 'phone', r.customer_phone, 'email', r.customer_email),
      'note', r.note, 'staffNote', r.staff_note,
      'depositRequired', r.deposit_required, 'depositPaid', r.deposit_paid
    ) order by r.reserved_time, r.created_at)
    from reservations r
    where r.reserved_date = v_day
      and (v_loc is null or r.location_id = v_loc)
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_reservations_upcoming(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_today date := (now() at time zone 'America/Bogota')::date;
  v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object('day', d.reserved_date, 'total', d.total, 'pendientes', d.pend) order by d.reserved_date)
    from (
      select r.reserved_date,
             count(*) as total,
             count(*) filter (where r.status = 'pendiente') as pend
      from reservations r
      where r.reserved_date >= v_today and r.status <> 'cancelada'
        and (v_loc is null or r.location_id = v_loc)
      group by r.reserved_date
    ) d
  ), '[]'::jsonb);
end
$$;

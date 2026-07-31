-- ══════════════════════════════════════════════════════════════════
-- Saber si la decoración de una reserva ya está pagada.
--
-- Las decoraciones se cobran por adelantado y el cliente ahora paga
-- desde la pantalla de su reserva (portal de Davivienda, transferencia
-- o QR). Como ninguno de esos medios avisa solo, es el restaurante el
-- que marca el pago cuando ve el comprobante — igual que con los
-- pedidos.
--
-- Se guarda en columnas propias y no dentro del jsonb de la decoración
-- para poder contar y sumar después (cuánto se vendió en decoración,
-- cuántas quedaron sin cobrar).
-- ══════════════════════════════════════════════════════════════════

alter table public.reservations
  add column if not exists decoration_paid boolean not null default false,
  add column if not exists decoration_paid_at timestamptz;

-- ── El panel: la lista del día ──
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
      'depositRequired', r.deposit_required, 'depositPaid', r.deposit_paid,
      'isWalkIn', r.is_walk_in, 'source', r.source,
      'petFriendly', r.pet_friendly, 'reducedMobility', r.reduced_mobility,
      'decoration', r.decoration,
      'decorationPaid', r.decoration_paid,
      'decorationPaidAt', r.decoration_paid_at,
      'tableId', r.table_id,
      'tableName', (select t.name from restaurant_tables t where t.id = r.table_id),
      'tables', coalesce((
        select jsonb_agg(jsonb_build_object('id', tt.id, 'name', tt.name) order by tt.sort, tt.name)
        from restaurant_tables tt
        where tt.id = r.table_id
           or exists (select 1 from reservation_tables rt
                      where rt.reservation_id = r.id and rt.table_id = tt.id)
      ), '[]'::jsonb)
    ) order by r.reserved_time, r.created_at)
    from reservations r
    where r.reserved_date = v_day
      and (v_loc is null or r.location_id = v_loc)
  ), '[]'::jsonb);
end
$$;

-- ── El panel: el detalle de una reserva ──
create or replace function public.staff_reservation_detail(p_code text, p_id uuid)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_loc text;
  v_res reservations;
  v_client clients;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  select * into v_res from reservations where id = p_id;
  if v_res.id is null then raise exception 'Reserva no encontrada'; end if;
  if v_loc is not null and v_res.location_id <> v_loc then
    raise exception 'No autorizado' using errcode = '42501';
  end if;
  if v_res.client_id is not null then
    select * into v_client from clients where id = v_res.client_id;
  end if;

  return jsonb_build_object(
    'id', v_res.id, 'code', v_res.code,
    'date', v_res.reserved_date, 'time', to_char(v_res.reserved_time, 'HH24:MI'),
    'party', v_res.party_size, 'status', v_res.status, 'createdAt', v_res.created_at,
    'source', v_res.source, 'isWalkIn', v_res.is_walk_in,
    'petFriendly', v_res.pet_friendly, 'reducedMobility', v_res.reduced_mobility,
    'decoration', v_res.decoration,
    'decorationPaid', v_res.decoration_paid,
    'decorationPaidAt', v_res.decoration_paid_at,
    'note', v_res.note, 'staffNote', v_res.staff_note,
    'depositRequired', v_res.deposit_required, 'depositPaid', v_res.deposit_paid,
    'customer', jsonb_build_object('name', v_res.customer_name, 'phone', v_res.customer_phone, 'email', v_res.customer_email),
    'tables', coalesce((
      select jsonb_agg(jsonb_build_object('id', tt.id, 'name', tt.name, 'zone', z.name) order by tt.sort, tt.name)
      from restaurant_tables tt join zones z on z.id = tt.zone_id
      where tt.id = v_res.table_id
         or exists (select 1 from reservation_tables rt where rt.reservation_id = v_res.id and rt.table_id = tt.id)
    ), '[]'::jsonb),
    'client', case when v_client.id is null then null else jsonb_build_object(
      'id', v_client.id, 'name', v_client.name, 'phone', v_client.phone, 'email', v_client.email,
      'birthday', v_client.birthday, 'vip', v_client.vip, 'blacklisted', v_client.blacklisted
    ) end,
    'clientStats', (
      select jsonb_build_object(
        'total', count(*),
        'arrived', count(*) filter (where status = 'cumplida'),
        'noShow', count(*) filter (where status = 'no_show'),
        'cancelled', count(*) filter (where status = 'cancelada')
      )
      from reservations r2
      where r2.client_id is not distinct from v_res.client_id
        and v_res.client_id is not null
    )
  );
end
$$;

-- ── Marcar (o desmarcar) el pago de la decoración ──
create or replace function public.staff_set_decoration_paid(
  p_code text, p_id uuid, p_paid boolean)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_loc text;
  v_res reservations;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  select * into v_res from reservations where id = p_id;
  if v_res.id is null then raise exception 'Reserva no encontrada'; end if;
  if v_loc is not null and v_res.location_id <> v_loc then
    raise exception 'No autorizado' using errcode = '42501';
  end if;
  if v_res.decoration is null then
    raise exception 'Esa reserva no tiene decoración';
  end if;

  update reservations
     set decoration_paid = coalesce(p_paid, false),
         decoration_paid_at = case when coalesce(p_paid, false) then now() else null end
   where id = p_id;
end
$$;

grant execute on function public.staff_set_decoration_paid(text, uuid, boolean) to anon, authenticated;

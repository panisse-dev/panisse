-- La lista y la ficha de reservas del panel ahora incluyen la decoración
-- elegida, para que el personal vea qué decoración pidió el cliente.

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
      where (v_res.client_id is not null and r2.client_id = v_res.client_id)
         or (v_res.client_id is null and r2.id = v_res.id)
    )
  );
end
$$;

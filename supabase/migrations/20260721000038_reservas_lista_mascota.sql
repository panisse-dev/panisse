-- La lista de reservas ahora incluye si viene con mascota o con movilidad
-- reducida, para mostrarlo en la tarjeta (no solo en la ficha).

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

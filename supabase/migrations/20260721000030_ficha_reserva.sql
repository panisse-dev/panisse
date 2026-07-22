-- ══════════════════════════════════════════════════════════════════
-- Ficha completa de la reserva (ver y editar) al estilo Precompro.
--   - Campos nuevos: viene con perro / con movilidad reducida.
--   - staff_reservation_detail: trae reserva + cliente + actividad del comensal.
--   - staff_update_reservation: edita personas, fecha, hora, datos del cliente,
--     comentario y los dos campos nuevos.
-- ══════════════════════════════════════════════════════════════════

alter table public.reservations add column if not exists pet_friendly boolean not null default false;
alter table public.reservations add column if not exists reduced_mobility boolean not null default false;

-- ── Ficha completa de una reserva ──
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

-- ── Editar la reserva (y el cliente vinculado) ──
create or replace function public.staff_update_reservation(p_code text, p_id uuid, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_loc text;
  v_res_loc text;
  v_client_id uuid;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  select location_id, client_id into v_res_loc, v_client_id from reservations where id = p_id;
  if v_res_loc is null then raise exception 'Reserva no encontrada'; end if;
  if v_loc is not null and v_res_loc <> v_loc then
    raise exception 'No autorizado' using errcode = '42501';
  end if;

  update reservations set
    party_size = case when p ? 'party' then greatest(1, least(50, (p->>'party')::int)) else party_size end,
    reserved_date = case when (p ? 'date') and nullif(p->>'date','') is not null then (p->>'date')::date else reserved_date end,
    reserved_time = case when (p ? 'time') and nullif(p->>'time','') is not null then (p->>'time')::time else reserved_time end,
    pet_friendly = case when p ? 'petFriendly' then (p->>'petFriendly')::boolean else pet_friendly end,
    reduced_mobility = case when p ? 'reducedMobility' then (p->>'reducedMobility')::boolean else reduced_mobility end,
    staff_note = case when p ? 'staffNote' then left(coalesce(p->>'staffNote',''), 500) else staff_note end,
    customer_name = case when (p ? 'name') and btrim(coalesce(p->>'name','')) <> '' then left(btrim(p->>'name'), 80) else customer_name end,
    customer_phone = case when p ? 'phone' then left(btrim(coalesce(p->>'phone','')), 40) else customer_phone end,
    customer_email = case when p ? 'email' then lower(left(btrim(coalesce(p->>'email','')), 120)) else customer_email end
  where id = p_id;

  if v_client_id is not null then
    update clients set
      name = case when (p ? 'name') and btrim(coalesce(p->>'name','')) <> '' then left(btrim(p->>'name'), 80) else name end,
      phone = case when (p ? 'phone') and btrim(coalesce(p->>'phone','')) <> '' then left(btrim(p->>'phone'), 40) else phone end,
      email = case when p ? 'email' then nullif(lower(left(btrim(coalesce(p->>'email','')), 120)), '') else email end,
      birthday = case when p ? 'birthday' then nullif(p->>'birthday','')::date else birthday end,
      last_activity_at = now()
    where id = v_client_id;
  end if;
end
$$;

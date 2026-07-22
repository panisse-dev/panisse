-- ══════════════════════════════════════════════════════════════════
-- El cliente elige su mesa en el mapa al reservar
--
-- Se expone el plano del salón (público) con qué mesas están libres para la
-- fecha y hora pedidas, y create_reservation acepta la mesa elegida (validando
-- que sea de la sede y que siga libre a esa hora). Elegir mesa es OPCIONAL:
-- si no elige, el restaurante la asigna después.
-- ══════════════════════════════════════════════════════════════════

-- Mapa público con disponibilidad por fecha/hora.
create or replace function public.public_floor(p_location text, p_date date, p_time time)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  s reservation_settings%rowtype;
  v_loc text := coalesce(nullif(p_location,''), 'cerritos');
  v_turn int;
  v_m int := mins_of(p_time);
begin
  select * into s from reservation_settings where id;
  v_turn := greatest(greatest(5, s.slot_minutes), s.turn_minutes);

  return jsonb_build_object(
    'zones', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', z.id, 'name', z.name,
        'tables', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id, 'name', t.name, 'seats', t.seats,
            'posX', t.pos_x, 'posY', t.pos_y, 'width', t.width, 'height', t.height, 'shape', t.shape,
            'available', not exists (
              select 1 from reservations r
              where r.table_id = t.id and r.reserved_date = p_date
                and r.status in ('pendiente','confirmada','cumplida')
                and mins_of(r.reserved_time) < v_m + v_turn
                and mins_of(r.reserved_time) + v_turn > v_m
            )
          ) order by t.sort, t.name)
          from restaurant_tables t where t.zone_id = z.id and t.active
        ), '[]'::jsonb)
      ) order by z.sort, z.name)
      from zones z where z.location_id = v_loc
    ), '[]'::jsonb)
  );
end
$$;

-- create_reservation: acepta la mesa elegida (opcional) y la valida.
create or replace function public.create_reservation(p jsonb)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  s reservation_settings%rowtype;
  v_name text := left(btrim(coalesce(p->>'name','')), 80);
  v_phone text := left(btrim(coalesce(p->>'phone','')), 40);
  v_email text := lower(left(btrim(coalesce(p->>'email','')), 120));
  v_note text := left(btrim(coalesce(p->>'note','')), 300);
  v_location text := coalesce(nullif(p->>'location',''), 'cerritos');
  v_date date;
  v_time time;
  v_party int := coalesce(nullif(p->>'party','')::int, 0);
  v_today date := (now() at time zone 'America/Bogota')::date;
  v_now_min int := mins_of((now() at time zone 'America/Bogota')::time);
  v_dow int;
  v_m int;
  v_sub int;
  v_slot int;
  v_turn int;
  v_peak int;
  v_load int;
  v_phone_digits text;
  v_client clients%rowtype;
  v_client_id uuid;
  v_code text;
  v_id uuid;
  v_deposit int;
  v_table uuid := nullif(p->>'table','')::uuid;
  v_tbl_loc text;
begin
  select * into s from reservation_settings where id;
  if not s.enabled then raise exception 'Las reservas no están disponibles por ahora.'; end if;

  if v_name = '' then raise exception 'Escribe tu nombre'; end if;
  if v_email = '' or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Escribe un correo válido';
  end if;
  if v_party < 1 or v_party > s.max_party then
    raise exception 'El número de personas no es válido';
  end if;
  if not exists (select 1 from locations where id = v_location and active) then
    v_location := 'cerritos';
  end if;

  begin
    v_date := (p->>'date')::date;
    v_time := (p->>'time')::time;
  exception when others then
    raise exception 'Fecha u hora no válidas';
  end;

  if v_date < v_today or v_date > v_today + s.advance_days then
    raise exception 'Esa fecha no está disponible';
  end if;
  v_dow := extract(isodow from v_date)::int;
  if not (v_dow = any(s.open_days)) then
    raise exception 'Ese día no recibimos reservas';
  end if;
  if reservation_day_blocked(v_location, v_date) then
    raise exception 'Ese día no estamos recibiendo reservas';
  end if;

  v_slot := greatest(5, s.slot_minutes);
  v_turn := greatest(v_slot, s.turn_minutes);
  v_m := mins_of(v_time);
  if v_m < mins_of(s.start_time) or v_m > mins_of(s.end_time) then
    raise exception 'Esa hora no está disponible';
  end if;
  if v_date = v_today and v_m < v_now_min + s.min_hours * 60 then
    raise exception 'Esa hora ya es muy pronto, elige una más adelante';
  end if;
  if reservation_min_blocked(v_location, v_date, v_m) then
    raise exception 'Esa hora no está disponible';
  end if;

  perform pg_advisory_xact_lock(hashtext('reserva:' || v_location || ':' || v_date::text));

  v_peak := 0;
  v_sub := v_m;
  while v_sub < v_m + v_turn loop
    select coalesce(sum(r.party_size), 0) into v_load
    from reservations r
    where r.reserved_date = v_date
      and r.location_id = v_location
      and r.status in ('pendiente', 'confirmada')
      and mins_of(r.reserved_time) <= v_sub
      and mins_of(r.reserved_time) + v_turn > v_sub;
    if v_load > v_peak then v_peak := v_load; end if;
    v_sub := v_sub + v_slot;
  end loop;
  if v_peak + v_party > s.capacity then
    raise exception 'Esa hora se acaba de llenar, elige otra por favor';
  end if;

  -- Mesa elegida (opcional): debe ser de la sede y seguir libre a esa hora.
  if v_table is not null then
    select location_id into v_tbl_loc from restaurant_tables where id = v_table and active;
    if v_tbl_loc is null or v_tbl_loc <> v_location then
      raise exception 'Esa mesa no está disponible';
    end if;
    if exists (
      select 1 from reservations r
      where r.table_id = v_table and r.reserved_date = v_date
        and r.status in ('pendiente','confirmada','cumplida')
        and mins_of(r.reserved_time) < v_m + v_turn
        and mins_of(r.reserved_time) + v_turn > v_m
    ) then
      raise exception 'Esa mesa se acaba de reservar, elige otra por favor';
    end if;
  end if;

  v_phone_digits := nullif(regexp_replace(v_phone, '\D', '', 'g'), '');
  select * into v_client from clients where lower(email) = v_email limit 1;
  if v_client.id is null and v_phone_digits is not null then
    select * into v_client from clients where phone_digits = v_phone_digits limit 1;
  end if;
  if v_client.id is not null then
    v_client_id := v_client.id;
    begin
      update clients set
        name = case when v_name <> '' then v_name else name end,
        phone = case when v_phone <> '' then v_phone else phone end,
        phone_digits = coalesce(phone_digits, v_phone_digits),
        email = coalesce(email, v_email),
        last_activity_at = now()
      where id = v_client_id;
    exception when unique_violation then
      update clients set last_activity_at = now() where id = v_client_id;
    end;
  else
    insert into clients (name, phone, phone_digits, email)
    values (v_name, v_phone, v_phone_digits, v_email)
    returning id into v_client_id;
  end if;

  v_deposit := s.deposit_per_person * v_party;
  v_code := nextval('reservation_code_seq')::text;

  insert into reservations (
    code, reserved_date, reserved_time, party_size, client_id,
    customer_name, customer_phone, customer_email, note, deposit_required,
    location_id, source, table_id
  ) values (
    v_code, v_date, v_time, v_party, v_client_id,
    v_name, v_phone, v_email, v_note, v_deposit,
    v_location, 'web', v_table
  ) returning id into v_id;

  return jsonb_build_object(
    'id', v_id, 'code', v_code, 'status', 'pendiente', 'depositRequired', v_deposit
  );
end
$$;

-- ══════════════════════════════════════════════════════════════════
-- Bloqueo de días y horas para reservas (como el calendario de Precompro)
--
-- El restaurante puede cerrar una fecha completa o un rango de horas de
-- una fecha, por sede (o para todas). La disponibilidad del cliente y la
-- creación de reservas consultan estos bloqueos, así nadie reserva en un
-- momento cerrado. Aditivo: si no hay bloqueos, todo se comporta igual.
-- ══════════════════════════════════════════════════════════════════

create table if not exists public.reservation_blocks (
  id uuid primary key default gen_random_uuid(),
  -- sede del bloqueo. null = aplica a TODAS las sedes.
  location_id text references public.locations(id) on delete cascade,
  block_date date not null,
  -- null,null = día completo. Si vienen, es un rango de minutos [start,end).
  start_min int,
  end_min int,
  reason text not null default '',
  created_at timestamptz not null default now(),
  check (
    (start_min is null and end_min is null)
    or (start_min is not null and end_min is not null and end_min > start_min)
  )
);
create index if not exists reservation_blocks_date_idx
  on public.reservation_blocks (block_date);

alter table public.reservation_blocks enable row level security; -- sólo por RPC

-- ── Helpers: ¿está bloqueado un día / un minuto en una sede? ──
-- Un bloqueo con location_id null aplica a todas las sedes.
create or replace function public.reservation_day_blocked(p_loc text, p_date date)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from reservation_blocks b
    where b.block_date = p_date
      and b.start_min is null
      and (b.location_id is null or b.location_id = p_loc)
  );
$$;

create or replace function public.reservation_min_blocked(p_loc text, p_date date, p_min int)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from reservation_blocks b
    where b.block_date = p_date
      and (b.location_id is null or b.location_id = p_loc)
      and (
        b.start_min is null  -- día completo
        or (b.start_min <= p_min and b.end_min > p_min)
      )
  );
$$;

-- ── Disponibilidad: ahora también respeta los bloqueos ──
create or replace function public.reservation_availability(p_date date, p_party int default 2, p_location text default 'cerritos')
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  s reservation_settings%rowtype;
  v_dow int;
  v_today date := (now() at time zone 'America/Bogota')::date;
  v_now_min int := mins_of((now() at time zone 'America/Bogota')::time);
  v_party int := greatest(1, coalesce(p_party, 2));
  v_loc text := coalesce(nullif(p_location,''), 'cerritos');
  v_start int;
  v_end int;
  v_slot int;
  v_turn int;
  v_m int;
  v_sub int;
  v_peak int;
  v_load int;
  v_ok boolean;
  v_slots jsonb := '[]'::jsonb;
begin
  select * into s from reservation_settings where id;

  if not s.enabled then
    return jsonb_build_object('open', false, 'reason', 'Las reservas no están disponibles por ahora.', 'slots', '[]'::jsonb);
  end if;
  if p_date < v_today then
    return jsonb_build_object('open', false, 'reason', 'Esa fecha ya pasó.', 'slots', '[]'::jsonb);
  end if;
  if p_date > v_today + s.advance_days then
    return jsonb_build_object('open', false, 'reason', 'Aún no abrimos reservas para esa fecha.', 'slots', '[]'::jsonb);
  end if;
  v_dow := extract(isodow from p_date)::int;
  if not (v_dow = any(s.open_days)) then
    return jsonb_build_object('open', false, 'reason', 'Ese día no recibimos reservas.', 'slots', '[]'::jsonb);
  end if;
  if reservation_day_blocked(v_loc, p_date) then
    return jsonb_build_object('open', false, 'reason', 'Ese día no estamos recibiendo reservas.', 'slots', '[]'::jsonb);
  end if;
  if v_party > s.max_party then
    return jsonb_build_object('open', false, 'reason',
      'Para grupos de más de ' || s.max_party || ' personas, escríbenos.', 'slots', '[]'::jsonb);
  end if;

  v_start := mins_of(s.start_time);
  v_end := mins_of(s.end_time);
  v_slot := greatest(5, s.slot_minutes);
  v_turn := greatest(v_slot, s.turn_minutes);

  v_m := v_start;
  while v_m <= v_end loop
    v_ok := true;
    if p_date = v_today and v_m < v_now_min + s.min_hours * 60 then
      v_ok := false;
    end if;
    if v_ok and reservation_min_blocked(v_loc, p_date, v_m) then
      v_ok := false;
    end if;
    if v_ok then
      v_peak := 0;
      v_sub := v_m;
      while v_sub < v_m + v_turn loop
        select coalesce(sum(r.party_size), 0) into v_load
        from reservations r
        where r.reserved_date = p_date
          and r.location_id = v_loc
          and r.status in ('pendiente', 'confirmada')
          and mins_of(r.reserved_time) <= v_sub
          and mins_of(r.reserved_time) + v_turn > v_sub;
        if v_load > v_peak then v_peak := v_load; end if;
        v_sub := v_sub + v_slot;
      end loop;
      if v_peak + v_party > s.capacity then
        v_ok := false;
      end if;
    end if;
    v_slots := v_slots || jsonb_build_object(
      'time', to_char((v_m / 60) * interval '1 hour' + (v_m % 60) * interval '1 minute', 'HH24:MI'),
      'available', v_ok
    );
    v_m := v_m + v_slot;
  end loop;

  return jsonb_build_object('open', true, 'reason', '', 'slots', v_slots);
end
$$;

-- ── Crear reserva: rechaza días u horas bloqueadas ──
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
    customer_name, customer_phone, customer_email, note, deposit_required, location_id
  ) values (
    v_code, v_date, v_time, v_party, v_client_id,
    v_name, v_phone, v_email, v_note, v_deposit, v_location
  ) returning id into v_id;

  return jsonb_build_object(
    'id', v_id, 'code', v_code, 'status', 'pendiente', 'depositRequired', v_deposit
  );
end
$$;

-- ══════════════════════════════════════════════════════════════════
-- Panel: gestionar bloqueos
-- Un código de sede sólo maneja los bloqueos de SU sede. El código dueño
-- (sin sede) puede crear bloqueos para una sede o para todas.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_reservation_blocks(p_code text, p_from date default null, p_to date default null)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_loc text;
  v_from date := coalesce(p_from, (now() at time zone 'America/Bogota')::date);
  v_to date := coalesce(p_to, (now() at time zone 'America/Bogota')::date + 120);
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', b.id,
      'date', b.block_date,
      'allDay', b.start_min is null,
      'startTime', case when b.start_min is null then null
        else to_char((b.start_min/60)*interval '1 hour' + (b.start_min%60)*interval '1 minute', 'HH24:MI') end,
      'endTime', case when b.end_min is null then null
        else to_char((b.end_min/60)*interval '1 hour' + (b.end_min%60)*interval '1 minute', 'HH24:MI') end,
      'reason', b.reason,
      'locationId', b.location_id,
      'locationName', coalesce((select l.name from locations l where l.id = b.location_id), 'Todas las sedes')
    ) order by b.block_date, b.start_min nulls first)
    from reservation_blocks b
    where b.block_date between v_from and v_to
      and (v_loc is null or b.location_id is null or b.location_id = v_loc)
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_add_reservation_block(p_code text, p jsonb)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_staff_loc text;
  v_loc text;
  v_date date;
  v_all boolean := coalesce((p->>'allDay')::boolean, true);
  v_start int;
  v_end int;
  v_reason text := left(btrim(coalesce(p->>'reason','')), 200);
  v_id uuid;
begin
  perform assert_staff(p_code);
  v_staff_loc := staff_location(p_code);

  begin
    v_date := (p->>'date')::date;
  exception when others then
    raise exception 'Fecha no válida';
  end;

  -- La sede: si el código es de una sede, se fuerza esa. El dueño elige
  -- (o null = todas).
  if v_staff_loc is not null then
    v_loc := v_staff_loc;
  else
    v_loc := nullif(p->>'location','');
    if v_loc is not null and not exists (select 1 from locations where id = v_loc) then
      raise exception 'Sede no válida';
    end if;
  end if;

  if v_all then
    v_start := null;
    v_end := null;
  else
    v_start := mins_of((p->>'startTime')::time);
    v_end := mins_of((p->>'endTime')::time);
    if v_start is null or v_end is null or v_end <= v_start then
      raise exception 'El rango de horas no es válido';
    end if;
  end if;

  insert into reservation_blocks (location_id, block_date, start_min, end_min, reason)
  values (v_loc, v_date, v_start, v_end, v_reason)
  returning id into v_id;
  return v_id;
end
$$;

create or replace function public.staff_remove_reservation_block(p_code text, p_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  delete from reservation_blocks b
  where b.id = p_id
    and (v_loc is null or b.location_id is null or b.location_id = v_loc);
end
$$;

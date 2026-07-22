-- ══════════════════════════════════════════════════════════════════
-- Origen de las reservas y métricas más completas
--
-- Cada reserva guarda POR DÓNDE llegó: página web, teléfono, Google o
-- presencial (walk-in). El personal puede crear una reserva a mano (cuando
-- llaman o llega por Google) y marcar su origen. Las estadísticas suman por
-- origen, por comida (desayuno/almuerzo/cena), permiten filtrar de una fecha
-- a otra, y muestran Total y Total efectivas con sus personas.
-- ══════════════════════════════════════════════════════════════════

-- Origen: 'web' (formulario en línea), 'telefono', 'google', 'walkin'
-- (presencial), 'otro'. Texto libre validado en las funciones.
alter table public.reservations
  add column if not exists source text not null default 'web';

-- Las que ya existían venían del formulario web; las walk-in ya se marcan aparte.
update public.reservations set source = 'walkin' where is_walk_in and source = 'web';

-- create_reservation (cliente en línea) deja constancia del origen web.
-- (Sólo añade el source; el resto es idéntico a la versión vigente.)
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
    customer_name, customer_phone, customer_email, note, deposit_required, location_id, source
  ) values (
    v_code, v_date, v_time, v_party, v_client_id,
    v_name, v_phone, v_email, v_note, v_deposit, v_location, 'web'
  ) returning id into v_id;

  return jsonb_build_object(
    'id', v_id, 'code', v_code, 'status', 'pendiente', 'depositRequired', v_deposit
  );
end
$$;

-- Walk-in deja constancia de origen presencial.
create or replace function public.staff_walkin(p_code text, p jsonb)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_loc text;
  v_target_loc text;
  v_name text := left(btrim(coalesce(p->>'name','')), 80);
  v_phone text := left(btrim(coalesce(p->>'phone','')), 40);
  v_party int := coalesce(nullif(p->>'party','')::int, 0);
  v_note text := left(btrim(coalesce(p->>'note','')), 300);
  v_table uuid;
  v_tbl_loc text;
  v_now time := (now() at time zone 'America/Bogota')::time;
  v_today date := (now() at time zone 'America/Bogota')::date;
  v_phone_digits text;
  v_client_id uuid;
  v_code text;
  v_id uuid;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  if v_party < 1 or v_party > 50 then raise exception 'Número de personas no válido'; end if;
  if v_name = '' then v_name := 'Walk-In'; end if;
  if v_loc is not null then v_target_loc := v_loc;
  else v_target_loc := coalesce(nullif(p->>'location',''), 'cerritos'); end if;
  if not exists (select 1 from locations where id = v_target_loc) then
    raise exception 'Sede no válida';
  end if;
  v_table := nullif(p->>'table','')::uuid;
  if v_table is not null then
    select location_id into v_tbl_loc from restaurant_tables where id = v_table;
    if v_tbl_loc is null or v_tbl_loc <> v_target_loc then
      raise exception 'Esa mesa no es de esta sede';
    end if;
  end if;
  v_phone_digits := nullif(regexp_replace(v_phone, '\D', '', 'g'), '');
  if v_phone_digits is not null then
    select id into v_client_id from clients where phone_digits = v_phone_digits limit 1;
    if v_client_id is null then
      insert into clients (name, phone, phone_digits) values (v_name, v_phone, v_phone_digits)
      returning id into v_client_id;
    else
      update clients set last_activity_at = now() where id = v_client_id;
    end if;
  end if;
  v_code := nextval('reservation_code_seq')::text;
  insert into reservations (
    code, reserved_date, reserved_time, party_size, client_id,
    customer_name, customer_phone, customer_email, note,
    status, is_walk_in, table_id, location_id, source
  ) values (
    v_code, v_today, v_now, v_party, v_client_id,
    v_name, v_phone, '', v_note,
    'confirmada', true, v_table, v_target_loc, 'walkin'
  ) returning id into v_id;
  return jsonb_build_object('id', v_id, 'code', v_code, 'status', 'confirmada');
end
$$;

-- ── Crear una reserva a mano (teléfono, Google, web, otro) ──
create or replace function public.staff_create_reservation(p_code text, p jsonb)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_loc text;
  v_target_loc text;
  v_name text := left(btrim(coalesce(p->>'name','')), 80);
  v_phone text := left(btrim(coalesce(p->>'phone','')), 40);
  v_email text := lower(left(btrim(coalesce(p->>'email','')), 120));
  v_party int := coalesce(nullif(p->>'party','')::int, 0);
  v_note text := left(btrim(coalesce(p->>'note','')), 300);
  v_source text := lower(coalesce(nullif(p->>'source',''), 'telefono'));
  v_date date;
  v_time time;
  v_table uuid;
  v_tbl_loc text;
  v_phone_digits text;
  v_client_id uuid;
  v_code text;
  v_id uuid;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  if v_source not in ('web','telefono','google','walkin','otro') then v_source := 'otro'; end if;
  if v_party < 1 or v_party > 50 then raise exception 'Número de personas no válido'; end if;
  if v_name = '' then raise exception 'Escribe el nombre'; end if;

  begin
    v_date := (p->>'date')::date;
    v_time := (p->>'time')::time;
  exception when others then
    raise exception 'Fecha u hora no válidas';
  end;

  if v_loc is not null then v_target_loc := v_loc;
  else v_target_loc := coalesce(nullif(p->>'location',''), 'cerritos'); end if;
  if not exists (select 1 from locations where id = v_target_loc) then
    raise exception 'Sede no válida';
  end if;

  v_table := nullif(p->>'table','')::uuid;
  if v_table is not null then
    select location_id into v_tbl_loc from restaurant_tables where id = v_table;
    if v_tbl_loc is null or v_tbl_loc <> v_target_loc then
      raise exception 'Esa mesa no es de esta sede';
    end if;
  end if;

  -- Cliente por correo o teléfono (crea/actualiza; no bloquea si falta)
  v_phone_digits := nullif(regexp_replace(v_phone, '\D', '', 'g'), '');
  if v_email <> '' then
    select id into v_client_id from clients where lower(email) = v_email limit 1;
  end if;
  if v_client_id is null and v_phone_digits is not null then
    select id into v_client_id from clients where phone_digits = v_phone_digits limit 1;
  end if;
  if v_client_id is null and (v_phone_digits is not null or v_email <> '') then
    begin
      insert into clients (name, phone, phone_digits, email)
      values (v_name, v_phone, v_phone_digits, nullif(v_email,''))
      returning id into v_client_id;
    exception when unique_violation then
      select id into v_client_id from clients where phone_digits = v_phone_digits limit 1;
    end;
  elsif v_client_id is not null then
    update clients set last_activity_at = now() where id = v_client_id;
  end if;

  v_code := nextval('reservation_code_seq')::text;
  insert into reservations (
    code, reserved_date, reserved_time, party_size, client_id,
    customer_name, customer_phone, customer_email, note,
    status, is_walk_in, table_id, location_id, source
  ) values (
    v_code, v_date, v_time, v_party, v_client_id,
    v_name, v_phone, nullif(v_email,''), v_note,
    'confirmada', false, v_table, v_target_loc, v_source
  ) returning id into v_id;
  return jsonb_build_object('id', v_id, 'code', v_code, 'status', 'confirmada');
end
$$;

-- Cambiar el origen de una reserva desde el panel.
create or replace function public.staff_set_reservation_source(p_code text, p_id uuid, p_source text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_src text := lower(coalesce(p_source,''));
begin
  perform assert_staff(p_code);
  if v_src not in ('web','telefono','google','walkin','otro') then
    raise exception 'Origen inválido';
  end if;
  update reservations set source = v_src where id = p_id;
end
$$;

-- ── Reservas del día: ahora traen el origen ──
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
      'tableId', r.table_id,
      'tableName', (select t.name from restaurant_tables t where t.id = r.table_id)
    ) order by r.reserved_time, r.created_at)
    from reservations r
    where r.reserved_date = v_day
      and (v_loc is null or r.location_id = v_loc)
  ), '[]'::jsonb);
end
$$;

-- ── Estadísticas: Total / Total efectivas con personas, por origen y por comida ──
create or replace function public.staff_reservation_stats(p_code text, p_from date, p_to date)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_loc text;
  v_from date := coalesce(p_from, (now() at time zone 'America/Bogota')::date - 29);
  v_to date := coalesce(p_to, (now() at time zone 'America/Bogota')::date);
  v_result jsonb;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);

  with base as (
    select r.*,
      case
        when extract(hour from r.reserved_time) < 11 then 'desayuno'
        when extract(hour from r.reserved_time) < 16 then 'almuerzo'
        else 'cena'
      end as meal
    from reservations r
    where r.reserved_date between v_from and v_to
      and (v_loc is null or r.location_id = v_loc)
  ),
  eff as (select * from base where status in ('confirmada','cumplida'))
  select jsonb_build_object(
    'kpis', jsonb_build_object(
      'total', (select count(*) from base where status <> 'cancelada'),
      'totalPeople', (select coalesce(sum(party_size),0) from base where status not in ('cancelada','no_show')),
      'effective', (select count(*) from eff),
      'effectivePeople', (select coalesce(sum(party_size),0) from eff),
      'pending', (select count(*) from base where status = 'pendiente'),
      'noShow', (select count(*) from base where status = 'no_show'),
      'cancelled', (select count(*) from base where status = 'cancelada'),
      'avgParty', (select round(avg(party_size)::numeric, 1) from base where status <> 'cancelada')
    ),
    'byDay', coalesce((
      select jsonb_agg(jsonb_build_object('day', d.day, 'count', d.cnt, 'people', d.ppl) order by d.day)
      from (
        select reserved_date as day,
               count(*) filter (where status <> 'cancelada') as cnt,
               coalesce(sum(party_size) filter (where status not in ('cancelada','no_show')),0) as ppl
        from base group by reserved_date
      ) d
    ), '[]'::jsonb),
    'byMonth', coalesce((
      select jsonb_agg(jsonb_build_object('month', m.mon, 'count', m.cnt, 'people', m.ppl) order by m.mon)
      from (
        select to_char(reserved_date, 'YYYY-MM') as mon,
               count(*) filter (where status <> 'cancelada') as cnt,
               coalesce(sum(party_size) filter (where status not in ('cancelada','no_show')),0) as ppl
        from base group by to_char(reserved_date, 'YYYY-MM')
      ) m
    ), '[]'::jsonb),
    'byHour', coalesce((
      select jsonb_agg(jsonb_build_object('hour', h.hr, 'count', h.cnt) order by h.hr)
      from (
        select extract(hour from reserved_time)::int as hr, count(*) as cnt
        from base where status <> 'cancelada'
        group by extract(hour from reserved_time)::int
      ) h
    ), '[]'::jsonb),
    'byMeal', jsonb_build_object(
      'desayuno', (select count(*) from base where status <> 'cancelada' and meal = 'desayuno'),
      'almuerzo', (select count(*) from base where status <> 'cancelada' and meal = 'almuerzo'),
      'cena', (select count(*) from base where status <> 'cancelada' and meal = 'cena')
    ),
    'byOrigin', coalesce((
      select jsonb_agg(jsonb_build_object('source', o.src, 'count', o.cnt) order by o.cnt desc)
      from (
        select source as src, count(*) as cnt
        from base where status <> 'cancelada'
        group by source
      ) o
    ), '[]'::jsonb),
    'byStatus', jsonb_build_object(
      'pendiente', (select count(*) from base where status = 'pendiente'),
      'confirmada', (select count(*) from base where status = 'confirmada'),
      'cumplida', (select count(*) from base where status = 'cumplida'),
      'no_show', (select count(*) from base where status = 'no_show'),
      'cancelada', (select count(*) from base where status = 'cancelada')
    ),
    'byLocation', coalesce((
      select jsonb_agg(jsonb_build_object('id', x.lid, 'name', l.name, 'count', x.cnt) order by x.cnt desc)
      from (
        select location_id as lid, count(*) as cnt
        from base where status <> 'cancelada'
        group by location_id
      ) x join locations l on l.id = x.lid
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end
$$;

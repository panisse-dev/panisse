-- ══════════════════════════════════════════════════════════════════
-- Reservas de mesa (sede Cerritos)
--
-- Replica el flujo de Precompro: personas → fecha → hora (con
-- disponibilidad) → datos → confirmar. La disponibilidad se calcula por
-- CAPACIDAD (aforo simultáneo) y DURACIÓN DE MESA (turno): una reserva
-- ocupa su cupo desde la hora elegida hasta 'turn_minutes' después, así
-- no se sobrevende. Todo lo configurable lo maneja el restaurante desde
-- el panel. El abono queda preparado (montos) para enchufar una pasarela.
-- ══════════════════════════════════════════════════════════════════

-- ── Configuración (una sola fila, editable desde el panel) ──
create table if not exists public.reservation_settings (
  id boolean primary key default true check (id),
  enabled boolean not null default true,
  -- Días abiertos: ISO (1=lunes … 7=domingo). Por defecto lunes a sábado.
  open_days int[] not null default '{1,2,3,4,5,6}',
  start_time time not null default '08:00',
  end_time time not null default '20:00',
  slot_minutes int not null default 30,       -- cada cuánto una franja
  turn_minutes int not null default 90,       -- cuánto ocupa la mesa una reserva
  capacity int not null default 40,           -- personas que caben a la vez (aforo)
  max_party int not null default 6,           -- máximo de personas por reserva en línea
  advance_days int not null default 60,       -- con cuánta anticipación máxima
  min_hours int not null default 2,           -- mínimo de anticipación (horas)
  deposit_per_person int not null default 0,  -- abono por persona (0 = sin abono)
  updated_at timestamptz not null default now()
);
insert into public.reservation_settings (id) values (true)
  on conflict (id) do nothing;

-- ── Reservas ──
create sequence if not exists public.reservation_code_seq start 1001;

create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  created_at timestamptz not null default now(),
  reserved_date date not null,
  reserved_time time not null,
  party_size int not null check (party_size between 1 and 50),
  client_id uuid references public.clients(id) on delete set null,
  customer_name text not null,
  customer_phone text not null default '',
  customer_email text not null default '',
  note text not null default '',
  status text not null default 'pendiente'
    check (status in ('pendiente','confirmada','cancelada','cumplida','no_show')),
  status_at timestamptz not null default now(),
  deposit_required int not null default 0,   -- monto del abono para esta reserva
  deposit_paid boolean not null default false,
  staff_note text not null default ''
);
create index if not exists reservations_date_idx on public.reservations (reserved_date);
create index if not exists reservations_client_idx on public.reservations (client_id);

alter table public.reservation_settings enable row level security;
alter table public.reservations enable row level security;
-- Sin políticas: nadie accede directo; todo pasa por las funciones de abajo
-- (security definer), igual que pedidos y clientes.

-- ── Helper interno: minutos desde medianoche de un `time` ──
create or replace function public.mins_of(t time)
returns int language sql immutable as $$
  select (extract(hour from t) * 60 + extract(minute from t))::int
$$;

-- ══════════════════════════════════════════════════════════════════
-- Disponibilidad de un día para un tamaño de grupo
-- Devuelve { open, reason, slots: [{time:'HH:MM', available}] }
-- ══════════════════════════════════════════════════════════════════
create or replace function public.reservation_availability(p_date date, p_party int default 2)
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
  v_start int;
  v_end int;
  v_slot int;
  v_turn int;
  v_m int;         -- minuto de la franja candidata
  v_sub int;       -- sub-franja dentro del turno
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
  if v_party > s.max_party then
    return jsonb_build_object('open', false, 'reason',
      'Para grupos de más de ' || s.max_party || ' personas, escríbenos.', 'slots', '[]'::jsonb);
  end if;

  v_start := mins_of(s.start_time);
  v_end := mins_of(s.end_time);
  v_slot := greatest(5, s.slot_minutes);
  v_turn := greatest(v_slot, s.turn_minutes);

  -- Recorre cada franja candidata y calcula si cabe el grupo.
  v_m := v_start;
  while v_m <= v_end loop
    v_ok := true;

    -- Anticipación mínima: si es hoy, la franja debe estar suficientemente adelante.
    if p_date = v_today and v_m < v_now_min + s.min_hours * 60 then
      v_ok := false;
    end if;

    if v_ok then
      -- Pico de ocupación durante la estadía [v_m, v_m + turno): en cada
      -- sub-franja sumamos las reservas activas que la cubren.
      v_peak := 0;
      v_sub := v_m;
      while v_sub < v_m + v_turn loop
        select coalesce(sum(r.party_size), 0) into v_load
        from reservations r
        where r.reserved_date = p_date
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

-- ══════════════════════════════════════════════════════════════════
-- Config pública que necesita el cliente para armar el flujo
-- ══════════════════════════════════════════════════════════════════
create or replace function public.reservation_config()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'enabled', s.enabled,
    'openDays', s.open_days,
    'startTime', to_char(s.start_time, 'HH24:MI'),
    'endTime', to_char(s.end_time, 'HH24:MI'),
    'slotMinutes', s.slot_minutes,
    'maxParty', s.max_party,
    'advanceDays', s.advance_days,
    'minHours', s.min_hours,
    'depositPerPerson', s.deposit_per_person
  )
  from reservation_settings s where s.id;
$$;

-- ══════════════════════════════════════════════════════════════════
-- Crear una reserva (valida disponibilidad de forma atómica)
-- ══════════════════════════════════════════════════════════════════
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

  -- Datos obligatorios
  if v_name = '' then raise exception 'Escribe tu nombre'; end if;
  if v_email = '' or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Escribe un correo válido';
  end if;
  if v_party < 1 or v_party > s.max_party then
    raise exception 'El número de personas no es válido';
  end if;

  begin
    v_date := (p->>'date')::date;
    v_time := (p->>'time')::time;
  exception when others then
    raise exception 'Fecha u hora no válidas';
  end;

  -- Reglas de fecha/hora
  if v_date < v_today or v_date > v_today + s.advance_days then
    raise exception 'Esa fecha no está disponible';
  end if;
  v_dow := extract(isodow from v_date)::int;
  if not (v_dow = any(s.open_days)) then
    raise exception 'Ese día no recibimos reservas';
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

  -- Candado por fecha: evita que dos personas reserven el último cupo a la vez.
  perform pg_advisory_xact_lock(hashtext('reserva:' || v_date::text));

  -- Revisa la capacidad durante toda la estadía
  v_peak := 0;
  v_sub := v_m;
  while v_sub < v_m + v_turn loop
    select coalesce(sum(r.party_size), 0) into v_load
    from reservations r
    where r.reserved_date = v_date
      and r.status in ('pendiente', 'confirmada')
      and mins_of(r.reserved_time) <= v_sub
      and mins_of(r.reserved_time) + v_turn > v_sub;
    if v_load > v_peak then v_peak := v_load; end if;
    v_sub := v_sub + v_slot;
  end loop;
  if v_peak + v_party > s.capacity then
    raise exception 'Esa hora se acaba de llenar, elige otra por favor';
  end if;

  -- Cliente: por correo → por teléfono → nuevo (reutiliza la misma tabla)
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
    customer_name, customer_phone, customer_email, note, deposit_required
  ) values (
    v_code, v_date, v_time, v_party, v_client_id,
    v_name, v_phone, v_email, v_note, v_deposit
  ) returning id into v_id;

  return jsonb_build_object(
    'id', v_id, 'code', v_code, 'status', 'pendiente', 'depositRequired', v_deposit
  );
end
$$;

-- El cliente sigue su reserva (estado público)
create or replace function public.get_reservation_public(p_id uuid)
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'code', r.code, 'status', r.status,
    'date', r.reserved_date, 'time', to_char(r.reserved_time, 'HH24:MI'),
    'party', r.party_size, 'depositPaid', r.deposit_paid
  )
  from reservations r where r.id = p_id;
$$;

-- ══════════════════════════════════════════════════════════════════
-- Panel del personal
-- ══════════════════════════════════════════════════════════════════

-- Reservas de un día (por defecto hoy)
create or replace function public.staff_reservations(p_code text, p_day date default null)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_day date := coalesce(p_day, (now() at time zone 'America/Bogota')::date);
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', r.id,
      'code', r.code,
      'date', r.reserved_date,
      'time', to_char(r.reserved_time, 'HH24:MI'),
      'party', r.party_size,
      'status', r.status,
      'createdAt', r.created_at,
      'customer', jsonb_build_object('name', r.customer_name, 'phone', r.customer_phone, 'email', r.customer_email),
      'note', r.note,
      'staffNote', r.staff_note,
      'depositRequired', r.deposit_required,
      'depositPaid', r.deposit_paid
    ) order by r.reserved_time, r.created_at)
    from reservations r
    where r.reserved_date = v_day
  ), '[]'::jsonb);
end
$$;

-- Cuántas reservas próximas hay (para el conteo del panel)
create or replace function public.staff_reservations_upcoming(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_today date := (now() at time zone 'America/Bogota')::date;
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object('day', d.reserved_date, 'total', d.total, 'pendientes', d.pend) order by d.reserved_date)
    from (
      select r.reserved_date,
             count(*) as total,
             count(*) filter (where r.status = 'pendiente') as pend
      from reservations r
      where r.reserved_date >= v_today and r.status <> 'cancelada'
      group by r.reserved_date
    ) d
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_set_reservation_status(p_code text, p_id uuid, p_status text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  if p_status not in ('pendiente','confirmada','cancelada','cumplida','no_show') then
    raise exception 'Estado inválido';
  end if;
  update reservations set status = p_status, status_at = now() where id = p_id;
end
$$;

create or replace function public.staff_set_reservation_note(p_code text, p_id uuid, p_note text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update reservations set staff_note = left(btrim(coalesce(p_note,'')), 300) where id = p_id;
end
$$;

create or replace function public.staff_set_reservation_deposit(p_code text, p_id uuid, p_paid boolean)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update reservations set deposit_paid = coalesce(p_paid, false) where id = p_id;
end
$$;

-- Leer / actualizar la configuración de reservas desde el panel
create or replace function public.staff_reservation_settings(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return (
    select jsonb_build_object(
      'enabled', s.enabled,
      'openDays', s.open_days,
      'startTime', to_char(s.start_time, 'HH24:MI'),
      'endTime', to_char(s.end_time, 'HH24:MI'),
      'slotMinutes', s.slot_minutes,
      'turnMinutes', s.turn_minutes,
      'capacity', s.capacity,
      'maxParty', s.max_party,
      'advanceDays', s.advance_days,
      'minHours', s.min_hours,
      'depositPerPerson', s.deposit_per_person
    )
    from reservation_settings s where s.id
  );
end
$$;

create or replace function public.staff_update_reservation_settings(p_code text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update reservation_settings set
    enabled = coalesce((p->>'enabled')::boolean, enabled),
    open_days = coalesce((select array_agg(x)::int[] from jsonb_array_elements_text(p->'openDays') t(x)), open_days),
    start_time = coalesce((p->>'startTime')::time, start_time),
    end_time = coalesce((p->>'endTime')::time, end_time),
    slot_minutes = greatest(5, coalesce((p->>'slotMinutes')::int, slot_minutes)),
    turn_minutes = greatest(15, coalesce((p->>'turnMinutes')::int, turn_minutes)),
    capacity = greatest(1, coalesce((p->>'capacity')::int, capacity)),
    max_party = greatest(1, coalesce((p->>'maxParty')::int, max_party)),
    advance_days = greatest(1, coalesce((p->>'advanceDays')::int, advance_days)),
    min_hours = greatest(0, coalesce((p->>'minHours')::int, min_hours)),
    deposit_per_person = greatest(0, coalesce((p->>'depositPerPerson')::int, deposit_per_person)),
    updated_at = now()
  where id;
end
$$;

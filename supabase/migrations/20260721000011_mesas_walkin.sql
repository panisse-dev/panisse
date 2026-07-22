-- ══════════════════════════════════════════════════════════════════
-- Plano de mesas + Walk-In (como el salón de Precompro)
--
-- Cada sede tiene ZONAS (Roka I, Toscana…) y cada zona sus MESAS con su
-- capacidad. En el panel se ve el salón por zonas, se asigna una reserva a
-- una mesa, y se registra un Walk-In (cliente que llega sin reservar) que
-- entra ya sentado. El aforo total sigue mandando la disponibilidad en
-- línea; las mesas son la capa de operación de la casa.
-- ══════════════════════════════════════════════════════════════════

create table if not exists public.zones (
  id uuid primary key default gen_random_uuid(),
  location_id text not null references public.locations(id) on delete cascade,
  name text not null,
  sort int not null default 0
);
create index if not exists zones_location_idx on public.zones (location_id);

create table if not exists public.restaurant_tables (
  id uuid primary key default gen_random_uuid(),
  zone_id uuid not null references public.zones(id) on delete cascade,
  location_id text not null references public.locations(id) on delete cascade,
  name text not null,
  seats int not null default 2 check (seats between 1 and 40),
  sort int not null default 0,
  active boolean not null default true
);
create index if not exists tables_zone_idx on public.restaurant_tables (zone_id);
create index if not exists tables_location_idx on public.restaurant_tables (location_id);

alter table public.zones enable row level security;             -- sólo por RPC
alter table public.restaurant_tables enable row level security; -- sólo por RPC

-- Marca de mesa y de walk-in en las reservas.
alter table public.reservations
  add column if not exists table_id uuid references public.restaurant_tables(id) on delete set null,
  add column if not exists is_walk_in boolean not null default false;

-- ── Semilla de zonas y mesas (editable luego) ──
-- Sólo se siembra si la sede aún no tiene zonas, para no duplicar.
do $$
declare
  v_zone uuid;
begin
  -- ═══ Cerritos ═══
  if not exists (select 1 from zones where location_id = 'cerritos') then
    insert into zones (location_id, name, sort) values ('cerritos','Roka I',1) returning id into v_zone;
    insert into restaurant_tables (zone_id, location_id, name, seats, sort) values
      (v_zone,'cerritos','1',2,1),(v_zone,'cerritos','2',2,2),(v_zone,'cerritos','3',4,3),
      (v_zone,'cerritos','4',4,4),(v_zone,'cerritos','5',6,5),(v_zone,'cerritos','6',6,6);

    insert into zones (location_id, name, sort) values ('cerritos','Roka II',2) returning id into v_zone;
    insert into restaurant_tables (zone_id, location_id, name, seats, sort) values
      (v_zone,'cerritos','21',4,1),(v_zone,'cerritos','22',4,2),(v_zone,'cerritos','24',5,3),
      (v_zone,'cerritos','25',6,4),(v_zone,'cerritos','B1',1,5),(v_zone,'cerritos','B2',1,6),
      (v_zone,'cerritos','B3',1,7),(v_zone,'cerritos','B4',1,8);

    insert into zones (location_id, name, sort) values ('cerritos','Toscana',3) returning id into v_zone;
    insert into restaurant_tables (zone_id, location_id, name, seats, sort) values
      (v_zone,'cerritos','27',8,1),(v_zone,'cerritos','28',4,2);
  end if;

  -- ═══ Pilares ═══
  if not exists (select 1 from zones where location_id = 'pilares') then
    insert into zones (location_id, name, sort) values ('pilares','Salón',1) returning id into v_zone;
    insert into restaurant_tables (zone_id, location_id, name, seats, sort) values
      (v_zone,'pilares','1',2,1),(v_zone,'pilares','2',2,2),(v_zone,'pilares','3',4,3),
      (v_zone,'pilares','4',4,4),(v_zone,'pilares','5',6,5);

    insert into zones (location_id, name, sort) values ('pilares','Terraza',2) returning id into v_zone;
    insert into restaurant_tables (zone_id, location_id, name, seats, sort) values
      (v_zone,'pilares','T1',4,1),(v_zone,'pilares','T2',4,2),(v_zone,'pilares','T3',6,3);
  end if;
end $$;

-- ── Reservas del día con su mesa (re-crea para incluir mesa y walk-in) ──
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
      'isWalkIn', r.is_walk_in,
      'tableId', r.table_id,
      'tableName', (select t.name from restaurant_tables t where t.id = r.table_id)
    ) order by r.reserved_time, r.created_at)
    from reservations r
    where r.reserved_date = v_day
      and (v_loc is null or r.location_id = v_loc)
  ), '[]'::jsonb);
end
$$;

-- ── El salón: zonas → mesas, con la reserva de HOY asignada a cada mesa ──
create or replace function public.staff_floor(p_code text, p_day date default null, p_location text default null)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_day date := coalesce(p_day, (now() at time zone 'America/Bogota')::date);
  v_staff_loc text;
  v_loc text;
begin
  perform assert_staff(p_code);
  v_staff_loc := staff_location(p_code);
  -- Un código de sede sólo ve la suya. El dueño puede pedir una sede concreta.
  if v_staff_loc is not null then
    v_loc := v_staff_loc;
  else
    v_loc := coalesce(nullif(p_location,''), 'cerritos');
  end if;

  return jsonb_build_object(
    'locationId', v_loc,
    'zones', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', z.id, 'name', z.name,
        'tables', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id, 'name', t.name, 'seats', t.seats,
            'reservations', coalesce((
              select jsonb_agg(jsonb_build_object(
                'id', r.id, 'time', to_char(r.reserved_time,'HH24:MI'), 'party', r.party_size,
                'name', r.customer_name, 'status', r.status, 'isWalkIn', r.is_walk_in
              ) order by r.reserved_time)
              from reservations r
              where r.table_id = t.id and r.reserved_date = v_day
                and r.status not in ('cancelada','no_show')
            ), '[]'::jsonb)
          ) order by t.sort, t.name)
          from restaurant_tables t where t.zone_id = z.id and t.active
        ), '[]'::jsonb)
      ) order by z.sort, z.name)
      from zones z where z.location_id = v_loc
    ), '[]'::jsonb)
  );
end
$$;

-- ── Asignar (o quitar) la mesa de una reserva ──
create or replace function public.staff_assign_table(p_code text, p_reservation uuid, p_table uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_loc text;
  v_res_loc text;
  v_tbl_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);

  select location_id into v_res_loc from reservations where id = p_reservation;
  if v_res_loc is null then raise exception 'Reserva no encontrada'; end if;
  if v_loc is not null and v_res_loc <> v_loc then raise exception 'No autorizado' using errcode = '42501'; end if;

  if p_table is not null then
    select location_id into v_tbl_loc from restaurant_tables where id = p_table;
    if v_tbl_loc is null then raise exception 'Mesa no encontrada'; end if;
    if v_tbl_loc <> v_res_loc then raise exception 'Esa mesa es de otra sede'; end if;
  end if;

  update reservations set table_id = p_table where id = p_reservation;
end
$$;

-- ── Registrar un Walk-In (cliente que llega sin reservar, entra sentado) ──
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

  -- Sede destino
  if v_loc is not null then
    v_target_loc := v_loc;
  else
    v_target_loc := coalesce(nullif(p->>'location',''), 'cerritos');
  end if;
  if not exists (select 1 from locations where id = v_target_loc) then
    raise exception 'Sede no válida';
  end if;

  -- Mesa (opcional) y que sea de la sede
  v_table := nullif(p->>'table','')::uuid;
  if v_table is not null then
    select location_id into v_tbl_loc from restaurant_tables where id = v_table;
    if v_tbl_loc is null or v_tbl_loc <> v_target_loc then
      raise exception 'Esa mesa no es de esta sede';
    end if;
  end if;

  -- Cliente por teléfono si lo dieron
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
    status, is_walk_in, table_id, location_id
  ) values (
    v_code, v_today, v_now, v_party, v_client_id,
    v_name, v_phone, '', v_note,
    'confirmada', true, v_table, v_target_loc
  ) returning id into v_id;

  return jsonb_build_object('id', v_id, 'code', v_code, 'status', 'confirmada');
end
$$;

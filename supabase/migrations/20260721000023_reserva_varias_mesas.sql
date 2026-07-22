-- ══════════════════════════════════════════════════════════════════
-- Una reserva puede ocupar VARIAS mesas
--
-- Antes cada reserva tenía una sola mesa (reservations.table_id). Para un
-- grupo grande (ej. 8 personas) que no cabe en una mesa de 6, había que
-- juntar dos mesas — y no se podía: quedaba sin mesa y el plano no marcaba
-- nada. Ahora una reserva puede tener 1..N mesas, guardadas en la tabla
-- puente reservation_tables, y TODAS se pintan ocupadas en el plano.
--
-- Se conserva reservations.table_id como "primera mesa" para que el resto
-- del sistema (y las reservas del cliente que elige una mesa) siga igual:
-- la ocupación se lee como la UNIÓN de table_id + reservation_tables.
-- ══════════════════════════════════════════════════════════════════

create table if not exists public.reservation_tables (
  reservation_id uuid not null references reservations(id) on delete cascade,
  table_id uuid not null references restaurant_tables(id) on delete cascade,
  primary key (reservation_id, table_id)
);

create index if not exists idx_reservation_tables_table on public.reservation_tables(table_id);

-- Sólo se toca por RPCs (security definer); nada de acceso directo.
alter table public.reservation_tables enable row level security;

-- Traer las mesas que ya estaban asignadas de a una.
insert into public.reservation_tables (reservation_id, table_id)
select id, table_id from public.reservations where table_id is not null
on conflict do nothing;

-- Lee las mesas del payload: 'tables' (arreglo de ids) o 'table' (una sola).
create or replace function public.reservation_tables_from_payload(p jsonb)
returns uuid[]
language plpgsql immutable
as $$
declare v_tables uuid[];
begin
  if jsonb_typeof(p->'tables') = 'array' then
    select array_agg(e::uuid) into v_tables
    from jsonb_array_elements_text(p->'tables') e
    where nullif(e, '') is not null;
  end if;
  if (v_tables is null or array_length(v_tables, 1) is null)
     and nullif(p->>'table', '') is not null then
    v_tables := array[(p->>'table')::uuid];
  end if;
  return coalesce(v_tables, array[]::uuid[]);
end
$$;

-- ══════════════════════════════════════════════════════════════════
-- Reemplazar el conjunto de mesas de una reserva (desde la tarjeta)
-- ══════════════════════════════════════════════════════════════════
create or replace function public.staff_set_reservation_tables(p_code text, p_reservation uuid, p_tables jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_loc text;
  v_res_loc text;
  v_first uuid;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);

  select location_id into v_res_loc from reservations where id = p_reservation;
  if v_res_loc is null then raise exception 'Reserva no encontrada'; end if;
  if v_loc is not null and v_res_loc <> v_loc then
    raise exception 'No autorizado' using errcode = '42501';
  end if;

  if p_tables is not null and jsonb_typeof(p_tables) = 'array' and jsonb_array_length(p_tables) > 0 then
    if exists (
      select 1 from jsonb_array_elements_text(p_tables) e
      left join restaurant_tables t on t.id = e::uuid
      where t.id is null or t.location_id <> v_res_loc
    ) then
      raise exception 'Alguna mesa no es de esta sede';
    end if;
  end if;

  delete from reservation_tables where reservation_id = p_reservation;

  if p_tables is not null and jsonb_typeof(p_tables) = 'array' and jsonb_array_length(p_tables) > 0 then
    insert into reservation_tables (reservation_id, table_id)
    select p_reservation, e::uuid from jsonb_array_elements_text(p_tables) e
    on conflict do nothing;
    select e::uuid into v_first from jsonb_array_elements_text(p_tables) e limit 1;
  else
    v_first := null;
  end if;

  update reservations set table_id = v_first where id = p_reservation;
end
$$;

-- ══════════════════════════════════════════════════════════════════
-- Plano: una mesa está ocupada por su table_id O por reservation_tables
-- ══════════════════════════════════════════════════════════════════
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
  if v_staff_loc is not null then
    v_loc := v_staff_loc;
  else
    v_loc := coalesce(nullif(p_location,''), 'cerritos');
  end if;

  return jsonb_build_object(
    'locationId', v_loc,
    'zones', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', z.id, 'name', z.name, 'sort', z.sort,
        'tables', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id, 'name', t.name, 'seats', t.seats,
            'posX', t.pos_x, 'posY', t.pos_y, 'width', t.width, 'height', t.height, 'shape', t.shape,
            'reservations', coalesce((
              select jsonb_agg(jsonb_build_object(
                'id', r.id, 'time', to_char(r.reserved_time,'HH24:MI'), 'party', r.party_size,
                'name', r.customer_name, 'status', r.status, 'isWalkIn', r.is_walk_in
              ) order by r.reserved_time)
              from reservations r
              where r.reserved_date = v_day
                and r.status not in ('cancelada','no_show')
                and (
                  r.table_id = t.id
                  or exists (select 1 from reservation_tables rt
                             where rt.reservation_id = r.id and rt.table_id = t.id)
                )
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

-- ══════════════════════════════════════════════════════════════════
-- Reservas del día: ahora traen el arreglo de mesas (además de la primera)
-- ══════════════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════════════
-- Crear reserva a mano: acepta 'tables' (arreglo) o 'table' (una sola)
-- ══════════════════════════════════════════════════════════════════
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
  v_tables uuid[];
  v_table uuid;
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

  v_tables := reservation_tables_from_payload(p);
  if array_length(v_tables, 1) is not null then
    if exists (select 1 from unnest(v_tables) tid
               left join restaurant_tables t on t.id = tid
               where t.id is null or t.location_id <> v_target_loc) then
      raise exception 'Alguna mesa no es de esta sede';
    end if;
    v_table := v_tables[1];
  end if;

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

  if array_length(v_tables, 1) is not null then
    insert into reservation_tables (reservation_id, table_id)
    select v_id, tid from unnest(v_tables) tid on conflict do nothing;
  end if;

  return jsonb_build_object('id', v_id, 'code', v_code, 'status', 'confirmada');
end
$$;

-- ══════════════════════════════════════════════════════════════════
-- Walk-In: también acepta 'tables' (arreglo) o 'table' (una sola)
-- ══════════════════════════════════════════════════════════════════
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
  v_tables uuid[];
  v_table uuid;
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

  v_tables := reservation_tables_from_payload(p);
  if array_length(v_tables, 1) is not null then
    if exists (select 1 from unnest(v_tables) tid
               left join restaurant_tables t on t.id = tid
               where t.id is null or t.location_id <> v_target_loc) then
      raise exception 'Alguna mesa no es de esta sede';
    end if;
    v_table := v_tables[1];
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

  if array_length(v_tables, 1) is not null then
    insert into reservation_tables (reservation_id, table_id)
    select v_id, tid from unnest(v_tables) tid on conflict do nothing;
  end if;

  return jsonb_build_object('id', v_id, 'code', v_code, 'status', 'confirmada');
end
$$;

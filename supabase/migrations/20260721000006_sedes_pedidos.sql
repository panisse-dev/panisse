-- create_order y create_reservation ahora guardan la SEDE que elige el cliente.
-- Si no viniera (cliente con versión vieja en caché), cae a 'pilares' por
-- defecto, así nunca se rompe.

create or replace function public.create_order(p jsonb)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_name text := left(btrim(coalesce(p->'customer'->>'name','')), 80);
  v_phone text := left(btrim(coalesce(p->'customer'->>'phone','')), 40);
  v_note text := left(btrim(coalesce(p->'customer'->>'note','')), 300);
  v_email text := lower(left(btrim(coalesce(p->'customer'->>'email','')), 120));
  v_session text := left(btrim(coalesce(p->>'session_id','')), 64);
  v_location text := coalesce(nullif(p->'customer'->>'location',''), 'pilares');
  v_wants_billing boolean := coalesce((p->'customer'->>'wantsBilling')::boolean, false);
  v_billing jsonb := norm_billing(p->'customer'->'billing');
  v_saved_billing jsonb;
  v_birthday date;
  v_phone_digits text;
  v_client clients%rowtype;
  v_client_id uuid;
  v_order_id uuid;
  v_code_n int;
  v_total int := 0;
  v_count int := 0;
  v_day date := (now() at time zone 'America/Bogota')::date;
  it jsonb;
  v_prod products%rowtype;
  v_variant text;
  v_qty int;
  v_entry jsonb;
  v_unit int;
begin
  if v_email = '' then
    raise exception 'Falta el correo';
  end if;
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'El correo no parece válido';
  end if;

  -- Sede válida (si no, a la de siempre)
  if not exists (select 1 from locations where id = v_location and active) then
    v_location := 'pilares';
  end if;

  begin
    v_birthday := nullif(p->'customer'->>'birthday','')::date;
  exception when others then
    v_birthday := null;
  end;
  if v_birthday is not null and v_birthday > current_date then
    v_birthday := null;
  end if;

  v_phone_digits := nullif(regexp_replace(v_phone, '\D', '', 'g'), '');

  select * into v_client from clients where lower(email) = v_email limit 1;
  if v_client.id is not null then
    v_client_id := v_client.id;
    v_saved_billing := v_client.billing;
    if v_name = '' then v_name := v_client.name; end if;
    if v_phone = '' then
      v_phone := v_client.phone;
      v_phone_digits := v_client.phone_digits;
    end if;
    begin
      update clients set
        name = case when v_name <> '' then v_name else name end,
        phone = case when v_phone <> '' then v_phone else phone end,
        phone_digits = coalesce(phone_digits, v_phone_digits),
        birthday = coalesce(birthday, v_birthday),
        last_activity_at = now()
      where id = v_client_id;
    exception when unique_violation then
      update clients set last_activity_at = now() where id = v_client_id;
    end;
  else
    if v_phone_digits is not null then
      select * into v_client from clients where phone_digits = v_phone_digits limit 1;
    end if;
    if v_client.id is not null then
      v_client_id := v_client.id;
      v_saved_billing := v_client.billing;
      if v_name = '' then v_name := v_client.name; end if;
      begin
        update clients set
          name = case when v_name <> '' then v_name else name end,
          email = v_email,
          birthday = coalesce(v_birthday, birthday),
          last_activity_at = now()
        where id = v_client_id;
      exception when unique_violation then
        update clients set last_activity_at = now() where id = v_client_id;
      end;
    else
      if v_name = '' then raise exception 'Falta el nombre'; end if;
      if v_birthday is null then raise exception 'Falta el cumpleaños'; end if;
      insert into clients (name, phone, phone_digits, email, birthday)
      values (v_name, v_phone, v_phone_digits, v_email, v_birthday)
      returning id into v_client_id;
    end if;
  end if;

  if v_name = '' then
    raise exception 'Falta el nombre';
  end if;

  if not v_wants_billing then
    v_billing := null;
  else
    if v_billing is null then
      v_billing := v_saved_billing;
      if v_billing is null then
        raise exception 'Faltan los datos de la factura';
      end if;
    else
      update clients set billing = v_billing where id = v_client_id;
    end if;
    if coalesce(v_billing->>'email','') = '' then
      v_billing := jsonb_set(v_billing, '{email}', to_jsonb(v_email));
    end if;
  end if;

  insert into daily_counters as dc (day, n) values (v_day, 1)
  on conflict (day) do update set n = dc.n + 1
  returning dc.n into v_code_n;

  insert into orders (code, customer_name, customer_phone, customer_note, client_id, billing, location_id)
  values (v_code_n::text, v_name, v_phone, v_note, v_client_id, v_billing, v_location)
  returning id into v_order_id;

  for it in select * from jsonb_array_elements(coalesce(p->'items','[]'::jsonb)) loop
    select * into v_prod from products where id = it->>'productId' and visible;
    if not found or v_prod.hide_price then continue; end if;

    v_qty := least(50, greatest(1, coalesce(nullif(it->>'qty','')::int, 1)));
    v_variant := left(btrim(coalesce(it->>'variant','')), 80);

    select pe into v_entry
    from jsonb_array_elements(v_prod.prices) with ordinality as t(pe, ord)
    where coalesce(pe->>'label','') = v_variant
       or ('Opción ' || ord) = v_variant
    limit 1;
    if v_entry is null then
      select pe into v_entry
      from jsonb_array_elements(v_prod.prices) as t(pe) limit 1;
    end if;
    if v_entry is null then continue; end if;

    v_unit := coalesce(
      nullif(v_entry->>'discounted','')::numeric::int,
      nullif(v_entry->>'price','')::numeric::int, 0);
    if v_unit <= 0 then continue; end if;

    insert into order_items (order_id, product_id, name, variant, note, unit_price, qty)
    values (v_order_id, v_prod.id, v_prod.name, v_variant,
            left(btrim(coalesce(it->>'note','')), 200), v_unit, v_qty);
    v_total := v_total + v_unit * v_qty;
    v_count := v_count + 1;
  end loop;

  if v_count = 0 then
    raise exception 'El pedido está vacío';
  end if;

  update orders set total = v_total where id = v_order_id;
  insert into events (type, session_id) values ('order_created', nullif(v_session,''));

  return jsonb_build_object('id', v_order_id, 'code', v_code_n::text, 'status', 'recibido');
end
$$;

-- create_reservation: agrega la sede elegida.
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

  v_slot := greatest(5, s.slot_minutes);
  v_turn := greatest(v_slot, s.turn_minutes);
  v_m := mins_of(v_time);
  if v_m < mins_of(s.start_time) or v_m > mins_of(s.end_time) then
    raise exception 'Esa hora no está disponible';
  end if;
  if v_date = v_today and v_m < v_now_min + s.min_hours * 60 then
    raise exception 'Esa hora ya es muy pronto, elige una más adelante';
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

-- La disponibilidad de reservas se calcula por sede.
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

-- Lista pública de sedes para que el cliente elija
create or replace function public.public_locations()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', l.id, 'name', l.name, 'address', l.address, 'whatsapp', l.whatsapp
  ) order by l.sort), '[]'::jsonb)
  from locations l where l.active;
$$;

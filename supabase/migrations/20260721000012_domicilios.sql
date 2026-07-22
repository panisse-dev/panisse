-- ══════════════════════════════════════════════════════════════════
-- Domicilios programados
--
-- El cliente puede pedir "para recoger" (como siempre) o "a domicilio",
-- y en domicilio puede pedir para YA o programar día y hora. Cada sede
-- decide si acepta domicilios, el costo, el pedido mínimo, el horario y
-- la anticipación. Viene APAGADO: mientras la sede no lo active, todo se
-- comporta igual que hoy (solo recoger). Aditivo y sin riesgo.
-- ══════════════════════════════════════════════════════════════════

-- ── Configuración de domicilios por sede ──
create table if not exists public.delivery_settings (
  location_id text primary key references public.locations(id) on delete cascade,
  enabled boolean not null default false,       -- la sede acepta domicilios
  fee int not null default 0,                    -- costo del domicilio (0 = gratis)
  min_order int not null default 0,              -- pedido mínimo para domicilio
  scheduling boolean not null default true,      -- permite programar día/hora
  lead_minutes int not null default 45,          -- anticipación mínima
  days_ahead int not null default 3,             -- hasta cuántos días adelante se programa
  start_time time not null default '11:00',      -- desde qué hora se entrega
  end_time time not null default '21:00',        -- hasta qué hora se entrega
  note text not null default '',                 -- aviso para el cliente (ej. cobertura)
  updated_at timestamptz not null default now()
);
insert into public.delivery_settings (location_id) values ('cerritos'), ('pilares')
  on conflict (location_id) do nothing;

alter table public.delivery_settings enable row level security; -- sólo por RPC

-- ── Marca de domicilio en los pedidos ──
alter table public.orders
  add column if not exists order_type text not null default 'pickup'
    check (order_type in ('pickup','delivery')),
  add column if not exists delivery_address text not null default '',
  add column if not exists delivery_fee int not null default 0,
  add column if not exists scheduled_at timestamptz;   -- null = para ya

-- ── Config pública de domicilios que ve el cliente (por sede) ──
create or replace function public.public_delivery_config(p_location text)
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'enabled', d.enabled,
    'fee', d.fee,
    'minOrder', d.min_order,
    'scheduling', d.scheduling,
    'leadMinutes', d.lead_minutes,
    'daysAhead', d.days_ahead,
    'startTime', to_char(d.start_time, 'HH24:MI'),
    'endTime', to_char(d.end_time, 'HH24:MI'),
    'note', d.note
  )
  from delivery_settings d
  where d.location_id = coalesce(nullif(p_location,''), 'pilares');
$$;

-- ══════════════════════════════════════════════════════════════════
-- create_order: ahora acepta domicilio (recoger sigue igual)
-- ══════════════════════════════════════════════════════════════════
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
  -- Domicilio
  v_order_type text := lower(coalesce(nullif(p->'customer'->>'orderType',''), 'pickup'));
  v_addr text := left(btrim(coalesce(p->'customer'->>'deliveryAddress','')), 300);
  v_sched timestamptz;
  v_dset delivery_settings%rowtype;
  v_fee int := 0;
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

  -- ── Tipo de pedido: recoger (por defecto) o domicilio ──
  if v_order_type not in ('pickup','delivery') then
    v_order_type := 'pickup';
  end if;
  if v_order_type = 'delivery' then
    select * into v_dset from delivery_settings where location_id = v_location;
    if v_dset.location_id is null or not v_dset.enabled then
      raise exception 'Esta sede no está recibiendo domicilios por ahora';
    end if;
    if v_addr = '' then
      raise exception 'Escribe la dirección de entrega';
    end if;
    -- Hora programada (opcional). Si no viene, es "para ya".
    begin
      v_sched := nullif(p->'customer'->>'scheduledAt','')::timestamptz;
    exception when others then
      v_sched := null;
    end;
    v_fee := v_dset.fee;
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

  insert into orders (
    code, customer_name, customer_phone, customer_note, client_id, billing, location_id,
    order_type, delivery_address, delivery_fee, scheduled_at
  )
  values (
    v_code_n::text, v_name, v_phone, v_note, v_client_id, v_billing, v_location,
    v_order_type, case when v_order_type = 'delivery' then v_addr else '' end,
    v_fee, case when v_order_type = 'delivery' then v_sched else null end
  )
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

  -- Pedido mínimo para domicilio (sobre el valor de los platos)
  if v_order_type = 'delivery' and v_dset.min_order > 0 and v_total < v_dset.min_order then
    raise exception 'El pedido mínimo para domicilio es %', v_dset.min_order;
  end if;

  -- El total incluye el costo del domicilio
  update orders set total = v_total + v_fee where id = v_order_id;
  insert into events (type, session_id) values ('order_created', nullif(v_session,''));

  return jsonb_build_object('id', v_order_id, 'code', v_code_n::text, 'status', 'recibido');
end
$$;

-- ══════════════════════════════════════════════════════════════════
-- Cocina: los pedidos ahora traen tipo, dirección, costo y hora programada
-- ══════════════════════════════════════════════════════════════════
create or replace function public.staff_orders(p_code text, p_day date default null)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', o.id, 'code', o.code, 'createdAt', o.created_at, 'status', o.status,
      'statusAt', o.status_at, 'paid', o.paid, 'locationId', o.location_id,
      'orderType', o.order_type, 'deliveryAddress', o.delivery_address,
      'deliveryFee', o.delivery_fee, 'scheduledAt', o.scheduled_at,
      'customer', jsonb_build_object('name', o.customer_name, 'phone', o.customer_phone, 'note', o.customer_note),
      'billing', o.billing, 'staffNote', o.staff_note, 'total', o.total,
      'items', coalesce((
        select jsonb_agg(jsonb_build_object(
          'productId', i.product_id, 'name', i.name, 'variant', i.variant,
          'note', i.note, 'unitPrice', i.unit_price, 'qty', i.qty))
        from order_items i where i.order_id = o.id), '[]'::jsonb)
    ) order by o.created_at)
    from orders o
    where o.paid
      and (v_loc is null or o.location_id = v_loc)
      and case when p_day is null then
        o.status <> 'recogido' or o.status_at > now() - interval '6 hours'
      else (o.created_at at time zone 'America/Bogota')::date = p_day end
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_pending_orders(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', o.id, 'code', o.code, 'createdAt', o.created_at, 'status', o.status,
      'statusAt', o.status_at, 'paid', o.paid, 'locationId', o.location_id,
      'orderType', o.order_type, 'deliveryAddress', o.delivery_address,
      'deliveryFee', o.delivery_fee, 'scheduledAt', o.scheduled_at,
      'customer', jsonb_build_object('name', o.customer_name, 'phone', o.customer_phone, 'note', o.customer_note),
      'billing', o.billing, 'staffNote', o.staff_note, 'total', o.total,
      'items', coalesce((
        select jsonb_agg(jsonb_build_object(
          'productId', i.product_id, 'name', i.name, 'variant', i.variant,
          'note', i.note, 'unitPrice', i.unit_price, 'qty', i.qty))
        from order_items i where i.order_id = o.id), '[]'::jsonb)
    ) order by o.created_at desc)
    from orders o
    where not o.paid and o.status <> 'recogido'
      and o.created_at > now() - interval '24 hours'
      and (v_loc is null or o.location_id = v_loc)
  ), '[]'::jsonb);
end
$$;

-- ══════════════════════════════════════════════════════════════════
-- Panel: leer y editar la configuración de domicilios por sede
-- ══════════════════════════════════════════════════════════════════
create or replace function public.staff_delivery_settings(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'locationId', d.location_id,
      'locationName', l.name,
      'enabled', d.enabled,
      'fee', d.fee,
      'minOrder', d.min_order,
      'scheduling', d.scheduling,
      'leadMinutes', d.lead_minutes,
      'daysAhead', d.days_ahead,
      'startTime', to_char(d.start_time, 'HH24:MI'),
      'endTime', to_char(d.end_time, 'HH24:MI'),
      'note', d.note
    ) order by l.sort)
    from delivery_settings d join locations l on l.id = d.location_id
    where (v_loc is null or d.location_id = v_loc)
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_update_delivery_settings(p_code text, p_location text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  if v_loc is not null and v_loc <> p_location then
    raise exception 'No autorizado' using errcode = '42501';
  end if;
  update delivery_settings set
    enabled = coalesce((p->>'enabled')::boolean, enabled),
    fee = greatest(0, coalesce((p->>'fee')::int, fee)),
    min_order = greatest(0, coalesce((p->>'minOrder')::int, min_order)),
    scheduling = coalesce((p->>'scheduling')::boolean, scheduling),
    lead_minutes = greatest(0, coalesce((p->>'leadMinutes')::int, lead_minutes)),
    days_ahead = greatest(0, coalesce((p->>'daysAhead')::int, days_ahead)),
    start_time = coalesce((p->>'startTime')::time, start_time),
    end_time = coalesce((p->>'endTime')::time, end_time),
    note = left(btrim(coalesce(p->>'note', note)), 200),
    updated_at = now()
  where location_id = p_location;
end
$$;

-- Facturación electrónica opcional: al enviar el pedido el cliente puede
-- pedir factura y dejar sus datos fiscales. Se guardan en el pedido (para
-- emitirla) y en el cliente (para no volver a pedírselos la próxima vez).

alter table public.clients add column if not exists billing jsonb;
alter table public.orders  add column if not exists billing jsonb;

-- Normaliza y valida los datos de facturación. Devuelve null si no vienen.
create or replace function public.norm_billing(p jsonb)
returns jsonb
language plpgsql immutable
set search_path = public
as $$
declare
  v_type text;
  v_num text;
  v_name text;
  v_email text;
  v_addr text;
  v_phone text;
begin
  if p is null or jsonb_typeof(p) <> 'object' then
    return null;
  end if;

  v_type := upper(btrim(coalesce(p->>'docType', '')));
  if v_type not in ('NIT', 'CC', 'CE', 'PP') then
    v_type := 'CC';
  end if;

  v_num := left(regexp_replace(coalesce(p->>'docNumber', ''), '[^0-9A-Za-z-]', '', 'g'), 20);
  v_name := left(btrim(coalesce(p->>'name', '')), 120);
  v_email := lower(left(btrim(coalesce(p->>'email', '')), 120));
  v_addr := left(btrim(coalesce(p->>'address', '')), 160);
  v_phone := left(btrim(coalesce(p->>'phone', '')), 40);

  if v_num = '' then
    raise exception 'Falta el número de documento para la factura';
  end if;
  if v_name = '' then
    raise exception 'Falta el nombre o razón social para la factura';
  end if;
  if v_email <> '' and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'El correo de la factura no parece válido';
  end if;

  return jsonb_build_object(
    'docType', v_type, 'docNumber', v_num, 'name', v_name,
    'email', v_email, 'address', v_addr, 'phone', v_phone);
end
$$;

-- ¿Conocemos este correo? Sólo revela si existe, el nombre (para saludar) y
-- si ya tenemos sus datos de facturación (para no volver a pedírselos).
create or replace function public.check_client(p_email text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_name text;
  v_has_billing boolean;
begin
  select name, billing is not null into v_name, v_has_billing
  from clients
  where lower(email) = lower(btrim(coalesce(p_email, ''))) limit 1;
  if v_name is null then
    return jsonb_build_object('known', false);
  end if;
  return jsonb_build_object('known', true, 'name', v_name, 'hasBilling', v_has_billing);
end
$$;

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
  -- ── Correo: obligatorio, identifica al cliente ──
  if v_email = '' then
    raise exception 'Falta el correo';
  end if;
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'El correo no parece válido';
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

  -- ── Cliente: por correo → por teléfono → nuevo ──
  select * into v_client from clients where lower(email) = v_email limit 1;
  if v_client.id is not null then
    -- Cliente que regresa: completamos con sus datos guardados
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
      -- el teléfono nuevo choca con otro cliente: no lo tocamos
      update clients set last_activity_at = now() where id = v_client_id;
    end;
  else
    if v_phone_digits is not null then
      select * into v_client from clients where phone_digits = v_phone_digits limit 1;
    end if;
    if v_client.id is not null then
      -- Cliente creado antes (p. ej. por el personal) sin correo:
      -- le anexamos el correo y seguimos siendo el mismo cliente.
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
      -- Cliente nuevo: nombre y cumpleaños obligatorios
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

  -- ── Factura electrónica (opcional) ──
  if not v_wants_billing then
    v_billing := null;
  else
    if v_billing is null then
      -- El cliente pidió factura sin escribir datos: usamos los guardados
      v_billing := v_saved_billing;
      if v_billing is null then
        raise exception 'Faltan los datos de la factura';
      end if;
    else
      -- Datos nuevos o corregidos: quedan guardados para la próxima vez
      update clients set billing = v_billing where id = v_client_id;
    end if;
    if coalesce(v_billing->>'email','') = '' then
      v_billing := jsonb_set(v_billing, '{email}', to_jsonb(v_email));
    end if;
  end if;

  -- ── Número corto del día ──
  insert into daily_counters as dc (day, n) values (v_day, 1)
  on conflict (day) do update set n = dc.n + 1
  returning dc.n into v_code_n;

  insert into orders (code, customer_name, customer_phone, customer_note, client_id, billing)
  values (v_code_n::text, v_name, v_phone, v_note, v_client_id, v_billing)
  returning id into v_order_id;

  -- ── Líneas: el precio sale de la base, no del cliente ──
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

-- El panel ve los datos de facturación junto al pedido
create or replace function public.staff_orders(p_code text, p_day date default null)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', o.id,
      'code', o.code,
      'createdAt', o.created_at,
      'status', o.status,
      'statusAt', o.status_at,
      'customer', jsonb_build_object(
        'name', o.customer_name, 'phone', o.customer_phone, 'note', o.customer_note
      ),
      'billing', o.billing,
      'staffNote', o.staff_note,
      'total', o.total,
      'items', coalesce((
        select jsonb_agg(jsonb_build_object(
          'productId', i.product_id, 'name', i.name, 'variant', i.variant,
          'note', i.note, 'unitPrice', i.unit_price, 'qty', i.qty
        ))
        from order_items i where i.order_id = o.id
      ), '[]'::jsonb)
    ) order by o.created_at)
    from orders o
    where case
      when p_day is null then
        o.status <> 'recogido' or o.status_at > now() - interval '6 hours'
      else
        (o.created_at at time zone 'America/Bogota')::date = p_day
    end
  ), '[]'::jsonb);
end
$$;

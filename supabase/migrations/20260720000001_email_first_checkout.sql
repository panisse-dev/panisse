-- Checkout con correo primero: el correo identifica al cliente que
-- regresa (no se le vuelven a pedir sus datos) y es obligatorio junto
-- con el cumpleaños para clientes nuevos. Los datos guardados nunca se
-- devuelven al navegador: create_order los completa del lado del servidor.

-- Un correo = un cliente (insensible a mayúsculas)
create unique index if not exists clients_email_unique_idx
  on public.clients (lower(email)) where email is not null;

-- ¿Conocemos este correo? Sólo revela si existe y el nombre (para saludar).
create or replace function public.check_client(p_email text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_name text;
begin
  select name into v_name from clients
  where lower(email) = lower(btrim(coalesce(p_email, ''))) limit 1;
  if v_name is null then
    return jsonb_build_object('known', false);
  end if;
  return jsonb_build_object('known', true, 'name', v_name);
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

  -- ── Número corto del día ──
  insert into daily_counters as dc (day, n) values (v_day, 1)
  on conflict (day) do update set n = dc.n + 1
  returning dc.n into v_code_n;

  insert into orders (code, customer_name, customer_phone, customer_note, client_id)
  values (v_code_n::text, v_name, v_phone, v_note, v_client_id)
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

-- El personal también guarda correos normalizados y recibe un error claro
create or replace function public.staff_upsert_client(p_code text, p jsonb)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_id uuid;
  v_name text := left(btrim(coalesce(p->>'name','')), 80);
  v_phone text := left(btrim(coalesce(p->>'phone','')), 40);
  v_digits text := nullif(regexp_replace(coalesce(p->>'phone',''), '\D', '', 'g'), '');
  v_email text := nullif(lower(left(btrim(coalesce(p->>'email','')), 120)), '');
  v_notes text := left(btrim(coalesce(p->>'notes','')), 500);
  v_birthday date;
begin
  perform assert_staff(p_code);
  if v_name = '' then
    raise exception 'Falta el nombre';
  end if;
  begin
    v_birthday := nullif(p->>'birthday','')::date;
  exception when others then
    v_birthday := null;
  end;

  if coalesce(p->>'id','') <> '' then
    v_id := (p->>'id')::uuid;
    update clients set
      name = v_name, phone = v_phone, phone_digits = v_digits,
      email = v_email, birthday = v_birthday, notes = v_notes,
      last_activity_at = now()
    where id = v_id;
    if not found then raise exception 'Cliente no encontrado'; end if;
  else
    insert into clients (name, phone, phone_digits, email, birthday, notes)
    values (v_name, v_phone, v_digits, v_email, v_birthday, v_notes)
    returning id into v_id;
  end if;
  return v_id;
exception
  when unique_violation then
    raise exception 'Ya existe un cliente con ese teléfono o correo';
end
$$;

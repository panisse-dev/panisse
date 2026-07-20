-- ══════════════════════════════════════════════════════════════════
-- PANISSE · Esquema inicial
-- Backend en Supabase: menú (productos), clientes, pedidos y analítica.
-- El panel /admin se autentica con una clave de personal (staff code)
-- guardada en app_config; todas las operaciones privilegiadas pasan por
-- funciones SECURITY DEFINER que la verifican. Las tablas sensibles no
-- tienen políticas para anon: sólo se leen a través de esas funciones.
-- ══════════════════════════════════════════════════════════════════

-- ── Restaurante (una sola fila) ──
create table public.restaurant_info (
  id boolean primary key default true check (id),
  name text not null,
  logo text not null default '',
  instagram text not null default '',
  whatsapp text not null default '',
  address text not null default '',
  city text not null default '',
  currency text not null default 'COP'
);

-- ── Estructura del menú ──
create table public.menus (
  slug text primary key,
  label text not null,
  tagline text not null default '',
  name text not null,
  sort int not null default 0
);

create table public.sections (
  id text primary key,
  menu_slug text not null references public.menus(slug) on delete cascade,
  parent_id text references public.sections(id) on delete cascade,
  slug text not null,
  name text not null,
  description text not null default '',
  image text,
  layout text not null default 'cards' check (layout in ('cards','list')),
  sort int not null default 0
);
create index sections_menu_idx on public.sections(menu_slug);
create index sections_parent_idx on public.sections(parent_id);

create table public.products (
  id text primary key,
  section_id text not null references public.sections(id) on delete cascade,
  name text not null,
  description text not null default '',
  -- [{"label": "", "price": 29900, "discounted": null}, ...]
  prices jsonb not null default '[]'::jsonb,
  hide_price boolean not null default false,
  image text,
  is_new boolean not null default false,
  veg boolean not null default false,
  visible boolean not null default true,
  sort int not null default 0,
  updated_at timestamptz not null default now()
);
create index products_section_idx on public.products(section_id);

-- ── Clientes ──
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null default '',
  phone text not null default '',
  -- sólo dígitos, para deduplicar (+57 312... == 312...)
  phone_digits text unique,
  email text,
  birthday date,
  notes text not null default '',
  created_at timestamptz not null default now(),
  last_activity_at timestamptz not null default now()
);

-- ── Pedidos ──
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  created_at timestamptz not null default now(),
  status text not null default 'recibido'
    check (status in ('recibido','preparacion','listo','recogido')),
  status_at timestamptz not null default now(),
  client_id uuid references public.clients(id) on delete set null,
  customer_name text not null,
  customer_phone text not null default '',
  customer_note text not null default '',
  staff_note text not null default '',
  total int not null default 0
);
create index orders_created_idx on public.orders(created_at);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id text,
  name text not null,
  variant text not null default '',
  note text not null default '',
  unit_price int not null,
  qty int not null
);
create index order_items_order_idx on public.order_items(order_id);
create index order_items_product_idx on public.order_items(product_id);

-- Número de pedido corto que se reinicia cada día (America/Bogota)
create table public.daily_counters (
  day date primary key,
  n int not null default 0
);

-- ── Eventos de analítica ──
create table public.events (
  id bigint generated always as identity primary key,
  ts timestamptz not null default now(),
  type text not null check (type in ('menu_view','product_view','order_created')),
  menu_slug text,
  product_id text,
  session_id text,
  device text check (device is null or device in ('movil','escritorio'))
);
create index events_ts_idx on public.events(ts);

-- ── Configuración privada ──
create table public.app_config (
  key text primary key,
  value text not null
);
insert into public.app_config (key, value) values ('staff_code', 'panisse2026');

-- ── Bucket para fotos de productos (lectura pública, subida sólo vía
--    Edge Function con service role) ──
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- ══════════════════════════════════════════════════════════════════
-- RLS
-- ══════════════════════════════════════════════════════════════════
alter table public.restaurant_info enable row level security;
alter table public.menus enable row level security;
alter table public.sections enable row level security;
alter table public.products enable row level security;
alter table public.clients enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.daily_counters enable row level security;
alter table public.events enable row level security;
alter table public.app_config enable row level security;

-- El menú es público
create policy restaurant_public_read on public.restaurant_info
  for select to anon, authenticated using (true);
create policy menus_public_read on public.menus
  for select to anon, authenticated using (true);
create policy sections_public_read on public.sections
  for select to anon, authenticated using (true);
create policy products_public_read on public.products
  for select to anon, authenticated using (visible);

-- Cualquiera puede registrar eventos de analítica (sólo insertar)
create policy events_public_insert on public.events
  for insert to anon, authenticated
  with check (
    type in ('menu_view','product_view')
    and (menu_slug is null or char_length(menu_slug) <= 60)
    and (product_id is null or char_length(product_id) <= 64)
    and (session_id is null or char_length(session_id) <= 64)
  );
-- clients / orders / order_items / daily_counters / app_config:
-- sin políticas → inaccesibles con la clave anon; sólo vía RPCs.

-- ══════════════════════════════════════════════════════════════════
-- RPCs públicas
-- ══════════════════════════════════════════════════════════════════

-- Productos visibles de una sección, con la misma forma que usa la web
create or replace function public.menu_products_json(p_section_id text)
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', p.id,
    'name', p.name,
    'description', p.description,
    'prices', p.prices,
    'hidePrice', p.hide_price,
    'image', p.image,
    'isNew', p.is_new,
    'veg', p.veg,
    'order', p.sort
  ) order by p.sort), '[]'::jsonb)
  from products p
  where p.section_id = p_section_id and p.visible
$$;

-- Todo el menú en un solo viaje, con la misma forma que menu.json
create or replace function public.get_menu_data()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'restaurant', (
      select jsonb_build_object(
        'name', r.name, 'logo', r.logo, 'instagram', r.instagram,
        'whatsapp', r.whatsapp, 'address', r.address, 'city', r.city,
        'currency', r.currency
      ) from restaurant_info r limit 1
    ),
    'menus', coalesce((
      select jsonb_agg(jsonb_build_object(
        'slug', m.slug,
        'label', m.label,
        'tagline', m.tagline,
        'name', m.name,
        'totalProducts', (
          select count(*) from products p
          join sections s on s.id = p.section_id
          where s.menu_slug = m.slug and p.visible
        ),
        'sections', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', s.id,
            'slug', s.slug,
            'name', s.name,
            'description', s.description,
            'image', s.image,
            'layout', s.layout,
            'products', menu_products_json(s.id),
            'subsections', coalesce((
              select jsonb_agg(jsonb_build_object(
                'id', ss.id,
                'slug', ss.slug,
                'name', ss.name,
                'description', ss.description,
                'layout', ss.layout,
                'products', menu_products_json(ss.id)
              ) order by ss.sort)
              from sections ss where ss.parent_id = s.id
            ), '[]'::jsonb)
          ) order by s.sort)
          from sections s where s.menu_slug = m.slug and s.parent_id is null
        ), '[]'::jsonb)
      ) order by m.sort)
      from menus m
    ), '[]'::jsonb)
  )
$$;

-- Crear pedido: valida contra la base (precios del servidor), enlaza o
-- crea el cliente por teléfono y asigna número corto del día.
create or replace function public.create_order(p jsonb)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_name text := left(btrim(coalesce(p->'customer'->>'name','')), 80);
  v_phone text := left(btrim(coalesce(p->'customer'->>'phone','')), 40);
  v_note text := left(btrim(coalesce(p->'customer'->>'note','')), 300);
  v_email text := left(btrim(coalesce(p->'customer'->>'email','')), 120);
  v_session text := left(btrim(coalesce(p->>'session_id','')), 64);
  v_birthday date;
  v_phone_digits text;
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
  if v_name = '' then
    raise exception 'Falta el nombre';
  end if;

  begin
    v_birthday := nullif(p->'customer'->>'birthday','')::date;
  exception when others then
    v_birthday := null;
  end;

  -- ── Cliente (sólo si dejó teléfono) ──
  v_phone_digits := nullif(regexp_replace(v_phone, '\D', '', 'g'), '');
  if length(coalesce(v_phone_digits,'')) >= 7 then
    select id into v_client_id from clients where phone_digits = v_phone_digits;
    if v_client_id is null then
      insert into clients (name, phone, phone_digits, email, birthday)
      values (v_name, v_phone, v_phone_digits, nullif(v_email,''), v_birthday)
      returning id into v_client_id;
    else
      update clients set
        name = case when v_name <> '' then v_name else name end,
        email = coalesce(nullif(v_email,''), email),
        birthday = coalesce(v_birthday, birthday),
        last_activity_at = now()
      where id = v_client_id;
    end if;
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

    -- entrada de precio: por etiqueta, por "Opción N", o la primera
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

-- Estado público de un pedido (sólo con el id, que es un uuid secreto)
create or replace function public.get_order_public(p_id uuid)
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'code', o.code, 'status', o.status, 'createdAt', o.created_at
  )
  from orders o where o.id = p_id
$$;

-- ══════════════════════════════════════════════════════════════════
-- RPCs del personal (verifican la clave contra app_config)
-- ══════════════════════════════════════════════════════════════════

create or replace function public.assert_staff(p_code text)
returns void
language plpgsql stable
security definer set search_path = public
as $$
begin
  if coalesce(p_code,'') = '' or not exists (
    select 1 from app_config where key = 'staff_code' and value = p_code
  ) then
    raise exception 'No autorizado' using errcode = '42501';
  end if;
end
$$;

create or replace function public.staff_verify(p_code text)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from app_config
    where key = 'staff_code' and value = coalesce(p_code,'')
  )
$$;

-- Pedidos del panel. p_day null → vista en vivo (activos + recogidos
-- de las últimas 6 h); con fecha → historial completo de ese día.
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

create or replace function public.staff_set_status(p_code text, p_id uuid, p_status text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  if p_status not in ('recibido','preparacion','listo','recogido') then
    raise exception 'Estado inválido';
  end if;
  update orders set status = p_status, status_at = now() where id = p_id;
end
$$;

create or replace function public.staff_set_note(p_code text, p_id uuid, p_note text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update orders set staff_note = left(btrim(coalesce(p_note,'')), 300) where id = p_id;
end
$$;

-- Clientes con sus estadísticas de pedidos
create or replace function public.staff_clients(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'phone', c.phone,
      'email', c.email,
      'birthday', c.birthday,
      'notes', c.notes,
      'createdAt', c.created_at,
      'lastActivityAt', c.last_activity_at,
      'ordersCount', (select count(*) from orders o where o.client_id = c.id),
      'totalSpent', (select coalesce(sum(o.total),0) from orders o where o.client_id = c.id),
      'lastOrderAt', (select max(o.created_at) from orders o where o.client_id = c.id)
    ) order by c.last_activity_at desc)
    from clients c
  ), '[]'::jsonb);
end
$$;

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
  v_email text := nullif(left(btrim(coalesce(p->>'email','')), 120), '');
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
    raise exception 'Ya existe un cliente con ese teléfono';
end
$$;

create or replace function public.staff_delete_client(p_code text, p_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  delete from clients where id = p_id;
end
$$;

-- Edición de productos desde el panel (sólo llaves presentes)
create or replace function public.staff_update_product(p_code text, p_id text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update products set
    name = case when p ? 'name' then left(btrim(p->>'name'), 80) else name end,
    description = case when p ? 'description' then left(p->>'description', 2000) else description end,
    image = case when p ? 'image' then nullif(p->>'image','') else image end,
    prices = case when p ? 'prices' then p->'prices' else prices end,
    hide_price = case when p ? 'hidePrice' then (p->>'hidePrice')::boolean else hide_price end,
    is_new = case when p ? 'isNew' then (p->>'isNew')::boolean else is_new end,
    veg = case when p ? 'veg' then (p->>'veg')::boolean else veg end,
    visible = case when p ? 'visible' then (p->>'visible')::boolean else visible end,
    updated_at = now()
  where id = p_id;
  if not found then raise exception 'Producto no encontrado'; end if;
end
$$;

create or replace function public.staff_update_section(p_code text, p_id text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update sections set
    name = case when p ? 'name' then left(btrim(p->>'name'), 80) else name end,
    description = case when p ? 'description' then left(p->>'description', 500) else description end
  where id = p_id;
  if not found then raise exception 'Categoría no encontrada'; end if;
end
$$;

-- Analítica agregada del rango [p_from, p_to] en hora de Bogotá
create or replace function public.staff_analytics(p_code text, p_from date, p_to date)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  result jsonb;
begin
  perform assert_staff(p_code);

  with ev as (
    select e.*, (e.ts at time zone 'America/Bogota') as lts
    from events e
    where (e.ts at time zone 'America/Bogota')::date between p_from and p_to
  ), ord as (
    select o.*, (o.created_at at time zone 'America/Bogota') as lts
    from orders o
    where (o.created_at at time zone 'America/Bogota')::date between p_from and p_to
  )
  select jsonb_build_object(
    'kpis', jsonb_build_object(
      'menuVisits', (select count(*) from ev where type = 'menu_view'),
      'sessions', (select count(distinct session_id) from ev where session_id is not null),
      'productViews', (select count(*) from ev where type = 'product_view'),
      'orders', (select count(*) from ord),
      'revenue', (select coalesce(sum(total),0) from ord)
    ),
    'visitsByDay', coalesce((
      select jsonb_agg(jsonb_build_object(
        'day', to_char(d, 'YYYY-MM-DD'),
        'visits', (select count(*) from ev where type = 'menu_view' and lts::date = d),
        'orders', (select count(*) from ord where lts::date = d),
        'revenue', (select coalesce(sum(total),0) from ord where lts::date = d)
      ) order by d)
      from generate_series(p_from::timestamp, p_to::timestamp, interval '1 day') g(d)
    ), '[]'::jsonb),
    'visitsByDow', coalesce((
      select jsonb_agg(jsonb_build_object('dow', dw, 'visits', v) order by dw)
      from (
        select extract(isodow from lts)::int dw, count(*) v
        from ev where type = 'menu_view' group by 1
      ) t
    ), '[]'::jsonb),
    'visitsByHour', coalesce((
      select jsonb_agg(jsonb_build_object('hour', h, 'visits', v) order by h)
      from (
        select extract(hour from lts)::int h, count(*) v
        from ev where type = 'menu_view' group by 1
      ) t
    ), '[]'::jsonb),
    'menuVisits', coalesce((
      select jsonb_agg(jsonb_build_object('menu', coalesce(m.label, t.menu_slug), 'visits', t.v) order by t.v desc)
      from (
        select menu_slug, count(*) v from ev
        where type = 'menu_view' and menu_slug is not null group by 1
      ) t left join menus m on m.slug = t.menu_slug
    ), '[]'::jsonb),
    'topProductsViews', coalesce((
      select jsonb_agg(jsonb_build_object('id', t.product_id, 'name', t.name, 'views', t.v) order by t.v desc)
      from (
        select e.product_id, coalesce(min(p.name), '(eliminado)') as name, count(*) v
        from ev e left join products p on p.id = e.product_id
        where e.type = 'product_view' and e.product_id is not null
        group by e.product_id
        order by v desc limit 10
      ) t
    ), '[]'::jsonb),
    'topProductsOrders', coalesce((
      select jsonb_agg(jsonb_build_object('id', t.product_id, 'name', t.name, 'qty', t.q, 'revenue', t.r) order by t.q desc)
      from (
        select i.product_id, min(i.name) as name, sum(i.qty) q, sum(i.qty * i.unit_price) r
        from order_items i join ord on ord.id = i.order_id
        group by i.product_id
        order by q desc limit 10
      ) t
    ), '[]'::jsonb),
    'topCategories', coalesce((
      select jsonb_agg(jsonb_build_object('name', t.name, 'views', t.v) order by t.v desc)
      from (
        select s.name, count(*) v
        from ev e
        join products p on p.id = e.product_id
        join sections s on s.id = p.section_id
        where e.type = 'product_view'
        group by s.name
        order by v desc limit 10
      ) t
    ), '[]'::jsonb),
    'devices', coalesce((
      select jsonb_agg(jsonb_build_object('device', t.device, 'sessions', t.v))
      from (
        select coalesce(device, 'otro') device, count(distinct session_id) v
        from ev where session_id is not null group by 1
      ) t
    ), '[]'::jsonb)
  ) into result;

  return result;
end
$$;

-- Analítica dividida por sede. Pedidos y reservas guardan location_id, así que
-- se pueden separar por Cerritos / Pilares. Las visitas al menú NO guardan sede
-- (el menú digital es el mismo enlace para ambas; el cliente elige sede al pagar),
-- por eso esas métricas siguen siendo del total.
--
-- Reglas de acceso:
--  · Clave de una sede  → sólo ve su sede (se ignora el filtro que pida).
--  · Clave del dueño    → puede filtrar por p_location (null = todas las sedes).

create or replace function public.staff_analytics(
  p_code text, p_from date, p_to date, p_location text default null
)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  result jsonb;
  v_forced text;  -- sede de la clave (null = dueño)
  v_loc text;     -- sede efectiva para filtrar pedidos/reservas
begin
  perform assert_staff(p_code);
  v_forced := staff_location(p_code);
  -- El personal de sede sólo ve lo suyo; el dueño usa el filtro que elija.
  v_loc := coalesce(v_forced, p_location);

  with ev as (
    select e.*, (e.ts at time zone 'America/Bogota') as lts
    from events e
    where (e.ts at time zone 'America/Bogota')::date between p_from and p_to
  ), ord as (
    select o.*, (o.created_at at time zone 'America/Bogota') as lts
    from orders o
    where (o.created_at at time zone 'America/Bogota')::date between p_from and p_to
      and o.paid
      and (v_loc is null or o.location_id = v_loc)
  ), res as (
    select r.*
    from reservations r
    where r.reserved_date between p_from and p_to
      and (v_loc is null or r.location_id = v_loc)
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
    ), '[]'::jsonb),
    -- ── Reservas (por fecha reservada, ya filtradas por sede efectiva) ──
    'reservations', jsonb_build_object(
      'total', (select count(*) from res),
      'confirmed', (select count(*) from res where status in ('confirmada','cumplida')),
      'fulfilled', (select count(*) from res where status = 'cumplida'),
      'cancelled', (select count(*) from res where status = 'cancelada'),
      'noShow', (select count(*) from res where status = 'no_show'),
      'guests', (select coalesce(sum(party_size),0) from res where status <> 'cancelada'),
      'deposits', (select coalesce(sum(deposit_required),0) from res where deposit_paid),
      'byDay', coalesce((
        select jsonb_agg(jsonb_build_object(
          'day', to_char(d, 'YYYY-MM-DD'),
          'total', (select count(*) from res where reserved_date = d::date),
          'guests', (select coalesce(sum(party_size),0) from res where reserved_date = d::date and status <> 'cancelada')
        ) order by d)
        from generate_series(p_from::timestamp, p_to::timestamp, interval '1 day') g(d)
      ), '[]'::jsonb),
      'byDow', coalesce((
        select jsonb_agg(jsonb_build_object('dow', dw, 'total', v) order by dw)
        from (
          select extract(isodow from reserved_date)::int dw, count(*) v
          from res where status <> 'cancelada' group by 1
        ) t
      ), '[]'::jsonb),
      'byHour', coalesce((
        select jsonb_agg(jsonb_build_object('hour', h, 'total', v) order by h)
        from (
          select extract(hour from reserved_time)::int h, count(*) v
          from res where status <> 'cancelada' group by 1
        ) t
      ), '[]'::jsonb)
    ),
    -- Bandera para el panel: ¿esta clave puede elegir sede? (sólo el dueño)
    'scope', jsonb_build_object(
      'canFilter', v_forced is null,
      'location', v_loc
    )
  ) into result;

  return result;
end
$$;

-- El wrapper con nombre neutro (no lo bloquean los bloqueadores de anuncios)
-- pasa también el filtro de sede.
create or replace function public.staff_resumen(
  p_code text, p_from date, p_to date, p_location text default null
)
returns jsonb
language sql
security definer set search_path = public
as $$
  select public.staff_analytics(p_code, p_from, p_to, p_location);
$$;

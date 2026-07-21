-- La analítica y las estadísticas de clientes cuentan SÓLO pedidos pagados.
-- Antes sumaban todos; como ahora un pedido nace sin pagar, uno abandonado
-- inflaría los ingresos con plata que nunca entró.

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
      and o.paid
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

-- Estadísticas de cada cliente: sólo pedidos pagados.
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
      'ordersCount', (select count(*) from orders o where o.client_id = c.id and o.paid),
      'totalSpent', (select coalesce(sum(o.total),0) from orders o where o.client_id = c.id and o.paid),
      'lastOrderAt', (select max(o.created_at) from orders o where o.client_id = c.id and o.paid)
    ) order by c.last_activity_at desc)
    from clients c
  ), '[]'::jsonb);
end
$$;

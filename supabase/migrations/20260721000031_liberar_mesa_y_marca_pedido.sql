-- ══════════════════════════════════════════════════════════════════
-- (1) Liberar la mesa cuando la reserva ya se cumplió (los clientes se fueron)
--     Antes el plano contaba 'cumplida' como ocupada; ahora solo cuentan las
--     pendientes y confirmadas. Al marcar cumplida, la mesa queda libre.
-- (2) Cocina por marca: cada plato del pedido trae su marca (roka/panisse),
--     para poder mostrar el pedido dividido por cocina en Pilares.
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
                and r.status not in ('cancelada','no_show','cumplida')
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

-- Marca de un plato del pedido (por su producto → sección → carta).
create or replace function public.product_brand(p_product_id text)
returns text
language sql stable
security definer set search_path = public
as $$
  select coalesce((
    select m.brand
    from products p
    join sections s on s.id = p.section_id
    join menus m on m.slug = s.menu_slug
    where p.id = p_product_id
  ), 'panisse')
$$;

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
          'note', i.note, 'unitPrice', i.unit_price, 'qty', i.qty,
          'brand', product_brand(i.product_id)))
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
          'note', i.note, 'unitPrice', i.unit_price, 'qty', i.qty,
          'brand', product_brand(i.product_id)))
        from order_items i where i.order_id = o.id), '[]'::jsonb)
    ) order by o.created_at desc)
    from orders o
    where not o.paid and o.status <> 'recogido'
      and o.created_at > now() - interval '24 hours'
      and (v_loc is null or o.location_id = v_loc)
  ), '[]'::jsonb);
end
$$;

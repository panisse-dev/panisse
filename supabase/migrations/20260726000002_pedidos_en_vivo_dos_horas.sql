-- ══════════════════════════════════════════════════════════════════
-- Pantalla "En vivo": los pedidos ya entregados se quedan 2 horas, no 6.
--
-- El panel de cocina consulta cada 8 segundos y traía TODOS los pedidos
-- del día, incluidos los entregados horas antes. Con 60 pedidos diarios
-- eso multiplicaba el tráfico sin darle nada útil a la cocina.
--
-- No se pierde nada: el historial por día sigue trayendo el día completo,
-- y de ahí sale también el archivo de Excel.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_orders(p_code text, p_day date default null)
returns jsonb
language plpgsql
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
        -- En vivo: lo que está en marcha + lo entregado en las últimas 2 horas.
        o.status <> 'recogido' or o.status_at > now() - interval '2 hours'
      else
        -- Historial: el día completo, tal cual.
        (o.created_at at time zone 'America/Bogota')::date = p_day
      end
  ), '[]'::jsonb);
end
$$;

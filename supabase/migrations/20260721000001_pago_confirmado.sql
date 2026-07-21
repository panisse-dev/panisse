-- Confirmación de pago antes de entrar a la cocina.
--
-- Ahora el pago es en línea (transferencia o link). El pedido nace SIN pagar
-- y NO aparece en la cola de la cocina hasta que el personal confirme el pago.
-- El personal ve los pendientes en una lista aparte ("Por confirmar pago").

-- ── Marca de pago en el pedido ──
alter table public.orders add column if not exists paid boolean not null default false;
alter table public.orders add column if not exists paid_at timestamptz;

-- Los pedidos que ya existían se dan por pagados para no frenar la operación.
update public.orders set paid = true where paid_at is null and paid = false;

-- Pedidos nuevos: default false (create_order no menciona la columna, así que
-- entra sin pagar automáticamente).

-- ── La cocina sólo ve lo ya pagado ──
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
      'paid', o.paid,
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
    where o.paid and case
      when p_day is null then
        o.status <> 'recogido' or o.status_at > now() - interval '6 hours'
      else
        (o.created_at at time zone 'America/Bogota')::date = p_day
    end
  ), '[]'::jsonb);
end
$$;

-- ── Pedidos pendientes de pago (lista aparte del personal) ──
-- Sólo los recientes (24 h): si alguien nunca paga, deja de aparecer solo.
create or replace function public.staff_pending_orders(p_code text)
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
      'paid', o.paid,
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
    ) order by o.created_at desc)
    from orders o
    where not o.paid
      and o.status <> 'recogido'
      and o.created_at > now() - interval '24 hours'
  ), '[]'::jsonb);
end
$$;

-- ── Confirmar el pago: el pedido pasa a la cola de la cocina ──
create or replace function public.staff_confirm_payment(p_code text, p_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  -- status_at = now() para que en la cocina el "hace X min" cuente desde que
  -- realmente entró (al confirmarse el pago), no desde que se hizo el pedido.
  update orders set paid = true, paid_at = now(), status_at = now()
  where id = p_id and not paid;
end
$$;

-- ── Descartar un pendiente que nunca pagó (limpieza) ──
-- Sólo se pueden borrar pedidos SIN pagar, nunca uno ya confirmado.
create or replace function public.staff_discard_order(p_code text, p_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  delete from orders where id = p_id and not paid;
end
$$;

-- ── El cliente ve si su pago ya fue confirmado ──
create or replace function public.get_order_public(p_id uuid)
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'code', o.code, 'status', o.status, 'createdAt', o.created_at, 'paid', o.paid
  )
  from orders o where o.id = p_id
$$;

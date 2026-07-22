-- ══════════════════════════════════════════════════════════════════
-- Al confirmar el pago, el pedido empieza a prepararse automáticamente.
--
-- Antes: "Confirmar pago" dejaba el pedido en "Recibido" y había que darle
-- otro toque para pasarlo a "En preparación". Ahora, al confirmar el pago,
-- pasa solo a "En preparación", y el cliente lo ve al instante.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_confirm_payment(p_code text, p_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  -- status_at = now() para que el "hace X min" de la cocina cuente desde que
  -- entró de verdad (al confirmarse el pago). El pedido arranca preparándose.
  update orders
  set paid = true, paid_at = now(), status = 'preparacion', status_at = now()
  where id = p_id and not paid;
end
$$;

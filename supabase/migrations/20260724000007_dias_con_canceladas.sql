-- ══════════════════════════════════════════════════════════════════
-- La fila de "próximos días" del panel ahora también cuenta las
-- canceladas (aparte), para llevar la cuenta de cuántos cancelan.
-- Un día en el que todas se cancelaron ya no desaparece de la fila.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_reservations_upcoming(p_code text)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_today date := (now() at time zone 'America/Bogota')::date;
  v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'day', d.reserved_date,
             'total', d.total,
             'pendientes', d.pend,
             'canceladas', d.canc
           ) order by d.reserved_date)
    from (
      select r.reserved_date,
             count(*) filter (where r.status <> 'cancelada') as total,
             count(*) filter (where r.status = 'pendiente') as pend,
             count(*) filter (where r.status = 'cancelada') as canc
      from reservations r
      where r.reserved_date >= v_today
        and (v_loc is null or r.location_id = v_loc)
      group by r.reserved_date
    ) d
  ), '[]'::jsonb);
end
$$;

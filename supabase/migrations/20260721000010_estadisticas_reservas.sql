-- ══════════════════════════════════════════════════════════════════
-- Estadísticas de reservas (como Métricas de Precompro)
--
-- Resumen de reservas en un rango de fechas, por sede: totales, personas,
-- efectivas vs canceladas/no llegó, y series por día, por mes y por hora.
-- Sólo lectura, agregado en una función (nada toca lo existente).
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_reservation_stats(p_code text, p_from date, p_to date)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_loc text;
  v_from date := coalesce(p_from, (now() at time zone 'America/Bogota')::date - 29);
  v_to date := coalesce(p_to, (now() at time zone 'America/Bogota')::date);
  v_result jsonb;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);

  with base as (
    select r.*
    from reservations r
    where r.reserved_date between v_from and v_to
      and (v_loc is null or r.location_id = v_loc)
  ),
  -- "Efectiva" = confirmada o cumplida (llegó de verdad o va a llegar).
  eff as (select * from base where status in ('confirmada','cumplida'))
  select jsonb_build_object(
    'kpis', jsonb_build_object(
      'total', (select count(*) from base where status <> 'cancelada'),
      'people', (select coalesce(sum(party_size),0) from base where status not in ('cancelada','no_show')),
      'effective', (select count(*) from eff),
      'pending', (select count(*) from base where status = 'pendiente'),
      'noShow', (select count(*) from base where status = 'no_show'),
      'cancelled', (select count(*) from base where status = 'cancelada'),
      'avgParty', (
        select round(avg(party_size)::numeric, 1) from base where status <> 'cancelada'
      )
    ),
    'byDay', coalesce((
      select jsonb_agg(jsonb_build_object('day', d.day, 'count', d.cnt, 'people', d.ppl) order by d.day)
      from (
        select reserved_date as day,
               count(*) filter (where status <> 'cancelada') as cnt,
               coalesce(sum(party_size) filter (where status not in ('cancelada','no_show')),0) as ppl
        from base group by reserved_date
      ) d
    ), '[]'::jsonb),
    'byMonth', coalesce((
      select jsonb_agg(jsonb_build_object('month', m.mon, 'count', m.cnt, 'people', m.ppl) order by m.mon)
      from (
        select to_char(reserved_date, 'YYYY-MM') as mon,
               count(*) filter (where status <> 'cancelada') as cnt,
               coalesce(sum(party_size) filter (where status not in ('cancelada','no_show')),0) as ppl
        from base group by to_char(reserved_date, 'YYYY-MM')
      ) m
    ), '[]'::jsonb),
    'byHour', coalesce((
      select jsonb_agg(jsonb_build_object('hour', h.hr, 'count', h.cnt) order by h.hr)
      from (
        select extract(hour from reserved_time)::int as hr, count(*) as cnt
        from base where status <> 'cancelada'
        group by extract(hour from reserved_time)::int
      ) h
    ), '[]'::jsonb),
    'byStatus', jsonb_build_object(
      'pendiente', (select count(*) from base where status = 'pendiente'),
      'confirmada', (select count(*) from base where status = 'confirmada'),
      'cumplida', (select count(*) from base where status = 'cumplida'),
      'no_show', (select count(*) from base where status = 'no_show'),
      'cancelada', (select count(*) from base where status = 'cancelada')
    ),
    'byLocation', coalesce((
      select jsonb_agg(jsonb_build_object('id', x.lid, 'name', l.name, 'count', x.cnt) order by x.cnt desc)
      from (
        select location_id as lid, count(*) as cnt
        from base where status <> 'cancelada'
        group by location_id
      ) x join locations l on l.id = x.lid
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end
$$;

-- Estadísticas de reservas: agregar PERSONAS por origen (web/teléfono/Google),
-- como en Precompro (763 reservas / 4709 personas por canal). Igual que la
-- versión de 20260721000016, solo cambia el bloque byOrigin.

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
    select r.*,
      case
        when extract(hour from r.reserved_time) < 11 then 'desayuno'
        when extract(hour from r.reserved_time) < 16 then 'almuerzo'
        else 'cena'
      end as meal
    from reservations r
    where r.reserved_date between v_from and v_to
      and (v_loc is null or r.location_id = v_loc)
  ),
  eff as (select * from base where status in ('confirmada','cumplida'))
  select jsonb_build_object(
    'kpis', jsonb_build_object(
      'total', (select count(*) from base where status <> 'cancelada'),
      'totalPeople', (select coalesce(sum(party_size),0) from base where status not in ('cancelada','no_show')),
      'effective', (select count(*) from eff),
      'effectivePeople', (select coalesce(sum(party_size),0) from eff),
      'pending', (select count(*) from base where status = 'pendiente'),
      'noShow', (select count(*) from base where status = 'no_show'),
      'cancelled', (select count(*) from base where status = 'cancelada'),
      'avgParty', (select round(avg(party_size)::numeric, 1) from base where status <> 'cancelada')
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
    'byMeal', jsonb_build_object(
      'desayuno', (select count(*) from base where status <> 'cancelada' and meal = 'desayuno'),
      'almuerzo', (select count(*) from base where status <> 'cancelada' and meal = 'almuerzo'),
      'cena', (select count(*) from base where status <> 'cancelada' and meal = 'cena')
    ),
    'byOrigin', coalesce((
      select jsonb_agg(jsonb_build_object('source', o.src, 'count', o.cnt, 'people', o.ppl) order by o.cnt desc)
      from (
        select source as src,
               count(*) as cnt,
               coalesce(sum(party_size) filter (where status <> 'no_show'), 0) as ppl
        from base where status <> 'cancelada'
        group by source
      ) o
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

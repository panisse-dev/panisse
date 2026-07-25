-- ══════════════════════════════════════════════════════════════════
-- Decoración para el mismo día (Globo de cumpleaños, Cerritos)
--
-- Hasta ahora la anticipación se medía en días. Esta se puede hacer el
-- mismo día siempre que falten 3 horas, así que se agrega la
-- anticipación en HORAS, que se mide contra la hora de la reserva.
--
-- Además, el rótulo de las opciones deja de ser fijo ("Tono de las
-- rosas"): cada decoración dice cómo se llama su opción (aquí, el color
-- del globo).
-- ══════════════════════════════════════════════════════════════════

alter table public.decorations add column if not exists advance_hours int not null default 0;
alter table public.decorations add column if not exists option_label text not null default '';

update public.decorations set option_label = 'Tono de las rosas'
 where array_length(color_options, 1) is not null and option_label = '';

insert into public.decorations (
  id, name, description, price, sort, active, image,
  location_id, advance_days, advance_hours, prepaid, color_options, option_label,
  dessert_mode, dessert_price
) values (
  'globo_cumple', 'Globo de cumpleaños',
  'Globo Happy Birthday con moño y base · Postre con vela (sabor según disponibilidad) · Tarjeta',
  50000, 5, true, null,
  'cerritos', 0, 3, true,
  array['Azul naval (hombre)','Arena (mujer)'], 'Color del globo',
  'none', 0
)
on conflict (id) do update set
  name = excluded.name, description = excluded.description, price = excluded.price,
  sort = excluded.sort, location_id = excluded.location_id,
  advance_days = excluded.advance_days, advance_hours = excluded.advance_hours,
  prepaid = excluded.prepaid, color_options = excluded.color_options,
  option_label = excluded.option_label;

-- ── Lo que ve el cliente: ahora también se mira la HORA de la reserva ──
create or replace function public.public_decorations(
  p_location text default null, p_date date default null, p_time time default null)
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', d.id, 'name', d.name, 'description', d.description,
    'price', d.price, 'image', d.image,
    'advanceDays', d.advance_days, 'advanceHours', d.advance_hours,
    'prepaid', d.prepaid,
    'colorOptions', to_jsonb(d.color_options), 'optionLabel', d.option_label,
    'dessertMode', d.dessert_mode, 'dessertPrice', d.dessert_price,
    'available', case
      when p_date is null then true
      -- Con días de anticipación: basta con que la fecha esté lejos.
      when d.advance_days > 0 then
        p_date >= ((now() at time zone 'America/Bogota')::date + d.advance_days)
      -- Con horas: se compara contra el momento exacto de la reserva.
      when d.advance_hours > 0 then
        (p_date + coalesce(p_time, time '23:59'))
          >= (now() at time zone 'America/Bogota') + make_interval(hours => d.advance_hours)
      else true
    end
  ) order by d.sort, d.name), '[]'::jsonb)
  from decorations d
  where d.active
    and (d.location_id is null or p_location is null or d.location_id = p_location);
$$;

grant execute on function public.public_decorations(text, date, time) to anon, authenticated;

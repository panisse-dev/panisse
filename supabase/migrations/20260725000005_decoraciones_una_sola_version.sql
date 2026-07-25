-- ══════════════════════════════════════════════════════════════════
-- Quedaron tres versiones de public_decorations conviviendo (sin datos,
-- con fecha, y con fecha+hora) y la nueva tenía valores por defecto, así
-- que llamarla "sin datos" era ambiguo y fallaba. Un navegador con la
-- página guardada podía quedarse sin ver ninguna decoración.
--
-- Se deja UNA sola versión, sin valores por defecto, y una compatible de
-- dos datos que reenvía a la buena para las páginas ya guardadas.
-- ══════════════════════════════════════════════════════════════════

drop function if exists public.public_decorations();
drop function if exists public.public_decorations(text, date);
drop function if exists public.public_decorations(text, date, time);

create function public.public_decorations(p_location text, p_date date, p_time time)
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

-- Compatibilidad con páginas ya cargadas en el navegador del cliente.
create function public.public_decorations(p_location text, p_date date)
returns jsonb
language sql stable
security definer set search_path = public
as $$ select public.public_decorations(p_location, p_date, null::time) $$;

grant execute on function public.public_decorations(text, date, time) to anon, authenticated;
grant execute on function public.public_decorations(text, date) to anon, authenticated;

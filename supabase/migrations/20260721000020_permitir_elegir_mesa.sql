-- ══════════════════════════════════════════════════════════════════
-- Interruptor: permitir (o no) que el cliente escoja su mesa al reservar
--
-- Se agrega a la configuración de reservas. Cuando está apagado, el cliente
-- reserva sin ver el mapa (el restaurante asigna la mesa). Por defecto
-- ENCENDIDO. Se expone en la config pública y en el panel.
-- ══════════════════════════════════════════════════════════════════

alter table public.reservation_settings
  add column if not exists allow_table_choice boolean not null default true;

-- Config pública (la que usa el flujo del cliente)
create or replace function public.reservation_config()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'enabled', s.enabled,
    'openDays', s.open_days,
    'startTime', to_char(s.start_time, 'HH24:MI'),
    'endTime', to_char(s.end_time, 'HH24:MI'),
    'slotMinutes', s.slot_minutes,
    'maxParty', s.max_party,
    'advanceDays', s.advance_days,
    'minHours', s.min_hours,
    'depositPerPerson', s.deposit_per_person,
    'allowTableChoice', s.allow_table_choice
  )
  from reservation_settings s where s.id;
$$;

-- Config del panel (lectura)
create or replace function public.staff_reservation_settings(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return (
    select jsonb_build_object(
      'enabled', s.enabled,
      'openDays', s.open_days,
      'startTime', to_char(s.start_time, 'HH24:MI'),
      'endTime', to_char(s.end_time, 'HH24:MI'),
      'slotMinutes', s.slot_minutes,
      'turnMinutes', s.turn_minutes,
      'capacity', s.capacity,
      'maxParty', s.max_party,
      'advanceDays', s.advance_days,
      'minHours', s.min_hours,
      'depositPerPerson', s.deposit_per_person,
      'allowTableChoice', s.allow_table_choice
    )
    from reservation_settings s where s.id
  );
end
$$;

-- Config del panel (guardar)
create or replace function public.staff_update_reservation_settings(p_code text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update reservation_settings set
    enabled = coalesce((p->>'enabled')::boolean, enabled),
    open_days = coalesce((select array_agg(x)::int[] from jsonb_array_elements_text(p->'openDays') t(x)), open_days),
    start_time = coalesce((p->>'startTime')::time, start_time),
    end_time = coalesce((p->>'endTime')::time, end_time),
    slot_minutes = greatest(5, coalesce((p->>'slotMinutes')::int, slot_minutes)),
    turn_minutes = greatest(15, coalesce((p->>'turnMinutes')::int, turn_minutes)),
    capacity = greatest(1, coalesce((p->>'capacity')::int, capacity)),
    max_party = greatest(1, coalesce((p->>'maxParty')::int, max_party)),
    advance_days = greatest(1, coalesce((p->>'advanceDays')::int, advance_days)),
    min_hours = greatest(0, coalesce((p->>'minHours')::int, min_hours)),
    deposit_per_person = greatest(0, coalesce((p->>'depositPerPerson')::int, deposit_per_person)),
    allow_table_choice = coalesce((p->>'allowTableChoice')::boolean, allow_table_choice),
    updated_at = now()
  where id;
end
$$;

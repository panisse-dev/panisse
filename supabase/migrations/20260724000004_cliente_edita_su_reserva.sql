-- ══════════════════════════════════════════════════════════════════
-- El cliente puede cambiar o cancelar su propia reserva desde el enlace
-- que le llega al correo (lleva el id secreto de la reserva).
--   · public_reservation_view(id)   → qué reserva es y si aún se puede tocar
--   · public_update_reservation(id) → cambiar fecha, hora o personas
--   · public_cancel_reservation(id) → cancelarla
-- Se revalida todo (día abierto, hora válida, cupo) igual que al crearla.
-- ══════════════════════════════════════════════════════════════════

-- Dirección del sitio, para armar el enlace del correo.
insert into public.app_secrets (key, value)
values ('site_url', 'https://panisse.netlify.app')
on conflict (key) do nothing;

-- ── Ficha pública de la reserva (para la pantalla del cliente) ──
create or replace function public.public_reservation_view(p_id uuid)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  r reservations;
  s reservation_settings%rowtype;
  v_sede text;
  v_today date := (now() at time zone 'America/Bogota')::date;
  v_now_min int := mins_of((now() at time zone 'America/Bogota')::time);
  v_editable boolean;
begin
  select * into r from reservations where id = p_id;
  if r.id is null then return null; end if;
  select * into s from reservation_settings where id;
  select name into v_sede from locations where id = r.location_id;

  -- Se puede tocar si sigue viva y todavía falta el tiempo mínimo de aviso.
  v_editable := r.status in ('pendiente','confirmada')
    and (r.reserved_date > v_today
         or (r.reserved_date = v_today
             and mins_of(r.reserved_time) >= v_now_min + s.min_hours * 60));

  return jsonb_build_object(
    'code', r.code,
    'status', r.status,
    'date', r.reserved_date,
    'time', to_char(r.reserved_time, 'HH24:MI'),
    'party', r.party_size,
    'name', coalesce(r.customer_name, ''),
    'location', r.location_id,
    'locationName', coalesce(v_sede, ''),
    'editable', v_editable
  );
end
$$;

-- ── Cambiar fecha, hora o número de personas ──
create or replace function public.public_update_reservation(p_id uuid, p jsonb)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  r reservations;
  s reservation_settings%rowtype;
  v_date date;
  v_time time;
  v_party int;
  v_today date := (now() at time zone 'America/Bogota')::date;
  v_now_min int := mins_of((now() at time zone 'America/Bogota')::time);
  v_dow int;
  v_m int;
  v_sub int;
  v_slot int;
  v_turn int;
  v_peak int;
  v_load int;
begin
  select * into r from reservations where id = p_id;
  if r.id is null then raise exception 'No encontramos esa reserva'; end if;
  if r.status not in ('pendiente','confirmada') then
    raise exception 'Esa reserva ya no se puede cambiar';
  end if;

  select * into s from reservation_settings where id;
  if not s.enabled then raise exception 'Las reservas no están disponibles por ahora.'; end if;

  begin
    v_date := (p->>'date')::date;
    v_time := (p->>'time')::time;
  exception when others then
    raise exception 'Fecha u hora no válidas';
  end;
  v_party := coalesce(nullif(p->>'party','')::int, 0);
  if v_party < 1 or v_party > s.max_party then
    raise exception 'El número de personas no es válido';
  end if;

  if v_date < v_today or v_date > v_today + s.advance_days then
    raise exception 'Esa fecha no está disponible';
  end if;
  v_dow := extract(isodow from v_date)::int;
  if not (v_dow = any(s.open_days)) then
    raise exception 'Ese día no recibimos reservas';
  end if;
  if reservation_day_blocked(r.location_id, v_date) then
    raise exception 'Ese día no estamos recibiendo reservas';
  end if;

  v_slot := greatest(5, s.slot_minutes);
  v_turn := greatest(v_slot, s.turn_minutes);
  v_m := mins_of(v_time);
  if v_m < mins_of(s.start_time) or v_m > mins_of(s.end_time) then
    raise exception 'Esa hora no está disponible';
  end if;
  if v_date = v_today and v_m < v_now_min + s.min_hours * 60 then
    raise exception 'Esa hora ya es muy pronto, elige una más adelante';
  end if;
  if reservation_min_blocked(r.location_id, v_date, v_m) then
    raise exception 'Esa hora no está disponible';
  end if;

  perform pg_advisory_xact_lock(hashtext('reserva:' || r.location_id || ':' || v_date::text));

  -- Cupo del salón, sin contar esta misma reserva.
  v_peak := 0;
  v_sub := v_m;
  while v_sub < v_m + v_turn loop
    select coalesce(sum(x.party_size), 0) into v_load
    from reservations x
    where x.reserved_date = v_date
      and x.location_id = r.location_id
      and x.id <> r.id
      and x.status in ('pendiente', 'confirmada')
      and mins_of(x.reserved_time) <= v_sub
      and mins_of(x.reserved_time) + v_turn > v_sub;
    if v_load > v_peak then v_peak := v_load; end if;
    v_sub := v_sub + v_slot;
  end loop;
  if v_peak + v_party > s.capacity then
    raise exception 'Esa hora se acaba de llenar, elige otra por favor';
  end if;

  -- La mesa asignada se suelta: con otra fecha u hora puede no servir.
  update reservations
     set reserved_date = v_date,
         reserved_time = v_time,
         party_size = v_party,
         table_id = null,
         status_at = now()
   where id = r.id;

  perform send_reservation_email(r.id);

  return public_reservation_view(r.id);
end
$$;

-- ── Cancelar la reserva ──
create or replace function public.public_cancel_reservation(p_id uuid)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare r reservations;
begin
  select * into r from reservations where id = p_id;
  if r.id is null then raise exception 'No encontramos esa reserva'; end if;
  if r.status = 'cancelada' then return public_reservation_view(r.id); end if;
  if r.status not in ('pendiente','confirmada') then
    raise exception 'Esa reserva ya no se puede cancelar';
  end if;
  update reservations set status = 'cancelada', status_at = now(), table_id = null
   where id = r.id;
  return public_reservation_view(r.id);
end
$$;

grant execute on function public.public_reservation_view(uuid) to anon, authenticated;
grant execute on function public.public_update_reservation(uuid, jsonb) to anon, authenticated;
grant execute on function public.public_cancel_reservation(uuid) to anon, authenticated;

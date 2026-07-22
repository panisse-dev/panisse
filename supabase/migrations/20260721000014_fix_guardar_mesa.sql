-- ══════════════════════════════════════════════════════════════════
-- Corrige staff_save_table: al editar una mesa (nombre, cupo, forma) se
-- deben CONSERVAR la posición y el tamaño si no vienen en la llamada. Antes
-- caían a valores por defecto (la mesa saltaba a la esquina). Ahora sólo se
-- cambia lo que se envía.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_save_table(p_code text, p jsonb)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_id uuid := nullif(p->>'id','')::uuid;
  v_zone uuid := nullif(p->>'zoneId','')::uuid;
  v_name text := left(btrim(coalesce(p->>'name','')), 20);
  v_seats int := greatest(1, least(40, coalesce((p->>'seats')::int, 2)));
  v_shape text := lower(coalesce(nullif(p->>'shape',''), 'rect'));
  -- Sólo se aplican si vienen (null = conservar lo que ya tenía la mesa).
  v_w int := case when (p ? 'width') then greatest(48, least(260, (p->>'width')::int)) end;
  v_h int := case when (p ? 'height') then greatest(48, least(260, (p->>'height')::int)) end;
  v_x int := case when (p ? 'posX') then greatest(0, (p->>'posX')::int) end;
  v_y int := case when (p ? 'posY') then greatest(0, (p->>'posY')::int) end;
  v_loc text;
  v_zone_loc text;
begin
  if v_shape not in ('rect','round') then v_shape := 'rect'; end if;
  if v_name = '' then raise exception 'Ponle un nombre a la mesa'; end if;

  if v_id is not null then
    select location_id into v_loc from restaurant_tables where id = v_id;
    if v_loc is null then raise exception 'Mesa no encontrada'; end if;
    perform assert_staff_location(p_code, v_loc);
    if v_zone is not null then
      select location_id into v_zone_loc from zones where id = v_zone;
      if v_zone_loc is null or v_zone_loc <> v_loc then raise exception 'Zona inválida'; end if;
    end if;
    update restaurant_tables set
      zone_id = coalesce(v_zone, zone_id),
      name = v_name, seats = v_seats, shape = v_shape,
      width = coalesce(v_w, width),
      height = coalesce(v_h, height),
      pos_x = coalesce(v_x, pos_x),
      pos_y = coalesce(v_y, pos_y)
    where id = v_id;
    return v_id;
  else
    if v_zone is null then raise exception 'Falta la zona'; end if;
    select location_id into v_zone_loc from zones where id = v_zone;
    if v_zone_loc is null then raise exception 'Zona no encontrada'; end if;
    perform assert_staff_location(p_code, v_zone_loc);
    insert into restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort)
    values (v_zone, v_zone_loc, v_name, v_seats, v_shape,
            coalesce(v_w, 96), coalesce(v_h, 64), coalesce(v_x, 20), coalesce(v_y, 20),
            (select coalesce(max(sort),0)+1 from restaurant_tables where zone_id = v_zone))
    returning id into v_id;
    return v_id;
  end if;
end
$$;

-- Devuelve VIP4 a una posición despejada tras la prueba.
update public.restaurant_tables set pos_x = 110, pos_y = 140
where location_id = 'cerritos' and name = 'VIP4';

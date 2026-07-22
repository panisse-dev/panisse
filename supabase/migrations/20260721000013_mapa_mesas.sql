-- ══════════════════════════════════════════════════════════════════
-- Mapa de mesas editable (plano estilo Precompro)
--
-- Cada mesa tiene posición (x,y), tamaño y forma (rectangular o redonda),
-- así el restaurante organiza y distribuye su salón arrastrando las mesas
-- en un plano. Se pueden crear/renombrar/borrar zonas y mesas. Se siembra
-- el perfil de Panisse (zona RESTAURANTE con mesas rectangulares y zona VIP
-- con mesas redondas) en la sede Cerritos como punto de partida editable.
-- ══════════════════════════════════════════════════════════════════

alter table public.restaurant_tables
  add column if not exists pos_x int not null default 20,
  add column if not exists pos_y int not null default 20,
  add column if not exists width int not null default 90,
  add column if not exists height int not null default 64,
  add column if not exists shape text not null default 'rect'
    check (shape in ('rect','round'));

-- ── Posiciones para las mesas ya existentes (rejilla, para que no se
--    amontonen en 0,0 la primera vez) ──
with ordered as (
  select id, row_number() over (partition by zone_id order by sort, name) - 1 as n
  from restaurant_tables
)
update restaurant_tables t
set pos_x = 20 + (o.n % 4) * 110,
    pos_y = 20 + (o.n / 4) * 100
from ordered o
where o.id = t.id
  and t.pos_x = 20 and t.pos_y = 20;   -- sólo las que aún no se han movido

-- ── Sembrar el perfil de Panisse en Cerritos (reemplaza el de práctica) ──
do $$
declare
  v_rest uuid;
  v_vip uuid;
begin
  -- Sólo si Cerritos aún no tiene la zona RESTAURANTE (para no duplicar).
  if not exists (select 1 from zones where location_id = 'cerritos' and name = 'RESTAURANTE') then
    -- Fuera las zonas de práctica de Cerritos (Roka I/II/Toscana). Sus mesas
    -- caen por cascada. No hay reservas reales asignadas todavía.
    delete from zones where location_id = 'cerritos';

    insert into zones (location_id, name, sort) values ('cerritos','RESTAURANTE',1)
      returning id into v_rest;
    insert into restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort) values
      (v_rest,'cerritos','M1',2,'rect', 80,64,  20, 20,1),
      (v_rest,'cerritos','M2',4,'rect', 96,64, 120, 20,2),
      (v_rest,'cerritos','M3',4,'rect', 96,64, 232, 20,3),
      (v_rest,'cerritos','M4',4,'rect', 96,64, 344, 20,4),
      (v_rest,'cerritos','M5',6,'rect',120,72, 456, 20,5),
      (v_rest,'cerritos','M6',4,'rect', 96,64,  20,140,6),
      (v_rest,'cerritos','M7',2,'rect', 80,64, 132,140,7),
      (v_rest,'cerritos','M8',4,'rect', 96,64, 232,140,8),
      (v_rest,'cerritos','M9',6,'rect',120,72, 344,140,9),
      (v_rest,'cerritos','M10',2,'rect',80,64,  20,260,10),
      (v_rest,'cerritos','M11',3,'rect',96,64, 120,260,11),
      (v_rest,'cerritos','M12',6,'rect',120,72,232,260,12);

    insert into zones (location_id, name, sort) values ('cerritos','VIP',2)
      returning id into v_vip;
    insert into restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort) values
      (v_vip,'cerritos','VIP1',4,'round',84,84,  40, 20,1),
      (v_vip,'cerritos','VIP2',4,'round',84,84, 180, 20,2),
      (v_vip,'cerritos','VIP3',4,'round',84,84, 320, 20,3),
      (v_vip,'cerritos','VIP4',4,'round',84,84, 110,140,4),
      (v_vip,'cerritos','VIP5',4,'round',84,84, 250,140,5);
  end if;
end $$;

-- ── El salón devuelve también la geometría de cada mesa ──
create or replace function public.staff_floor(p_code text, p_day date default null, p_location text default null)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare
  v_day date := coalesce(p_day, (now() at time zone 'America/Bogota')::date);
  v_staff_loc text;
  v_loc text;
begin
  perform assert_staff(p_code);
  v_staff_loc := staff_location(p_code);
  if v_staff_loc is not null then
    v_loc := v_staff_loc;
  else
    v_loc := coalesce(nullif(p_location,''), 'cerritos');
  end if;

  return jsonb_build_object(
    'locationId', v_loc,
    'zones', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', z.id, 'name', z.name, 'sort', z.sort,
        'tables', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id, 'name', t.name, 'seats', t.seats,
            'posX', t.pos_x, 'posY', t.pos_y, 'width', t.width, 'height', t.height, 'shape', t.shape,
            'reservations', coalesce((
              select jsonb_agg(jsonb_build_object(
                'id', r.id, 'time', to_char(r.reserved_time,'HH24:MI'), 'party', r.party_size,
                'name', r.customer_name, 'status', r.status, 'isWalkIn', r.is_walk_in
              ) order by r.reserved_time)
              from reservations r
              where r.table_id = t.id and r.reserved_date = v_day
                and r.status not in ('cancelada','no_show')
            ), '[]'::jsonb)
          ) order by t.sort, t.name)
          from restaurant_tables t where t.zone_id = z.id and t.active
        ), '[]'::jsonb)
      ) order by z.sort, z.name)
      from zones z where z.location_id = v_loc
    ), '[]'::jsonb)
  );
end
$$;

-- ══════════════════════════════════════════════════════════════════
-- Edición del plano (zonas y mesas). Cada código de sede edita SÓLO la
-- suya; el código dueño edita cualquiera (indicando la sede al crear).
-- ══════════════════════════════════════════════════════════════════

-- Comprueba que el código puede tocar esa sede.
create or replace function public.assert_staff_location(p_code text, p_location text)
returns void
language plpgsql stable
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  if v_loc is not null and v_loc <> p_location then
    raise exception 'No autorizado' using errcode = '42501';
  end if;
end
$$;

-- Crear o renombrar una zona. Devuelve el id.
create or replace function public.staff_save_zone(p_code text, p jsonb)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_id uuid := nullif(p->>'id','')::uuid;
  v_loc text := nullif(p->>'locationId','');
  v_name text := left(btrim(coalesce(p->>'name','')), 40);
  v_sort int := coalesce((p->>'sort')::int, 0);
  v_existing_loc text;
begin
  if v_name = '' then raise exception 'Escribe el nombre de la zona'; end if;

  if v_id is not null then
    select location_id into v_existing_loc from zones where id = v_id;
    if v_existing_loc is null then raise exception 'Zona no encontrada'; end if;
    perform assert_staff_location(p_code, v_existing_loc);
    update zones set name = v_name, sort = v_sort where id = v_id;
    return v_id;
  else
    if v_loc is null then raise exception 'Falta la sede'; end if;
    perform assert_staff_location(p_code, v_loc);
    insert into zones (location_id, name, sort)
    values (v_loc, v_name, coalesce(nullif(v_sort,0), (select coalesce(max(sort),0)+1 from zones where location_id = v_loc)))
    returning id into v_id;
    return v_id;
  end if;
end
$$;

create or replace function public.staff_delete_zone(p_code text, p_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_loc text;
begin
  select location_id into v_loc from zones where id = p_id;
  if v_loc is null then return; end if;
  perform assert_staff_location(p_code, v_loc);
  delete from zones where id = p_id;   -- las mesas caen por cascada
end
$$;

-- Crear o editar una mesa (nombre, cupo, posición, tamaño, forma). Devuelve id.
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
  v_w int := greatest(48, least(260, coalesce((p->>'width')::int, 90)));
  v_h int := greatest(48, least(260, coalesce((p->>'height')::int, 64)));
  v_x int := greatest(0, coalesce((p->>'posX')::int, 20));
  v_y int := greatest(0, coalesce((p->>'posY')::int, 20));
  v_loc text;
  v_zone_loc text;
begin
  if v_shape not in ('rect','round') then v_shape := 'rect'; end if;
  if v_name = '' then raise exception 'Ponle un nombre a la mesa'; end if;

  if v_id is not null then
    select location_id into v_loc from restaurant_tables where id = v_id;
    if v_loc is null then raise exception 'Mesa no encontrada'; end if;
    perform assert_staff_location(p_code, v_loc);
    -- Si cambia de zona, validar que la nueva zona sea de la misma sede.
    if v_zone is not null then
      select location_id into v_zone_loc from zones where id = v_zone;
      if v_zone_loc is null or v_zone_loc <> v_loc then raise exception 'Zona inválida'; end if;
    end if;
    update restaurant_tables set
      zone_id = coalesce(v_zone, zone_id),
      name = v_name, seats = v_seats, shape = v_shape,
      width = v_w, height = v_h, pos_x = v_x, pos_y = v_y
    where id = v_id;
    return v_id;
  else
    if v_zone is null then raise exception 'Falta la zona'; end if;
    select location_id into v_zone_loc from zones where id = v_zone;
    if v_zone_loc is null then raise exception 'Zona no encontrada'; end if;
    perform assert_staff_location(p_code, v_zone_loc);
    insert into restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort)
    values (v_zone, v_zone_loc, v_name, v_seats, v_shape, v_w, v_h, v_x, v_y,
            (select coalesce(max(sort),0)+1 from restaurant_tables where zone_id = v_zone))
    returning id into v_id;
    return v_id;
  end if;
end
$$;

-- Mover una mesa (guardado ligero al arrastrar).
create or replace function public.staff_move_table(p_code text, p_id uuid, p_x int, p_y int)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_loc text;
begin
  select location_id into v_loc from restaurant_tables where id = p_id;
  if v_loc is null then return; end if;
  perform assert_staff_location(p_code, v_loc);
  update restaurant_tables set pos_x = greatest(0, p_x), pos_y = greatest(0, p_y) where id = p_id;
end
$$;

create or replace function public.staff_delete_table(p_code text, p_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_loc text;
begin
  select location_id into v_loc from restaurant_tables where id = p_id;
  if v_loc is null then return; end if;
  perform assert_staff_location(p_code, v_loc);
  delete from restaurant_tables where id = p_id;
end
$$;

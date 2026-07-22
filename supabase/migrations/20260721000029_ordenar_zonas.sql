-- ══════════════════════════════════════════════════════════════════
-- Reordenar salones + arreglo: renombrar una zona ya no le cambia el orden
--
-- Bug: staff_save_zone ponía sort = 0 al renombrar (no traía el sort), así
-- que la zona saltaba de lugar. Ahora, al editar, el orden se conserva salvo
-- que se mande explícitamente. Se agrega staff_move_zone para mover un salón
-- a la izquierda/derecha (renumera todo, robusto ante empates).
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_save_zone(p_code text, p jsonb)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_id uuid := nullif(p->>'id','')::uuid;
  v_loc text := nullif(p->>'locationId','');
  v_name text := left(btrim(coalesce(p->>'name','')), 40);
  v_has_sort boolean := (p ? 'sort') and nullif(p->>'sort','') is not null;
  v_sort int := (p->>'sort')::int;
  v_existing_loc text;
begin
  if v_name = '' then raise exception 'Escribe el nombre de la zona'; end if;

  if v_id is not null then
    select location_id into v_existing_loc from zones where id = v_id;
    if v_existing_loc is null then raise exception 'Zona no encontrada'; end if;
    perform assert_staff_location(p_code, v_existing_loc);
    -- El orden solo cambia si viene explícito; si no, se conserva.
    update zones set name = v_name,
       sort = case when v_has_sort then v_sort else sort end
     where id = v_id;
    return v_id;
  else
    if v_loc is null then raise exception 'Falta la sede'; end if;
    perform assert_staff_location(p_code, v_loc);
    insert into zones (location_id, name, sort)
    values (
      v_loc, v_name,
      coalesce(case when v_has_sort then v_sort end,
               (select coalesce(max(sort),0)+1 from zones where location_id = v_loc))
    )
    returning id into v_id;
    return v_id;
  end if;
end
$$;

-- Mover un salón: p_dir < 0 = izquierda, p_dir > 0 = derecha.
create or replace function public.staff_move_zone(p_code text, p_id uuid, p_dir int)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_loc text;
  v_ids uuid[];
  v_idx int;
  v_tgt int;
  v_step int := case when p_dir < 0 then -1 else 1 end;
  v_tmp uuid;
  i int;
begin
  select location_id into v_loc from zones where id = p_id;
  if v_loc is null then return; end if;
  perform assert_staff_location(p_code, v_loc);

  select array_agg(id order by sort, name) into v_ids from zones where location_id = v_loc;
  v_idx := array_position(v_ids, p_id);
  if v_idx is null then return; end if;
  v_tgt := v_idx + v_step;
  if v_tgt < 1 or v_tgt > array_length(v_ids, 1) then return; end if;

  v_tmp := v_ids[v_idx];
  v_ids[v_idx] := v_ids[v_tgt];
  v_ids[v_tgt] := v_tmp;

  -- Renumera de 0 en adelante según el nuevo orden (limpia empates).
  for i in 1 .. array_length(v_ids, 1) loop
    update zones set sort = i - 1 where id = v_ids[i];
  end loop;
end
$$;

-- Restaurar el orden original de Pilares (quedó descuadrado por el bug).
update public.zones set sort = 0 where location_id = 'pilares' and name = 'ROKA II';
update public.zones set sort = 1 where location_id = 'pilares' and name = 'ROKA I';
update public.zones set sort = 2 where location_id = 'pilares' and name = 'TOSCANA';

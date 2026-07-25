-- ══════════════════════════════════════════════════════════════════
-- Crear platos y secciones desde el panel
--
-- Hasta ahora la carta solo se podía EDITAR: los platos y secciones
-- venían cargados de la plataforma anterior y no había forma de agregar
-- uno nuevo sin tocar la base a mano. Esto lo abre desde el panel.
--
-- Para quitar un plato de la carta se sigue usando "Visible en la carta"
-- (queda archivado, no se borra): así los pedidos viejos y la analítica
-- no se dañan. Las secciones sí se pueden borrar, pero solo si están
-- vacías, para no arrastrar platos por accidente.
-- ══════════════════════════════════════════════════════════════════

-- ── Crear un plato dentro de una sección ──
create or replace function public.staff_create_product(p_code text, p_section_id uuid, p jsonb)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_name text := left(btrim(coalesce(p->>'name','')), 120);
  v_id uuid;
  v_sort int;
begin
  perform assert_staff(p_code);
  if v_name = '' then raise exception 'Escribe el nombre del plato'; end if;
  if not exists (select 1 from sections where id = p_section_id) then
    raise exception 'Esa sección no existe';
  end if;

  select coalesce(max(sort), 0) + 1 into v_sort from products where section_id = p_section_id;

  insert into products (section_id, name, description, prices, hide_price, image,
                        is_new, veg, visible, sort)
  values (
    p_section_id,
    v_name,
    left(btrim(coalesce(p->>'description','')), 600),
    coalesce(p->'prices', '[]'::jsonb),
    coalesce((p->>'hidePrice')::boolean, false),
    nullif(btrim(coalesce(p->>'image','')), ''),
    coalesce((p->>'isNew')::boolean, false),
    coalesce((p->>'veg')::boolean, false),
    coalesce((p->>'visible')::boolean, true),
    v_sort
  )
  returning id into v_id;
  return v_id;
end
$$;

-- ── Crear una sección (o subsección, si viene p_parent_id) ──
create or replace function public.staff_create_section(
  p_code text, p_menu_slug text, p_parent_id uuid, p_name text)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_name text := left(btrim(coalesce(p_name,'')), 80);
  v_slug text;
  v_id uuid;
  v_sort int;
  v_menu text := p_menu_slug;
begin
  perform assert_staff(p_code);
  if v_name = '' then raise exception 'Escribe el nombre de la sección'; end if;

  -- Si es subsección, hereda la carta de su sección madre.
  if p_parent_id is not null then
    select menu_slug into v_menu from sections where id = p_parent_id;
    if v_menu is null then raise exception 'Esa sección no existe'; end if;
  end if;
  if not exists (select 1 from menus where slug = v_menu) then
    raise exception 'Esa carta no existe';
  end if;

  -- Slug legible y único dentro de la carta (sirve para las pestañas).
  v_slug := regexp_replace(lower(translate(v_name,
              'áéíóúàèìòùäëïöüâêîôûñÁÉÍÓÚÑ', 'aeiouaeiouaeiouaeioun aeioun')),
            '[^a-z0-9]+', '-', 'g');
  v_slug := trim(both '-' from v_slug);
  if v_slug = '' then v_slug := 'seccion'; end if;
  if exists (select 1 from sections where menu_slug = v_menu and slug = v_slug) then
    v_slug := v_slug || '-' || substr(gen_random_uuid()::text, 1, 4);
  end if;

  select coalesce(max(sort), 0) + 1 into v_sort
    from sections where menu_slug = v_menu and parent_id is not distinct from p_parent_id;

  insert into sections (menu_slug, parent_id, slug, name, description, layout, sort)
  values (v_menu, p_parent_id, v_slug, v_name, '', 'list', v_sort)
  returning id into v_id;
  return v_id;
end
$$;

-- ── Borrar una sección vacía ──
create or replace function public.staff_delete_section(p_code text, p_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  if exists (select 1 from products where section_id = p_id) then
    raise exception 'Esa sección todavía tiene platos: muévelos o escóndelos primero';
  end if;
  if exists (select 1 from sections where parent_id = p_id) then
    raise exception 'Esa sección todavía tiene subsecciones';
  end if;
  delete from sections where id = p_id;
end
$$;

-- ── Reordenar: mover un plato o una sección arriba/abajo ──
create or replace function public.staff_move_product(p_code text, p_id uuid, p_dir int)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_section uuid;
  v_ids uuid[];
  v_idx int;
  v_tgt int;
  v_tmp uuid;
  i int;
begin
  perform assert_staff(p_code);
  select section_id into v_section from products where id = p_id;
  if v_section is null then return; end if;

  select array_agg(id order by sort, name) into v_ids from products where section_id = v_section;
  v_idx := array_position(v_ids, p_id);
  v_tgt := v_idx + case when p_dir < 0 then -1 else 1 end;
  if v_idx is null or v_tgt < 1 or v_tgt > array_length(v_ids, 1) then return; end if;

  v_tmp := v_ids[v_idx]; v_ids[v_idx] := v_ids[v_tgt]; v_ids[v_tgt] := v_tmp;
  for i in 1 .. array_length(v_ids, 1) loop
    update products set sort = i where id = v_ids[i];
  end loop;
end
$$;

create or replace function public.staff_move_section(p_code text, p_id uuid, p_dir int)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_menu text;
  v_parent uuid;
  v_ids uuid[];
  v_idx int;
  v_tgt int;
  v_tmp uuid;
  i int;
begin
  perform assert_staff(p_code);
  select menu_slug, parent_id into v_menu, v_parent from sections where id = p_id;
  if v_menu is null then return; end if;

  select array_agg(id order by sort, name) into v_ids
    from sections where menu_slug = v_menu and parent_id is not distinct from v_parent;
  v_idx := array_position(v_ids, p_id);
  v_tgt := v_idx + case when p_dir < 0 then -1 else 1 end;
  if v_idx is null or v_tgt < 1 or v_tgt > array_length(v_ids, 1) then return; end if;

  v_tmp := v_ids[v_idx]; v_ids[v_idx] := v_ids[v_tgt]; v_ids[v_tgt] := v_tmp;
  for i in 1 .. array_length(v_ids, 1) loop
    update sections set sort = i where id = v_ids[i];
  end loop;
end
$$;

grant execute on function public.staff_create_product(text, uuid, jsonb) to anon, authenticated;
grant execute on function public.staff_create_section(text, text, uuid, text) to anon, authenticated;
grant execute on function public.staff_delete_section(text, uuid) to anon, authenticated;
grant execute on function public.staff_move_product(text, uuid, int) to anon, authenticated;
grant execute on function public.staff_move_section(text, uuid, int) to anon, authenticated;

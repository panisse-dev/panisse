-- ══════════════════════════════════════════════════════════════════
-- Arreglo: los identificadores de secciones y platos son texto (vienen
-- de la plataforma anterior, estilo "RMKG3sVjZQ0VBvNBr9mS"), no uuid.
-- Las funciones de crear/mover se habían escrito con uuid y fallaban.
-- Aquí se rehacen con texto y se genera el id en el mismo formato.
-- ══════════════════════════════════════════════════════════════════

drop function if exists public.staff_create_product(text, uuid, jsonb);
drop function if exists public.staff_create_section(text, text, uuid, text);
drop function if exists public.staff_delete_section(text, uuid);
drop function if exists public.staff_move_product(text, uuid, int);
drop function if exists public.staff_move_section(text, uuid, int);

-- Id corto y aleatorio, en el mismo estilo que los que ya existen.
create or replace function public.new_short_id()
returns text
language sql
volatile
as $$
  select string_agg(
    substr('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
           1 + floor(random() * 62)::int, 1), '')
  from generate_series(1, 20);
$$;

-- ── Crear un plato dentro de una sección ──
create or replace function public.staff_create_product(p_code text, p_section_id text, p jsonb)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_name text := left(btrim(coalesce(p->>'name','')), 120);
  v_id text := new_short_id();
  v_sort int;
begin
  perform assert_staff(p_code);
  if v_name = '' then raise exception 'Escribe el nombre del plato'; end if;
  if not exists (select 1 from sections where id = p_section_id) then
    raise exception 'Esa sección no existe';
  end if;

  select coalesce(max(sort), 0) + 1 into v_sort from products where section_id = p_section_id;

  insert into products (id, section_id, name, description, prices, hide_price, image,
                        is_new, veg, visible, sort)
  values (
    v_id, p_section_id, v_name,
    left(btrim(coalesce(p->>'description','')), 600),
    coalesce(p->'prices', '[]'::jsonb),
    coalesce((p->>'hidePrice')::boolean, false),
    nullif(btrim(coalesce(p->>'image','')), ''),
    coalesce((p->>'isNew')::boolean, false),
    coalesce((p->>'veg')::boolean, false),
    coalesce((p->>'visible')::boolean, true),
    v_sort
  );
  return v_id;
end
$$;

-- ── Crear una sección (o subsección, si viene p_parent_id) ──
create or replace function public.staff_create_section(
  p_code text, p_menu_slug text, p_parent_id text, p_name text)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_name text := left(btrim(coalesce(p_name,'')), 80);
  v_parent text := nullif(btrim(coalesce(p_parent_id,'')), '');
  v_slug text;
  v_id text := new_short_id();
  v_sort int;
  v_menu text := p_menu_slug;
begin
  perform assert_staff(p_code);
  if v_name = '' then raise exception 'Escribe el nombre de la sección'; end if;

  if v_parent is not null then
    select menu_slug into v_menu from sections where id = v_parent;
    if v_menu is null then raise exception 'Esa sección no existe'; end if;
  end if;
  if not exists (select 1 from menus where slug = v_menu) then
    raise exception 'Esa carta no existe';
  end if;

  v_slug := regexp_replace(lower(translate(v_name,
              'áéíóúàèìòùäëïöüâêîôûñÁÉÍÓÚÑ', 'aeiouaeiouaeiouaeioun aeioun')),
            '[^a-z0-9]+', '-', 'g');
  v_slug := trim(both '-' from v_slug);
  if v_slug = '' then v_slug := 'seccion'; end if;
  if exists (select 1 from sections where menu_slug = v_menu and slug = v_slug) then
    v_slug := v_slug || '-' || substr(new_short_id(), 1, 4);
  end if;

  select coalesce(max(sort), 0) + 1 into v_sort
    from sections where menu_slug = v_menu and parent_id is not distinct from v_parent;

  insert into sections (id, menu_slug, parent_id, slug, name, description, layout, sort)
  values (v_id, v_menu, v_parent, v_slug, v_name, '', 'list', v_sort);
  return v_id;
end
$$;

-- ── Borrar una sección vacía ──
create or replace function public.staff_delete_section(p_code text, p_id text)
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

-- ── Reordenar ──
create or replace function public.staff_move_product(p_code text, p_id text, p_dir int)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_section text;
  v_ids text[];
  v_idx int;
  v_tgt int;
  v_tmp text;
  i int;
begin
  perform assert_staff(p_code);
  select section_id into v_section from products where id = p_id;
  if v_section is null then return; end if;

  select array_agg(id order by sort, name) into v_ids from products where section_id = v_section;
  v_idx := array_position(v_ids, p_id);
  if v_idx is null then return; end if;
  v_tgt := v_idx + case when p_dir < 0 then -1 else 1 end;
  if v_tgt < 1 or v_tgt > array_length(v_ids, 1) then return; end if;

  v_tmp := v_ids[v_idx]; v_ids[v_idx] := v_ids[v_tgt]; v_ids[v_tgt] := v_tmp;
  for i in 1 .. array_length(v_ids, 1) loop
    update products set sort = i where id = v_ids[i];
  end loop;
end
$$;

create or replace function public.staff_move_section(p_code text, p_id text, p_dir int)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_menu text;
  v_parent text;
  v_ids text[];
  v_idx int;
  v_tgt int;
  v_tmp text;
  i int;
begin
  perform assert_staff(p_code);
  select menu_slug, parent_id into v_menu, v_parent from sections where id = p_id;
  if v_menu is null then return; end if;

  select array_agg(id order by sort, name) into v_ids
    from sections where menu_slug = v_menu and parent_id is not distinct from v_parent;
  v_idx := array_position(v_ids, p_id);
  if v_idx is null then return; end if;
  v_tgt := v_idx + case when p_dir < 0 then -1 else 1 end;
  if v_tgt < 1 or v_tgt > array_length(v_ids, 1) then return; end if;

  v_tmp := v_ids[v_idx]; v_ids[v_idx] := v_ids[v_tgt]; v_ids[v_tgt] := v_tmp;
  for i in 1 .. array_length(v_ids, 1) loop
    update sections set sort = i where id = v_ids[i];
  end loop;
end
$$;

grant execute on function public.staff_create_product(text, text, jsonb) to anon, authenticated;
grant execute on function public.staff_create_section(text, text, text, text) to anon, authenticated;
grant execute on function public.staff_delete_section(text, text) to anon, authenticated;
grant execute on function public.staff_move_product(text, text, int) to anon, authenticated;
grant execute on function public.staff_move_section(text, text, int) to anon, authenticated;

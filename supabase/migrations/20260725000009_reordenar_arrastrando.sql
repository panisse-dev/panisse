-- ══════════════════════════════════════════════════════════════════
-- Reordenar arrastrando: en vez de subir/bajar de a uno, el panel manda
-- el orden completo de la lista tal como quedó después de soltar.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_reorder_products(
  p_code text, p_section_id text, p_ids text[])
returns void
language plpgsql
security definer set search_path = public
as $$
declare i int;
begin
  perform assert_staff(p_code);
  for i in 1 .. coalesce(array_length(p_ids, 1), 0) loop
    update products set sort = i where id = p_ids[i] and section_id = p_section_id;
  end loop;
end
$$;

create or replace function public.staff_reorder_sections(
  p_code text, p_menu_slug text, p_parent_id text, p_ids text[])
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  i int;
  v_parent text := nullif(btrim(coalesce(p_parent_id, '')), '');
begin
  perform assert_staff(p_code);
  for i in 1 .. coalesce(array_length(p_ids, 1), 0) loop
    update sections set sort = i
     where id = p_ids[i]
       and menu_slug = p_menu_slug
       and parent_id is not distinct from v_parent;
  end loop;
end
$$;

grant execute on function public.staff_reorder_products(text, text, text[]) to anon, authenticated;
grant execute on function public.staff_reorder_sections(text, text, text, text[]) to anon, authenticated;

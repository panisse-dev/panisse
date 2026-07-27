-- ══════════════════════════════════════════════════════════════════
-- Mover un plato a otra sección (o a otra carta) desde el panel.
--
-- Antes solo se podía crear, editar, ocultar y reordenar dentro de su
-- sección: para pasar un plato de "Favoritos" a "Tradicionales" tocaba
-- borrarlo y volverlo a crear, perdiendo su historial de pedidos.
-- El plato conserva su identidad, así que la analítica no se rompe.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_move_product_to_section(
  p_code text, p_id text, p_section_id text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_sort int;
begin
  perform assert_staff(p_code);
  if not exists (select 1 from products where id = p_id) then
    raise exception 'Ese plato no existe';
  end if;
  if not exists (select 1 from sections where id = p_section_id) then
    raise exception 'Esa sección no existe';
  end if;

  -- Entra de último en la sección nueva; después se reordena arrastrando.
  select coalesce(max(sort), 0) + 1 into v_sort from products where section_id = p_section_id;
  update products set section_id = p_section_id, sort = v_sort where id = p_id;
end
$$;

grant execute on function public.staff_move_product_to_section(text, text, text) to anon, authenticated;

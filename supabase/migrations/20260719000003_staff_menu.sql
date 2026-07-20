-- Árbol completo del menú para el panel de administración
-- (incluye productos ocultos y su bandera visible).
create or replace function public.staff_menu_tree(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'slug', m.slug,
      'label', m.label,
      'name', m.name,
      'sections', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', s.id,
          'name', s.name,
          'description', s.description,
          'layout', s.layout,
          'products', staff_products_json(s.id),
          'subsections', coalesce((
            select jsonb_agg(jsonb_build_object(
              'id', ss.id,
              'name', ss.name,
              'description', ss.description,
              'layout', ss.layout,
              'products', staff_products_json(ss.id)
            ) order by ss.sort)
            from sections ss where ss.parent_id = s.id
          ), '[]'::jsonb)
        ) order by s.sort)
        from sections s where s.menu_slug = m.slug and s.parent_id is null
      ), '[]'::jsonb)
    ) order by m.sort)
    from menus m
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_products_json(p_section_id text)
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', p.id,
    'name', p.name,
    'description', p.description,
    'prices', p.prices,
    'hidePrice', p.hide_price,
    'image', p.image,
    'isNew', p.is_new,
    'veg', p.veg,
    'visible', p.visible,
    'order', p.sort
  ) order by p.sort), '[]'::jsonb)
  from products p
  where p.section_id = p_section_id
$$;

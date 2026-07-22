-- ══════════════════════════════════════════════════════════════════
-- Títulos y frases de los menús, en vivo para el cliente
--
-- El panel guarda los títulos/frases de cada carta en la tabla `menus`,
-- pero la portada del cliente los tomaba del código (estáticos), así que
-- los cambios no se veían. Esta función pública deja que la portada los
-- lea de la base y se actualicen al instante, sin volver a publicar.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.public_menu_titles()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'slug', m.slug, 'label', m.label, 'tagline', m.tagline, 'name', m.name
  ) order by m.sort), '[]'::jsonb)
  from menus m;
$$;

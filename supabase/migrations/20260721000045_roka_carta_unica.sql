-- ROKA queda como UNA sola carta. Las bebidas/vinos de Roka (que estaban en
-- una carta aparte "roka-bebidas") pasan a ser secciones dentro de "roka-carta",
-- después de la comida. Así, al tocar ROKA en Pilares, se abre la carta completa
-- de una, con los vinos incluidos, sin una segunda pantalla de selección.

-- 1) Las secciones grandes de bebidas van al final de la Carta Roka.
--    (sort +10 para quedar después de la comida, que va de 0 a 5.)
update public.sections
set menu_slug = 'roka-carta', sort = sort + 10
where menu_slug = 'roka-bebidas' and parent_id is null;

-- 2) Las subsecciones de bebidas siguen a sus padres (conservan su orden).
update public.sections
set menu_slug = 'roka-carta'
where menu_slug = 'roka-bebidas';

-- 3) La carta de bebidas Roka ya no existe como carta separada.
delete from public.menus where slug = 'roka-bebidas';

-- Marca de cada carta: 'panisse' o 'roka'. En Pilares conviven las dos y el
-- cliente elige primero la marca; cada carta se pinta con su propio estilo.
-- (La portada usa menu.json; esto deja la marca también en la base para el
-- futuro, p.ej. dividir el pedido por marca en la cocina.)
alter table public.menus add column if not exists brand text not null default 'panisse';
update public.menus set brand = 'roka' where slug like 'roka%';

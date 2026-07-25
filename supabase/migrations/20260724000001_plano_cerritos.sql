-- ══════════════════════════════════════════════════════════════════
-- Plano de Cerritos: 2 zonas tal como en Precompro.
--   RESTAURANTE (13 mesas, 42 puestos), VIP (5 mesas, 20 puestos) = 62.
-- Reemplaza el plano de prueba de Cerritos (Salón / Terraza).
-- Las reservas se conservan; solo se les quita la mesa vieja asignada.
-- ══════════════════════════════════════════════════════════════════

-- Desvincular reservas de las mesas viejas de Cerritos
update public.reservations set table_id = null where table_id in (
  select id from public.restaurant_tables where location_id = 'cerritos');
delete from public.reservation_tables where table_id in (
  select id from public.restaurant_tables where location_id = 'cerritos');

-- Borrar plano anterior de Cerritos
delete from public.restaurant_tables where location_id = 'cerritos';
delete from public.zones where location_id = 'cerritos';

-- ── Zona RESTAURANTE (13 mesas, 42 puestos) ──
insert into public.zones (location_id, name, sort) values ('cerritos', 'RESTAURANTE', 0);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M7', 2, 'rect', 76, 60, 20, 20, 0, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M6', 4, 'rect', 92, 62, 124, 20, 1, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M5', 4, 'rect', 92, 62, 243, 22, 2, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M4', 2, 'rect', 76, 60, 344, 23, 3, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M3', 4, 'rect', 92, 62, 447, 23, 4, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M2', 2, 'rect', 76, 60, 551, 25, 5, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M1', 4, 'rect', 92, 62, 657, 25, 6, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M10', 2, 'rect', 76, 60, 310, 140, 7, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M11', 3, 'rect', 84, 60, 404, 138, 8, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M12', 6, 'rect', 112, 70, 519, 137, 9, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M13', 2, 'rect', 76, 60, 653, 135, 10, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M9', 4, 'rect', 92, 62, 183, 229, 11, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='RESTAURANTE'), 'cerritos', 'M8', 3, 'rect', 84, 60, 268, 313, 12, true);

-- ── Zona VIP (5 mesas redondas, 20 puestos) ──
insert into public.zones (location_id, name, sort) values ('cerritos', 'VIP', 1);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='VIP'), 'cerritos', 'VIP2', 4, 'round', 76, 76, 21, 20, 0, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='VIP'), 'cerritos', 'VIP3', 4, 'round', 76, 76, 217, 20, 1, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='VIP'), 'cerritos', 'VIP4', 4, 'round', 76, 76, 118, 121, 2, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='VIP'), 'cerritos', 'VIP1', 4, 'round', 76, 76, 20, 227, 3, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='cerritos' and name='VIP'), 'cerritos', 'VIP5', 4, 'round', 76, 76, 212, 224, 4, true);

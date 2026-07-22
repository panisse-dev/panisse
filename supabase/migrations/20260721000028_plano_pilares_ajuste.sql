-- ══════════════════════════════════════════════════════════════════
-- Plano de Pilares del Bosque: 3 salones tal como en Precompro.
--   ROKA II (63 puestos), ROKA I (56), TOSCANA=Panisse (28) = 147.
-- Reemplaza el plano anterior de Pilares (zonas y mesas de prueba).
-- Las reservas se conservan; solo se les quita la mesa vieja asignada.
-- ══════════════════════════════════════════════════════════════════

-- Desvincular reservas de las mesas viejas de Pilares
update public.reservations set table_id = null where table_id in (
  select id from public.restaurant_tables where location_id = 'pilares');
delete from public.reservation_tables where table_id in (
  select id from public.restaurant_tables where location_id = 'pilares');

-- Borrar plano anterior de Pilares
delete from public.restaurant_tables where location_id = 'pilares';
delete from public.zones where location_id = 'pilares';

-- ── Salón ROKA II (17 mesas, 63 puestos) ──
insert into public.zones (location_id, name, sort) values ('pilares', 'ROKA II', 0);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', 'B1', 1, 'round', 54, 54, 20, 20, 0, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', 'B2', 1, 'round', 54, 54, 20, 88, 1, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', 'B3', 1, 'round', 54, 54, 20, 156, 2, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', 'B4', 1, 'round', 54, 54, 20, 224, 3, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', 'B5', 1, 'round', 54, 54, 20, 292, 4, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', 'B6', 1, 'round', 54, 54, 20, 360, 5, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', 'B7', 1, 'round', 54, 54, 20, 428, 6, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '25', 6, 'rect', 112, 70, 140, 20, 7, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '24', 5, 'rect', 104, 66, 140, 110, 8, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '23', 5, 'rect', 104, 66, 140, 200, 9, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '22', 6, 'rect', 112, 70, 140, 320, 10, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '21', 6, 'rect', 112, 70, 140, 410, 11, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '27', 8, 'rect', 132, 82, 430, 20, 12, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '28', 4, 'rect', 92, 62, 440, 122, 13, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '29', 4, 'rect', 92, 62, 440, 204, 14, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '20', 6, 'rect', 112, 70, 290, 410, 15, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA II'), 'pilares', '20A', 6, 'rect', 112, 70, 420, 410, 16, true);

-- ── Salón ROKA I (11 mesas, 56 puestos) ──
insert into public.zones (location_id, name, sort) values ('pilares', 'ROKA I', 1);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '15', 4, 'rect', 92, 62, 30, 120, 0, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '14', 4, 'rect', 92, 62, 30, 225, 1, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '13', 4, 'rect', 92, 62, 30, 330, 2, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '12', 4, 'rect', 92, 62, 30, 435, 3, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', 'VIP', 12, 'rect', 168, 88, 235, 20, 4, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '11', 6, 'rect', 112, 70, 225, 435, 5, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '10', 6, 'rect', 112, 70, 350, 435, 6, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '16', 4, 'rect', 92, 62, 490, 120, 7, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '17', 4, 'rect', 92, 62, 490, 225, 8, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '18', 4, 'rect', 92, 62, 490, 330, 9, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='ROKA I'), 'pilares', '19', 4, 'rect', 92, 62, 490, 435, 10, true);

-- ── Salón TOSCANA (7 mesas, 28 puestos) ──
insert into public.zones (location_id, name, sort) values ('pilares', 'TOSCANA', 2);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='TOSCANA'), 'pilares', '5', 4, 'round', 92, 62, 20, 20, 0, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='TOSCANA'), 'pilares', '4', 4, 'rect', 92, 62, 190, 20, 1, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='TOSCANA'), 'pilares', '1', 4, 'rect', 92, 62, 360, 20, 2, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='TOSCANA'), 'pilares', '6', 4, 'rect', 92, 62, 20, 170, 3, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='TOSCANA'), 'pilares', '7', 4, 'rect', 92, 62, 190, 170, 4, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='TOSCANA'), 'pilares', '2', 4, 'rect', 92, 62, 360, 170, 5, true);
insert into public.restaurant_tables (zone_id, location_id, name, seats, shape, width, height, pos_x, pos_y, sort, active)
values ((select id from public.zones where location_id='pilares' and name='TOSCANA'), 'pilares', '3', 4, 'rect', 92, 62, 360, 320, 6, true);


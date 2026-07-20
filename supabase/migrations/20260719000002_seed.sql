-- Datos iniciales generados desde web/src/data/menu.json
-- (node scripts/gen-supabase-seed.mjs)

insert into public.restaurant_info (name, logo, instagram, whatsapp, address, city, currency)
values ('PANISSE', '/images/restaurant/77690b74-5642-40b9-b93f-616216c8a646.webp', 'panisse.pei', '+573128179235', 'Mall Pilares del Bosque, Local 2', 'Pereira', 'COP');

-- ── Menú BRUNCH ──
insert into public.menus (slug, label, tagline, name, sort)
values ('brunch', 'Brunch', 'Desayunos y antojos de la mañana', 'BRUNCH', 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('3SuC0dDELsgQO36t5nox', 'brunch', null, 'desayunos-especiales', 'DESAYUNOS ESPECIALES', '', null, 'cards', 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('RMKG3sVjZQ0VBvNBr9mS', 'brunch', '3SuC0dDELsgQO36t5nox', 'tostadas', 'TOSTADAS', 'Base de pan de hogaza.', null, 'cards', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('UPwRyo0qqfiWqT5rdr8T', 'RMKG3sVjZQ0VBvNBr9mS', 'CAPRESE', 'Tostada de focaccia, queso crema de pesto, Mozzarella de búfala, tomate Cherry confitado, rúgula y Grana Padano.', '[{"label":"","price":29900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('0v0WiqFjiwthzuD17HqM', 'RMKG3sVjZQ0VBvNBr9mS', 'PROSCIUTTO E MOZZARELLA DI BUFALA', 'Focaccia de la casa, prosciutto, queso crema de pesto, mozzarella de búfala, tomate Cherry confitado, rúgula y Grana Padano.', '[{"label":"","price":38900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('vx7CXYfQmQNnU1FXLv4L', 'RMKG3sVjZQ0VBvNBr9mS', 'TRUFADA', 'Pan Italiano, huevos cremados en Grana Padano, queso crema trufado y toques de cebollín.', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('khYijxRprwxYAfGfUZix', 'brunch', '3SuC0dDELsgQO36t5nox', 'panini', 'PANINI', '', null, 'cards', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('A6MalQK1kyVnFJag5lM8', 'khYijxRprwxYAfGfUZix', 'ITALIANISSIMO', 'Pan de la casa, Salami, pepperoni, mortadela italiana, queso crema de pesto, tomate fresco y rúgula.', '[{"label":"","price":28900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('6tvZHJoJeRFN1rIVrScU', 'khYijxRprwxYAfGfUZix', 'MILANESA DE LA CASA', 'Pan de la casa, Milanesa de pollo, aderezo césar, tomate fresco y rúgula.', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('vfDWMhNR2ovddCdpkBZe', 'brunch', '3SuC0dDELsgQO36t5nox', 'especiales-de-la-casa', 'ESPECIALES DE LA CASA', '', null, 'cards', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Bmj4wvp6Xo506OCckXpx', 'vfDWMhNR2ovddCdpkBZe', 'FRITTATA DE PAPA', 'Tortilla Italiana con huevos, tocineta, cebollas y papas fritas en aceite de oliva.', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('oXXrJ4tfbPmqDAh2dnxu', 'vfDWMhNR2ovddCdpkBZe', 'HUEVOS A LA FLORENTINA', 'huevos, prosciutto, salsa holandesa, mezcla de espinacas escalfadas con stracciatella sobre pan brioche.', '[{"label":"","price":28900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('ezT7gaEdcfrITJwOTNo2', 'vfDWMhNR2ovddCdpkBZe', 'PROSCIUTTO CROISSANT', 'Croissant artesanal, prosciutto, huevos cremados en grana padano y toques de cebollín.', '[{"label":"","price":28900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('vBjBcQt9xWGyUW0i4RsS', 'brunch', '3SuC0dDELsgQO36t5nox', 'french-omelette', 'FRENCH OMELETTE', 'Omelette al mejor estilo francés.', null, 'cards', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('VfR7aDyIExXNw7UyXR0t', 'vBjBcQt9xWGyUW0i4RsS', 'CON TOCINETA', 'Omelette con tocineta y Mini waffles.', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('TbXnX4Hv585BPUFkQtDf', 'vBjBcQt9xWGyUW0i4RsS', 'FITNESS OMELETTE', 'Omelette de claras con espinacas, aguacate, acompañado con ensalada fresca y mini waffles funcionales.', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('ziRyc0q206yDZDKxWZXQ', 'brunch', null, 'desayunos-clasicos', 'DESAYUNOS CLÁSICOS', '', null, 'cards', 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('woQ9ngT4TOIEomwCwNGS', 'brunch', 'ziRyc0q206yDZDKxWZXQ', 'desayuno-toscana', 'DESAYUNO TOSCANA', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('6Bg3dW3NwjTVR82s6mff', 'woQ9ngT4TOIEomwCwNGS', 'DESAYUNO TOSCANA', 'TIPO DE HUEVO: Cacerola- Pericos- Revueltos. ACOMPAÑANTE: Arepa o Pan artesanal de masa madre. BEBIDA CALIENTE: Latte, Chocolate o Café. PANADERIA: Pandeyuca o Pandebono.', '[{"label":"Desayuno Toscana","price":22900,"discounted":null},{"label":"Con huevos rancheros","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('9Qx3pnQdoCucYJkXAyfP', 'brunch', 'ziRyc0q206yDZDKxWZXQ', 'tradicionales', 'TRADICIONALES', '', null, 'cards', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('vz6wy3qtlTDBrDdvKB4x', '9Qx3pnQdoCucYJkXAyfP', 'CALENTADO', 'Clásica preparación de arroz y fríjoles acompañado con arepa de maíz y proteína a elección.', '[{"label":"Huevos al gusto","price":22000,"discounted":null},{"label":"Carne de res","price":28000,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('UloyGFeThOxDx880Y36Q', '9Qx3pnQdoCucYJkXAyfP', 'CALDO DE COSTILLA', 'Tradicional caldo de costilla de res.', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('yt1KjNP8YdY3aFCnrLgP', 'brunch', 'ziRyc0q206yDZDKxWZXQ', 'favoritos', 'FAVORITOS', '', null, 'cards', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('sMYoA2luBvkD6zsN3Tjp', 'yt1KjNP8YdY3aFCnrLgP', 'BOWL DE GRANOLA', 'Yogurt griego, granola y frutas de temporada.', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('5O4UIv1cxQE9n9zx4udF', 'yt1KjNP8YdY3aFCnrLgP', 'BOWL DE FRUTA', 'Frutas de temporada.', '[{"label":"","price":18900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('1OuID87KZ9I9IQMEujmz', 'yt1KjNP8YdY3aFCnrLgP', 'WAFFLES', 'CLÁSICO: Mantequilla y miel de maple. NUTELLA: Fresa y Chantilly.', '[{"label":"CLÁSICO","price":14900,"discounted":null},{"label":"NUTELLA","price":20900,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('LqUyo3FbucqwYoYLqjva', 'yt1KjNP8YdY3aFCnrLgP', 'TOSTADA FRANCESA', 'Pan brioche humedecido en tres leches, chantilly y fresas.', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, '/images/products/76e01e84-8ccc-480c-b3c0-c18607b326c3.webp', false, false, 8);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('iMW8nkCzz6BcNEWJHfSo', 'brunch', null, 'bebidas', 'BEBIDAS', 'CAFFÉ PANISSE', null, 'list', 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('aLvsNc6LPmvVWvpTPCSN', 'brunch', 'iMW8nkCzz6BcNEWJHfSo', 'capuccino-latte', 'CAPUCCINO/LATTE', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('yLCi6w58sZ1g463K67hA', 'aLvsNc6LPmvVWvpTPCSN', 'TRADICIONAL', '', '[{"label":"","price":7900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('cU5oVQ0e5hzYukOp5izE', 'aLvsNc6LPmvVWvpTPCSN', 'VAINILLA', '', '[{"label":"","price":10000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('fGwX4z9CO8OqUnHKefhG', 'aLvsNc6LPmvVWvpTPCSN', 'CARAMELO', '', '[{"label":"","price":10000,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('spSgQMbBApwlOdjy87El', 'aLvsNc6LPmvVWvpTPCSN', 'MOCACCINO', '', '[{"label":"Sin Licor","price":10000,"discounted":null},{"label":"Con Licor","price":16000,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('pthTTlp9Ly1MELRURuEa', 'brunch', 'iMW8nkCzz6BcNEWJHfSo', 'espresso', 'ESPRESSO', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('U6TDjlKT6E4lv6noI49h', 'pthTTlp9Ly1MELRURuEa', 'ESPRESSO', '', '[{"label":"","price":5500,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('9UiGL7fW5QvCfzJ0CQtB', 'pthTTlp9Ly1MELRURuEa', 'AMERICANO', '', '[{"label":"","price":6000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('U6Sgblv8t5tOdy7ZNaoD', 'pthTTlp9Ly1MELRURuEa', 'MACCHIATO', '', '[{"label":"","price":7000,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('VEyozh8C7nlDFNaHSflZ', 'brunch', 'iMW8nkCzz6BcNEWJHfSo', 'preparaciones-con-cafe-frias', 'PREPARACIONES CON CAFÉ FRÍAS', '', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('pdZZkMpDPKEr3IDY8o34', 'VEyozh8C7nlDFNaHSflZ', 'AMERICANO ICE', '', '[{"label":"","price":7000,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('qvEmNon194qfNDq8MfDK', 'VEyozh8C7nlDFNaHSflZ', 'LATTE', '', '[{"label":"Clasico","price":9900,"discounted":null},{"label":"Vainilla","price":12900,"discounted":null},{"label":"Caramelo","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('JuUlz5hyzbNSIw4P9JBK', 'VEyozh8C7nlDFNaHSflZ', 'FROZEN', '', '[{"label":"Cappuccino","price":15000,"discounted":null},{"label":"Caramelo","price":15900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('axnDPjsEGtRrSfyAZbVw', 'brunch', 'iMW8nkCzz6BcNEWJHfSo', 'bebidas-calientes', 'BEBIDAS CALIENTES', '', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('vuZAFJST7PiYIHKytRP7', 'axnDPjsEGtRrSfyAZbVw', 'MILO', '', '[{"label":"","price":8500,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('5wmWPUqmwJfiP3vQ7zIV', 'axnDPjsEGtRrSfyAZbVw', 'TÉ CHAI', '', '[{"label":"","price":9900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('paCO2Fj6iXHr295Ip9Ge', 'axnDPjsEGtRrSfyAZbVw', 'TÉ MATCHA', '', '[{"label":"","price":10900,"discounted":null}]'::jsonb, false, null, false, false, 1.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('PCl6X0gTeIGjow7Nx7tc', 'axnDPjsEGtRrSfyAZbVw', 'CHOCOLATE', '', '[{"label":"En Agua","price":6900,"discounted":null},{"label":"En Leche","price":7900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('qPfv2sYXESclx4NScJxF', 'axnDPjsEGtRrSfyAZbVw', 'INFUSIONES (A ELECCION)', '', '[{"label":"","price":6500,"discounted":null}]'::jsonb, false, null, false, false, 3.5);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('P5V2BRpVzwqjRrlGZwD8', 'brunch', 'iMW8nkCzz6BcNEWJHfSo', 'bebidas-frias', 'BEBIDAS FRÍAS', '', null, 'list', 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Ztnw0EiqmEf8f4TSdP2j', 'P5V2BRpVzwqjRrlGZwD8', 'MILO FRAPPÉ', '', '[{"label":"","price":10500,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('aCF87o0Lw3rQU3J1CTNY', 'P5V2BRpVzwqjRrlGZwD8', 'TÉ CHAI FRAPPÉ', '', '[{"label":"","price":13900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('o5ejQG8lD6YjP2NVdMVx', 'P5V2BRpVzwqjRrlGZwD8', 'TÉ MATCHA FRAPPÉ', '', '[{"label":"","price":14900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('kxgru5jQpKi0Ah92YAfB', 'P5V2BRpVzwqjRrlGZwD8', 'AGUA MANANTIAL', '', '[{"label":"","price":7200,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('1skNDl9aXcrnZGkaxqx6', 'brunch', 'iMW8nkCzz6BcNEWJHfSo', 'smoothies-jugos', 'SMOOTHIES & JUGOS', '', null, 'list', 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('yj8VhUHt1Msdb56QAy5m', '1skNDl9aXcrnZGkaxqx6', 'JUGO DE MANDARINA', '', '[{"label":"","price":9900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('w4yCNhNeLBWlCfoSpy61', '1skNDl9aXcrnZGkaxqx6', 'SANDÍA LIMÓN', '', '[{"label":"","price":16900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('s74IRNyOUTWKslv3Xs60', '1skNDl9aXcrnZGkaxqx6', 'BATIDO VERDE FUNCIONAL', '', '[{"label":"","price":10900,"discounted":null}]'::jsonb, false, null, false, false, 2);

-- ── Menú LUNCH Y DINNER ──
insert into public.menus (slug, label, tagline, name, sort)
values ('lunch-y-dinner', 'Lunch y Dinner', 'Cocina italiana para almorzar y cenar', 'LUNCH Y DINNER', 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('RAa5FiKxYfUhUjYytVlM', 'lunch-y-dinner', null, 'entradas', 'ENTRADAS', '', null, 'cards', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('R5pvzlRWSxHs8Zp8heEX', 'RAa5FiKxYfUhUjYytVlM', 'ARANCINI TARTUFO E FUNGHI', 'croquetas de risotto trufado con centro de mozzarella.', '[{"label":"","price":34900,"discounted":null}]'::jsonb, false, null, false, true, -0.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('V6HnBiumvcJHHKMmzjs5', 'RAa5FiKxYfUhUjYytVlM', 'GAMBERI ALL''AGLIO', 'Camarones cremados con mantequilla de ajo, pimentón rostizado, perejil y ligeros toques de limón. Servidos con tostones de pan de masa madre', '[{"label":"","price":36900,"discounted":null}]'::jsonb, false, null, false, false, -0.25);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('hzEqFexNpV3EaconTf1T', 'RAa5FiKxYfUhUjYytVlM', 'CARPACCIO DE LOMO', 'Finas lonjas de solomito de res rebozado en pimienta molida, rúgula fresca, crocante de alcaparras, queso grana padano, reducción balsámica y aderezo cesar.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, '/images/products/7ae31559-8c53-4cf5-b5ef-bddfb47a3387.webp', false, false, -0.21875);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('rw4Hjs8XDaeffBzpaN9q', 'RAa5FiKxYfUhUjYytVlM', 'PAPAS TRUFADAS DELLA CASA', 'Papas fritas barnizadas con mantequilla de trufa, queso Grana Padano y cebollín.', '[{"label":"","price":39900,"discounted":null}]'::jsonb, false, '/images/products/620060dc-710e-4668-8d14-21925d292c61.webp', false, true, -0.1875);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('CTvjeokZPJQCu1dzx8Op', 'RAa5FiKxYfUhUjYytVlM', 'ALBÓNDIGAS ALLA TOSCANA', 'Albóndigas cremadas en Grana padano, queso azul, espinacas y pomodoro. servidas con pan de masa madre.', '[{"label":"","price":48900,"discounted":null}]'::jsonb, false, null, false, false, -0.0625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('5TCcWjEBYWp4bwvJ2I8c', 'RAa5FiKxYfUhUjYytVlM', 'PULPO DELLA CASA', 'Tentáculos de pulpo al fuego acompañado con tomates Cherry confitado y espárrago y papa artesanal.', '[{"label":"","price":64900,"discounted":null}]'::jsonb, false, '/images/products/54b28445-b461-4322-9f43-85c127f15b7c.webp', false, false, -0.015625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('4shRoI0iQIWlaNOd5DBI', 'RAa5FiKxYfUhUjYytVlM', 'BURRATA  PANISSE', 'Burrata de búfala, peras confitadas, queso azul, hierbabuena, crocante de pistacho y frutos secos.', '[{"label":"","price":49900,"discounted":null}]'::jsonb, false, '/images/products/e2a1103c-5ba6-4d86-bc3f-c99338e97595.webp', false, true, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('OQq7b4W6eqaUgA0PINRZ', 'RAa5FiKxYfUhUjYytVlM', 'DEDOS MOZZARELLA & TRUFA', 'Dedos mozzarella apanados acompañados con miel trufada.', '[{"label":"","price":27900,"discounted":null}]'::jsonb, false, null, false, true, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('iiqcWRAJ4wIuYCiIl2VU', 'lunch-y-dinner', null, 'sopas', 'SOPAS', 'Acompañados con pan artesanal de masa madre.', null, 'cards', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('2aMiArOgilSSrCLm8Tnb', 'iiqcWRAJ4wIuYCiIl2VU', 'MINESTRONE', 'Sopa clásica Italiana elaborada con vegetales de temporada.', '[{"label":"","price":18900,"discounted":null}]'::jsonb, false, null, false, true, -1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('ifDqMFpsgyjABoVUziWF', 'iiqcWRAJ4wIuYCiIl2VU', 'CREMA DI POMODORO', 'Crema artesanal de la casa a base de tomate San Marzano, con un toque ligero de parmesano.', '[{"label":"","price":20900,"discounted":null}]'::jsonb, false, null, false, true, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('lSdEdp8xeZ7I5lgBnzlm', 'iiqcWRAJ4wIuYCiIl2VU', 'ZUPPA DI PESCATORE', 'Sopa artesanal de la casa a base de tomate San Marzano y una fina selección de frutos del mar.', '[{"label":"","price":38900,"discounted":null}]'::jsonb, false, '/images/products/34a2199f-6fc9-42cb-b229-4127dbc038a4.webp', true, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('i90LEZ9iJLc1VYsy1qrO', 'lunch-y-dinner', null, 'ensaladas', 'ENSALADAS', '', null, 'cards', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Q7Zzdzg7FcQz6vz89f0g', 'i90LEZ9iJLc1VYsy1qrO', 'DELLA CASA', 'Cogollo europeo, filete de pechuga al fuego, peras caramelizadas, queso azul, reducción de durazno, crocante de pistachos y frutos secos.', '[{"label":"","price":46900,"discounted":null}]'::jsonb, false, null, false, false, -1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('NaU1N8FsGv1YmbZaTX57', 'i90LEZ9iJLc1VYsy1qrO', 'CÉSAR', 'Cogollo europeo, filete de pechuga al fuego, crotones de pan baguette, tocineta, queso grana Padano y aderezo césar de la casa.', '[{"label":"","price":45900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('P53pvjzVldAoWL52CSn0', 'i90LEZ9iJLc1VYsy1qrO', 'DE SOLOMITO', 'Cogollo europeo, solomo de res al fuego, tomate Cherry, champiñones, espárragos, Grana padano y aderezo de la casa.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('2B987OwlXOcKBI8sH5ML', 'i90LEZ9iJLc1VYsy1qrO', 'INSALATA DI SALMONE', 'Cogollo europeo, filete de salmón, duraznos asados, espárragos, champiñones, tomate Cherry, Grana padano y aderezo dulce de la casa.', '[{"label":"","price":64900,"discounted":null}]'::jsonb, false, '/images/products/9fa50c03-e649-45a7-b156-89da0eac91d5.webp', false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('1Dv5MikuDSPHAYPHS8gt', 'lunch-y-dinner', null, 'risottos-pastas', 'RISOTTOS & PASTAS', '', null, 'cards', 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('TuwhF3URRaX8Vs87rjSd', 'lunch-y-dinner', '1Dv5MikuDSPHAYPHS8gt', 'risottos', 'RISOTTOS', '', null, 'cards', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('FN4TuW6g7IZ8HbtTOfUq', 'TuwhF3URRaX8Vs87rjSd', 'QUESO AZUL & MANZANA', 'Espárragos, tomate Cherry confitado, champiñones y manzana verde cremados en salsa blanca de la casa y queso azul.', '[{"label":"","price":44900,"discounted":null}]'::jsonb, false, null, false, true, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Oxn6BZ4KFQ6scJsHQAEY', 'TuwhF3URRaX8Vs87rjSd', 'PESTO E GAMBERI', 'Risotto cremado en Grana padano y pesto de albahaca, finalizado con camarones sellados en mantequilla y ajo.', '[{"label":"","price":46900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('coV4uPRV8uEEJW1C6aTn', 'TuwhF3URRaX8Vs87rjSd', 'LOMO A LA PIMIENTA', 'Arroz arbóreo cremado con Grana padano, queso azul y parmesano, finalizado con cortes finos de solomito de res a la parrilla con toques ligeros de pimienta tostada.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, '/images/products/43c3776b-b257-4ad1-985b-497c52bbec49.webp', false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Rr5FbRpeXN4E4elxg3Z4', 'TuwhF3URRaX8Vs87rjSd', 'TARTUFO E FUNGHI', 'Risotto elaborado en mantequilla, Grana padano, laminas de champiñones y crema de trufa de la casa.', '[{"label":"","price":48900,"discounted":null}]'::jsonb, false, null, false, true, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('yEzeu5a24ugFUabL9ayS', 'TuwhF3URRaX8Vs87rjSd', 'MEDITERRÁNEO', 'Arroz arbóreo cremado con Grana padano, toques sutiles de salsa soya, champiñones y espárragos, finalizado con camarones sellados en aceite de oliva, pimienta y vino blanco.', '[{"label":"","price":50900,"discounted":null}]'::jsonb, false, '/images/products/a1bb6b44-bf9e-41e8-8187-c5de30fda6ba.webp', false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('3KzzE8Rw8ddn4M9YabiV', 'TuwhF3URRaX8Vs87rjSd', 'DI MARE', 'Risotto de la casa con selección especial de frutos del mar en salsa pomodoro San Marzano, cremado con Grana padano y pasta artesanal de pimentón rostizado.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, '/images/products/2cc8bec0-ebb7-4d80-b87e-6d919dde324a.webp', false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('T1QqNdL1zbeWZ2zEAdgC', 'TuwhF3URRaX8Vs87rjSd', 'CAPRESE & PROSCIUTTO', 'Risotto especial de la casa cremado en salsa pomodoro, Grana Padano y tomates secos, finalizado con toques sutiles de stracciatella y prosciutto PAESANO.', '[{"label":"","price":58900,"discounted":null}]'::jsonb, false, '/images/products/2fe02199-e9b4-47d8-b42b-eaf39f20201a.webp', true, false, 6);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('WLQHu6UbBjIlL94QODO1', 'lunch-y-dinner', '1Dv5MikuDSPHAYPHS8gt', 'pasta-tradizionale', 'PASTA TRADIZIONALE', '', null, 'cards', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('t1HY2eChcTjtu2sOhzlC', 'WLQHu6UbBjIlL94QODO1', 'BOLOGNESA', 'Res cocida a fuego lento en tradicional salsa italiana elaborada con tomate San Marzano y finalizada con queso Grana padano.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, -2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('bKIezI029lZ9tBtItuRp', 'WLQHu6UbBjIlL94QODO1', 'CARBONARA', 'Rigatoni en preparación clásica de queso Grana Padano, yemas y crema, finalizada con guanciale tostado.', '[{"label":"","price":44900,"discounted":null}]'::jsonb, false, '/images/products/8a2bd615-1061-43fe-9e4a-995076b664b9.webp', false, false, 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('K5sCHoSszBpVAViTrMiq', 'lunch-y-dinner', '1Dv5MikuDSPHAYPHS8gt', 'pasta-especiali', 'PASTA ESPECIALI', 'Pasta fettuccine acompañada de pan artesanal de masa madre.', null, 'cards', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('LA2MJ03CPlbTRfMupNmI', 'K5sCHoSszBpVAViTrMiq', 'HONGOS & TRUFA', 'Preparación especial de la casa cremada con trufa, champiñones, Grana padano y toques de pimienta negra.', '[{"label":"","price":44900,"discounted":null}]'::jsonb, false, '/images/products/1b371f67-fd90-4b98-b771-9730ee658d64.webp', false, true, 3.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('7aHNJIyTJopetVPriphn', 'K5sCHoSszBpVAViTrMiq', 'DELLA CASA', 'Camarones, champiñones y espárragos salteados en aceite de oliva y vino blanco, cremados en Grana padano y salsa blanca de la casa.', '[{"label":"","price":46900,"discounted":null}]'::jsonb, false, '/images/products/945efb53-cf01-41ad-b85b-ca537de16f5c.webp', false, false, 8);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('E7U4JlEsBnBZarBIIupV', 'K5sCHoSszBpVAViTrMiq', 'RIGATONI ALL''AMATRICIANA DI PEPPERONI', 'Pasta corta italiana, Rigatoni en salsa de tomate italiano confitado con un toque sutil de pepperoni y tocineta en su elaboración, finalizado con burrata de búfala.', '[{"label":"","price":54900,"discounted":null}]'::jsonb, false, '/images/products/128635bd-0f79-4326-b605-8558145953f5.webp', false, false, 10);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('5qzaC7PMj0uUpqY1KBBi', 'lunch-y-dinner', '1Dv5MikuDSPHAYPHS8gt', 'pasta-artigianale', 'PASTA ARTIGIANALE', 'Pasta artesanal hecha en casa acompañada con pan de masa madre.', null, 'cards', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('0R0x5k3HUWT5WdKLbun9', '5qzaC7PMj0uUpqY1KBBi', 'RAVIOLI TARTUFO E FUNGI', 'Pasta rellena de lomito de res, cremada en salsa trufada especial de la casa, finalizada con mozzarella y grana panado al horno.', '[{"label":"","price":48900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('fnGWil9BsYbujFnTTBdS', '5qzaC7PMj0uUpqY1KBBi', 'RAVIOLI RICOTTA & ESPINACA', 'Pasta rellena en salsa pomodoro San Marzano terminada con queso mozzarella y Grana padano al horno.', '[{"label":"","price":44900,"discounted":null}]'::jsonb, false, null, false, true, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('wAK5UuHuMlC7kQZfKtW1', '5qzaC7PMj0uUpqY1KBBi', 'RAVIOLI DI SALMONE', 'Pasta artesanal rellena de salmón, cremada a la Toscana con salsa pomodoro, espinacas, queso azul, y Grana padano, finalizada con camarones.', '[{"label":"","price":50900,"discounted":null}]'::jsonb, false, '/images/products/96448016-2595-47ef-8414-6d3988ce36a8.webp', false, false, 1.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('WPcSH23npXTdsN4L9ITQ', '5qzaC7PMj0uUpqY1KBBi', 'LASAGNA AL FORNO', 'Receta clásica con pasta fresca de la casa, base bechamel y ragú de lomito en salsa pomodoro, finalizada con mozzarella y Grana Padano al horno.', '[{"label":"","price":44900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('BO904lJmngJkSyq29pL2', 'lunch-y-dinner', '1Dv5MikuDSPHAYPHS8gt', 'pollos-pescados', 'POLLOS & PESCADOS', '', null, 'cards', 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('nxuKGWLx7UiKrErcXk3Y', 'BO904lJmngJkSyq29pL2', 'MILANESA ALLA PARMIGIANA', 'Corte fino de milanesa de pollo rebozado en parmesano al estilo italiano, acompañado con salsa pomodoro, ensalada cesar y papa de la casa.', '[{"label":"","price":44900,"discounted":null}]'::jsonb, false, '/images/products/df49ee4d-2888-49f8-beac-b74fb874a3ae.webp', false, false, -1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('0NMQnEOky52J7xJUCJWX', 'BO904lJmngJkSyq29pL2', 'SALMONE ALLA TOSCANA', 'Filete de salmón al fuego napado con pomodoro, espinacas, queso azul, Grana padano. Servido con papas de la casa.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, '/images/products/08d20a4e-9048-4cde-9a2d-e5f107a07a76.webp', false, false, -0.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('BriD74kLKp5YxuWOX6f9', 'BO904lJmngJkSyq29pL2', 'SALMÓN A LAS FINAS HIERBAS', 'Filete de salmón sellado en mantequilla de finas hierbas sobre mézclum de vegetales de temporada salteados en aceite de oliva.', '[{"label":"","price":56900,"discounted":null}]'::jsonb, false, '/images/products/4e663ac6-f2bb-4ffd-b56b-35e412503ccd.webp', false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('K5xOvVNqbnmYbo3XU35i', 'BO904lJmngJkSyq29pL2', 'SALMONE DELLA CASA', 'Filete de salmón sellado al fuego lento, servido con risotto cremado con mantequilla, preparación especial de pesto de la casa y Grana Padano.', '[{"label":"","price":64900,"discounted":null}]'::jsonb, false, '/images/products/63dcda32-5ffb-4273-9c05-ddc630ebb0d9.webp', false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('M0QDFdxER9dApC2i1Z8Z', 'lunch-y-dinner', '1Dv5MikuDSPHAYPHS8gt', 'cacerolas-panini', 'CACEROLAS & PANINI', '', null, 'cards', 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('3QlBxW0di8mNyUcf6D2a', 'M0QDFdxER9dApC2i1Z8Z', 'POLLO & SETAS', 'Pechuga de pollo en trozos cremada con salsa especial de la casa de champiñones, finalizado con mozzarella y Grana padano al horno.', '[{"label":"","price":36900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('5gvjIKpePSk9j8WlHG8b', 'M0QDFdxER9dApC2i1Z8Z', 'DI MARE', 'Selección especial de frutos del mar (Calamares, almejas y camarones) cremados con Grana Padano y láminas de champiñones, finalizados con mozzarella al horno.', '[{"label":"","price":45900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('lusDz1I2jjtWZ8O8bUvv', 'M0QDFdxER9dApC2i1Z8Z', 'DE SOLOMITO NAPOLITANO', 'Cortes finos de solomito napados con salsa pomodoro, tomates frescos y cebollas, finalizados con mozzarella y albahaca.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('Dm1ZNt2FniGfld7sA91R', 'lunch-y-dinner', '1Dv5MikuDSPHAYPHS8gt', 'panini-italiano', 'PANINI ITALIANO', 'Acompañados con papas Chips .', null, 'cards', 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('gBUfD4QldUb4LMPordHc', 'Dm1ZNt2FniGfld7sA91R', 'CAPRESE', 'Tomate fresco, tomate seco, mozzarella de búfala, rúgula, mayonesa pesto, pan artesal.', '[{"label":"","price":36900,"discounted":null}]'::jsonb, false, null, false, true, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('zfXBxPtqfsC0B2vH1R99', 'Dm1ZNt2FniGfld7sA91R', 'PROSCIUTTO & PESTO', 'Prosciutto, tomate fresco, rúgula, cebolla caramelizada, mayonesa pesto.', '[{"label":"","price":36900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Cf2YNFEaTS5rEcRtwblX', 'Dm1ZNt2FniGfld7sA91R', 'MILANESA DE POLLO', 'Milanesa de pollo, tomate fresco, queso crema, cogollo europeo, aderezo cesar.', '[{"label":"","price":34900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('mfnvMVGIBggloQRkHcF6', 'lunch-y-dinner', null, 'parrilla', 'PARRILLA', '', null, 'cards', 4);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('eGijHkKQu0jXlUMZ50gX', 'lunch-y-dinner', 'mfnvMVGIBggloQRkHcF6', 'cortes-tradicionales', 'CORTES TRADICIONALES', 'Acompañados con ensalada y papas de la casa.', null, 'cards', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('GM7wEYZ9BuJTTwhztLYj', 'eGijHkKQu0jXlUMZ50gX', 'PECHUGA DE LA CASA', 'filete de pechuga de pollo a la parilla.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('DWeGRwB8gGdLvHByIYG0', 'eGijHkKQu0jXlUMZ50gX', 'CHURRASCO', '400 gr de Filete de lomo ancho de res asado a la parrilla, caracterizado por su capa de grasa en los costados que potencia su sabor y presentación.', '[{"label":"","price":57900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('BVpys0AMGatlengyiVcC', 'eGijHkKQu0jXlUMZ50gX', 'PUNTA DE ANCA', '400 gr de corte del cuarto trasero de la res, con recubrimiento externo de grasa, de textura firme y jugosa.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('bnpWX34Is5PXm2L2hvlW', 'eGijHkKQu0jXlUMZ50gX', 'BABY BEEF', '400 gr de corte magro de solomito de res a la parrilla, de inigualable terneza.', '[{"label":"","price":60900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('FNwoIwcuTl2zEP3AZuR6', 'lunch-y-dinner', 'mfnvMVGIBggloQRkHcF6', 'cortes-certified-angus-beef', 'CORTES CERTIFIED ANGUS BEEF', 'Los cortes de la marca CERTIFIED ANGUS BEEF son de la mas alta calidad con excelente marmoleo y sabor. Acompañados con ensalada y papas de la casa.', null, 'cards', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('HBWAJw3mO7OWCwgSr5fR', 'FNwoIwcuTl2zEP3AZuR6', 'ASADO DE TIRA', 'Corte con mayor marmoleo, suave y jugoso seleccionado de la mejor parte de la costilla de res.', '[{"label":"","price":110900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('fKqcL4phBOba3k722uS1', 'FNwoIwcuTl2zEP3AZuR6', 'PICANHA', 'Perfecta punta de anca con terneza garantizada.', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('eGRO5QlSXZHOQwdUTvya', 'FNwoIwcuTl2zEP3AZuR6', 'NEW YORK', 'Lomo angosto con un poco de grasa subcutánea que ayuda a aumentar su sabor y jugosidad, terneza garantizada.', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('TD6OgqEuCQGAL7xZMqMB', 'lunch-y-dinner', null, 'pizzas', 'PIZZAS', 'Para nuestras masas utilizamos Harina Italiana y fermentamos durante 24 horas para asegurarnos de brindar una pizza de alta calidad y con inigualable sabor.', null, 'cards', 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('407QrV3DCzA2AfwQXRng', 'TD6OgqEuCQGAL7xZMqMB', 'PROSCIUTTO DI PARMA', 'Pomodoro, Mozzarella, Jamón de pierna, Rúgula y Oliva.', '[{"label":"","price":58900,"discounted":null}]'::jsonb, false, null, false, false, -2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('IpP6RlY35IlJSS0pW6a4', 'TD6OgqEuCQGAL7xZMqMB', 'MARGHERITA DI BUFALA', 'Pomodoro San Marzano, Mozzarella, Queso italiano Burrata, Albahaca fresca.', '[{"label":"","price":56900,"discounted":null}]'::jsonb, false, null, false, true, -1.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('TobXd8XmBGBzJ6Lh8hVH', 'TD6OgqEuCQGAL7xZMqMB', 'PESTO & STRACCIATELLA', 'Base pesto de Albahaca, Mozzarella, Stracciatella, Crocante de Pistachos.', '[{"label":"","price":46900,"discounted":null}]'::jsonb, false, '/images/products/7acd76d2-2789-4ad5-9eb7-b354c93dca18.webp', false, true, -1.25);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('gFQdcHN4lfujtNihkOy7', 'TD6OgqEuCQGAL7xZMqMB', 'TRUFA & STRACCIATELLA', 'Base de tartufo, Mozzarella, Champiñones, Stracciatella.', '[{"label":"","price":53900,"discounted":null}]'::jsonb, false, '/images/products/c7facc58-1235-4dd7-9c2b-50667a7b46ce.webp', false, true, -1.125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('pxnENV5q9pBJLzBz5lo1', 'TD6OgqEuCQGAL7xZMqMB', 'QUESO AZUL & MANZANA', 'Base blanca, Mozzarella, Parmesano, Queso azul, Manzana verde, Miel.', '[{"label":"","price":39900,"discounted":null}]'::jsonb, false, '/images/products/7b9ffa3c-6e54-4b73-b933-a2d529a1547f.webp', false, true, -1.0625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('VEEouNPQYpcb04BmXiOK', 'TD6OgqEuCQGAL7xZMqMB', 'QUATTRO FORMAGGI', 'Base blanca, Mozzarella, Queso azul, Grana padano, Parmesano.', '[{"label":"","price":39900,"discounted":null}]'::jsonb, false, null, false, true, -0.1875);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('vMnipNMBfrxNjUIMT58H', 'TD6OgqEuCQGAL7xZMqMB', 'DEL HUERTO', 'Mozzarella, Jamón, tomate Cherry, champiñones, Grana padano, Rúgula, Salsa blanca.', '[{"label":"","price":44900,"discounted":null}]'::jsonb, false, null, false, false, -0.171875);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('i00Kn7PxiYx23ykkxBCW', 'TD6OgqEuCQGAL7xZMqMB', 'SOLOMITO, BALSÁMICO & QUESO AZUL', 'Base blanca, Mozzarella, Solomito de res, Reducción balsámica con queso azul.', '[{"label":"","price":56900,"discounted":null}]'::jsonb, false, null, false, false, -0.1640625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Tlm0fxMMJlvaBtv63bWb', 'TD6OgqEuCQGAL7xZMqMB', 'DELLA  CASA', 'Base blanca, mozzarella, Queso Azul, Queso Brie, Tocineta caramelizada, Maíz tierno.', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, '/images/products/1c0cf114-0add-422a-bc3d-ed41737d2991.webp', true, false, -0.16015625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('SktGhOZs4Ec6mJX9ZQ5I', 'TD6OgqEuCQGAL7xZMqMB', 'TOSCANA MADURADA', 'Pomodoro, Mozzarella, Queso crema, Prosciutto, Salami, Chorizo vela, Aceitunas, Reducción Balsamica', '[{"label":"","price":48900,"discounted":null}]'::jsonb, false, '/images/products/e4b3b495-c511-40d3-b7ef-c3e8e20800c3.webp', false, false, -0.15625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('P5rSnRh7BX3bSM1Llmj2', 'TD6OgqEuCQGAL7xZMqMB', 'TOSCANA BBQ', 'Pomodoro, Mozzarella, Lomo de cerdo ahumado en BBQ, Cebollín.', '[{"label":"","price":39900,"discounted":null}]'::jsonb, false, null, false, false, -0.0625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('cve7YFe4OKfEWIp0LprP', 'TD6OgqEuCQGAL7xZMqMB', 'PEPPERONI', 'Pomodoro, Mozzarella, Albahaca, Pepperoni.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, -0.0390625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('WeoX08fXaqzGtTt7JZLp', 'TD6OgqEuCQGAL7xZMqMB', 'POLLO & SETAS', 'Pomodoro, Mozzarella, Pollo, Champiñones, Grana Padano, Cebollín.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, -0.02734375);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('mHGwp7J1ir1kyz5hwfgd', 'TD6OgqEuCQGAL7xZMqMB', 'HAWAIANA', 'Pomodoro, Mozzarella, Jamón de cerdo, Piña caramelizada.', '[{"label":"","price":38900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('5yZoE1fUZgQTIY4w8f2b', 'lunch-y-dinner', null, 'menu-bambini', 'MENÚ BAMBINI', '', null, 'list', 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('LvntWy1O3ooJhDFBgq3l', '5yZoE1fUZgQTIY4w8f2b', 'TORNADOS DE POLLO', 'Tenders de pollo apanados, acompañados con papas a la francesa y salsa rosada.', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('6urx720QbPmzVOsmQL5u', '5yZoE1fUZgQTIY4w8f2b', 'MINI BOLOGNESA', 'carne de res en tradicional salsa italiana elaborada con tomate San Marzano. Acompañada con pan artesanal de masa madre.', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('jMztVk4nd2x6epAF4j3Y', '5yZoE1fUZgQTIY4w8f2b', 'MINI FESTIN DE QUESO & POLLO', 'Tornados de pollo acompañados con fettuccine cremado en salsa especial de quesos de la casa y acompañada con pan artesanal de masa madre.', '[{"label":"","price":29900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('Hf2GWAUwlrLL8DDGhKzS', 'lunch-y-dinner', null, 'pasticceria', 'PASTICCERIA', 'Información sobre alérgenos: si tienes alguna alergia alimentaria, restricción y/o intolerancia, te pedimos informarlo.', null, 'cards', 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('0RjnNZTfX5yEqSjkNULE', 'Hf2GWAUwlrLL8DDGhKzS', 'MILLEFOGLIE FRUTTI DI BOSCO', 'Milhoja della casa con finas capas crujientes de masa filo caramelizada, ensambladas con confitura de frutos rojos, frosting de queso, arequipe de la casa y almendras garrapiñadas.', '[{"label":"","price":16900,"discounted":null}]'::jsonb, false, '/images/products/056b4c1e-987d-4488-abb3-5d9ae08b9f8d.webp', false, false, -2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('XhlycPBIepaw8QygmQgc', 'Hf2GWAUwlrLL8DDGhKzS', 'BAKLAVA CHEESECAKE', 'Tarta horneada de Queso Philadelphia cubierta con masa filo caramelizada, praliné de pistacho y nueces, finalizada con finas capas crujientes embebidas en almibar infusionado de rosas.', '[{"label":"","price":20900,"discounted":null}]'::jsonb, false, null, false, false, -0.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('A0dtnsQD0tejEnFGgrUR', 'Hf2GWAUwlrLL8DDGhKzS', 'BLUEBERRY CHEESECAKE', 'Tarta horneada de Queso Philadelphia con exterior de galleta crujiente y confitura de de frutos del bosque.', '[{"label":"","price":14900,"discounted":null}]'::jsonb, false, null, false, false, -0.25);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('gf3V184EPbJPCMLNBJbv', 'Hf2GWAUwlrLL8DDGhKzS', 'TIRAMISÚ DELLA CASA', 'Clásico postre Italiano con capas de galletas biscuit embebidas en extracción de café, crema de queso mascarpone y fina lluvia de cacao amargo.', '[{"label":"","price":16900,"discounted":null}]'::jsonb, false, '/images/products/af52c80a-f01c-4ca9-9e3e-1856144ce2e1.webp', false, false, -0.125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('dMADqDfYFUvo62YeUokm', 'Hf2GWAUwlrLL8DDGhKzS', 'CRÈME BRÛLÉE', 'Postre francés que consiste en crema suave a base de huevos, aromatizada con vainilla y crujiente de azúcar caramelizado.', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('puWq8oPFW0MxZJxA8I8c', 'Hf2GWAUwlrLL8DDGhKzS', 'CALZONE DE NUTELLA', 'Masa artesanal de pizza con centro de Nutella avellanada, crocante de praliné de pistacho con nueces, finalizada con helado de vainilla y chocolate caliente.', '[{"label":"","price":30900,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('LkE8sgn8MkOkEf1QCFGt', 'lunch-y-dinner', 'Hf2GWAUwlrLL8DDGhKzS', 'galleteria', 'GALLETERÍA', '', null, 'cards', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('feYGPiocmxRu4ve4Ysnm', 'LkE8sgn8MkOkEf1QCFGt', 'ALFAJORES', 'Colección especial de alfajores de la casa.', '[{"label":"Dulce leche & coco","price":9200,"discounted":null},{"label":"Limone","price":6900,"discounted":null},{"label":"Arequipe & Avellanas","price":6900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('SzMuG8B4pno8VUhuh3ZD', 'LkE8sgn8MkOkEf1QCFGt', 'MACARONS', 'Selección de sabores de temporada Imagen de referencia.', '[{"label":"Citrón","price":7500,"discounted":null},{"label":"Arándanos","price":7500,"discounted":null}]'::jsonb, false, '/images/products/d523590e-e632-4db6-afb8-cc899a0b53ae.webp', false, false, 2.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('KUaEVp4D7iWrjryQPuHg', 'LkE8sgn8MkOkEf1QCFGt', 'BISCOTTI DELLA CASA', 'Premium cookies.', '[{"label":"Pistacchio","price":13900,"discounted":null},{"label":"Lemon pie & merengue","price":9900,"discounted":null},{"label":"Cioccolato","price":9900,"discounted":null},{"label":"Red velvet","price":9900,"discounted":null}]'::jsonb, false, '/images/products/40198199-b3a9-4783-91a6-0c49e98ebe54.webp', false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('MVUl7PGXBMnuaavH7oV2', 'lunch-y-dinner', 'Hf2GWAUwlrLL8DDGhKzS', 'tartaletas-pie', 'TARTALETAS/PIE', '', null, 'cards', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('TfaKDYmJsYHPbiJqPz2d', 'MVUl7PGXBMnuaavH7oV2', 'TARTALETA BLACKBERRY & VAINILLA CREAM', '', '[{"label":"","price":16900,"discounted":null}]'::jsonb, false, '/images/products/d21a3749-5d03-4662-9d1c-55a5c7b8dbfc.webp', false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('coGLpFIrjMUMKOY46ATf', 'MVUl7PGXBMnuaavH7oV2', 'TARTALETA LIMONE & PISTACCHIO', '', '[{"label":"","price":14900,"discounted":null}]'::jsonb, false, '/images/products/ad894c70-4707-4c41-8e99-80cbf6e740f4.webp', false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Pjjc592ZfVHCa5oQsb8q', 'MVUl7PGXBMnuaavH7oV2', 'APPLE PIE', '', '[{"label":"","price":17900,"discounted":null}]'::jsonb, false, '/images/products/28fd6a5c-5308-4cf6-a8cb-67600f56fe8a.webp', true, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('bPE2YzFU1gWuw5UkdBgJ', 'lunch-y-dinner', 'Hf2GWAUwlrLL8DDGhKzS', 'pasteles', 'PASTELES', '', null, 'cards', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('ClLljwjXD13MDv3wgyH4', 'bPE2YzFU1gWuw5UkdBgJ', 'CIOCCOLATO & FRAMBUESAS', '', '[{"label":"","price":20900,"discounted":null}]'::jsonb, false, '/images/products/90a5b2b1-56aa-4ad1-90cb-d187c2636907.webp', false, false, 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('n0fASkrIRNiuxu2GxzwY', 'bPE2YzFU1gWuw5UkdBgJ', 'TRES LECHES & MERENGUE', '', '[{"label":"","price":14900,"discounted":null}]'::jsonb, false, null, false, false, 7.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('y4FNfxpOq14AdDNKMfZ1', 'bPE2YzFU1gWuw5UkdBgJ', 'ZANAHORIA &  NUECES', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 8);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('hjtVMlh89wPLGdv2JoTZ', 'bPE2YzFU1gWuw5UkdBgJ', 'AMAPOLA & FRAMBUESAS', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 12);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('oXuIvkvbwfsF3i6uCZwF', 'lunch-y-dinner', null, 'panetteria', 'PANETTERIA', 'VIENNOISERIE', null, 'cards', 8);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('1elD07j8v4ADRmZ4n5ty', 'oXuIvkvbwfsF3i6uCZwF', 'CROISSANT DE PISTACCHIO', '', '[{"label":"","price":17900,"discounted":null}]'::jsonb, false, '/images/products/6f960481-1181-48fa-9d80-1cc0ccb3e82d.webp', false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('6FsREyW5MoESSyCSTY5Y', 'oXuIvkvbwfsF3i6uCZwF', 'CROISSANT DE CHOCO-AVELLANAS', '', '[{"label":"","price":14900,"discounted":null}]'::jsonb, false, '/images/products/39cc41aa-86e8-4aee-85a9-8b9576ed46bd.webp', false, false, 0.125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('7iAyQNJCDP6D8BdZNNfy', 'oXuIvkvbwfsF3i6uCZwF', 'CROISSANT DE CHOCO-ALMENDRAS', '', '[{"label":"","price":14900,"discounted":null}]'::jsonb, false, null, false, false, 0.1875);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('kBuHkfp9RE8DGdPRIFfp', 'oXuIvkvbwfsF3i6uCZwF', 'CROISSANT DE ALMENDRAS', '', '[{"label":"","price":14900,"discounted":null}]'::jsonb, false, '/images/products/9692221d-7300-4803-859e-9bfd9cc535e6.webp', false, false, 0.25);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('NCJGsgIwSX6wSsa0z7Y2', 'oXuIvkvbwfsF3i6uCZwF', 'CROISSANT CIOCCOLATO & MERENGUE', '', '[{"label":"","price":10900,"discounted":null}]'::jsonb, false, '/images/products/d550030c-0c02-4d66-9458-6110c6aa18cd.webp', false, false, 0.625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('JlOHCMvL0AGvB5dHO3HD', 'oXuIvkvbwfsF3i6uCZwF', 'CROISSANT SALATO', '', '[{"label":"4 Quesos","price":10900,"discounted":null},{"label":"Mantequilla","price":7500,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('6wzc42kLzqf1hvTvGFHm', 'oXuIvkvbwfsF3i6uCZwF', 'QUICHÉ LORRAINE DE TOCINETA', '', '[{"label":"","price":16900,"discounted":null}]'::jsonb, false, '/images/products/5d2e4d36-b5b4-432e-8455-2f8ebfc0bc4e.webp', true, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('6sksVGsPBxHR6rh1NzfV', 'oXuIvkvbwfsF3i6uCZwF', 'PANE', 'PRESENTACION FAMILIAR', '[{"label":"Hogaza masa madre","price":14000,"discounted":null},{"label":"Brioche","price":18000,"discounted":null},{"label":"Semillas & Arándanos","price":20900,"discounted":null}]'::jsonb, false, '/images/products/4a182096-c26c-4f41-85ab-b3346fdbd645.webp', false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('2O7aPSRPCliWn530mZ3J', 'oXuIvkvbwfsF3i6uCZwF', 'DOLCI', '', '[{"label":"Cinnamon Roll","price":12900,"discounted":null}]'::jsonb, false, '/images/products/20f045a6-1b9e-4efe-910a-8f25fdc128dd.webp', true, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('XD3i0LN5aMu3N0ez6scz', 'oXuIvkvbwfsF3i6uCZwF', 'SALATO', '', '[{"label":"Focaccia della Casa","price":8900,"discounted":null}]'::jsonb, false, '/images/products/d9ec7ec7-c586-45aa-829d-ea55abbc128f.webp', true, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('gshvTbfqoOklaG5A2f7d', 'oXuIvkvbwfsF3i6uCZwF', 'TRADIZIONALE', '', '[{"label":"Pandeyuca della Casa","price":4000,"discounted":null},{"label":"Pandebono della Casa","price":4000,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('JlatCbARFaeg9RSfC4QM', 'lunch-y-dinner', null, 'il-bar', 'IL BAR', '', null, 'list', 9);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('kbvkXfhaLhGjh1cQAVxH', 'lunch-y-dinner', 'JlatCbARFaeg9RSfC4QM', 'd-autore', 'D''AUTORE', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('TPIsH0EfJTFHCtfivY43', 'kbvkXfhaLhGjh1cQAVxH', 'GIN-LIMONCELLO', 'Ginebra, Limoncello, Butterfly pea flower , Cordial de manzanas y peras.', '[{"label":"","price":42900,"discounted":null}]'::jsonb, false, null, false, false, -1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('fFxsVbZR7llsmV6JSPIN', 'kbvkXfhaLhGjh1cQAVxH', 'DOLCE', 'Ron, Puré De Mango, Crema De Coco y Hierbabuena.', '[{"label":"","price":40000,"discounted":null}]'::jsonb, false, null, false, false, -0.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('LexF9qCEX7Z38c15Noxn', 'kbvkXfhaLhGjh1cQAVxH', 'AMORE MÍO', 'Ginebra, triple sec, hierbabuena, syrup de almendras y coco, y macerado de cerezas.', '[{"label":"","price":44000,"discounted":null}]'::jsonb, false, null, false, false, -0.25);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('jjqoEXKXUms5S5dTEQ64', 'lunch-y-dinner', 'JlatCbARFaeg9RSfC4QM', 'spritz-della-casa', 'SPRITZ DELLA CASA', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('yIdANzjGdLWvzodFizSU', 'jjqoEXKXUms5S5dTEQ64', 'APEROL SPRITZ', 'Aperol, soda y vino espumoso.', '[{"label":"","price":36000,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('P3nqCdUGSuWOPFUfurbV', 'jjqoEXKXUms5S5dTEQ64', 'FRAGOLA SPRITZ', 'Aperol, shrub de fresa, zumo de piña y Ginger beer.', '[{"label":"","price":38900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('VIhp0zh61p3JL4DiIt0m', 'jjqoEXKXUms5S5dTEQ64', 'MANDARINA SPRITZ', 'Tequila, Aperol, Cordial cítrico de mandarina herbal.', '[{"label":"","price":42900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('704TIqoxECzFd1XVQjCO', 'jjqoEXKXUms5S5dTEQ64', 'FIERO SPRITZ', 'Martini fiero, crema de cassis, soda, zumo de mandarina y naranja.', '[{"label":"","price":38900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('qsa1YYj5D3D59skto0fb', 'lunch-y-dinner', 'JlatCbARFaeg9RSfC4QM', 'mocktail', 'MOCKTAIL', 'CÓCTELES SIN ALCOHOL', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('MA22oIChaKuBQyzZlxmL', 'qsa1YYj5D3D59skto0fb', 'BELLA DONNA', 'Shrub de mora, naranja, limón, ginger beer.', '[{"label":"","price":19500,"discounted":null}]'::jsonb, false, null, false, false, -1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('gEoChVYIkYMowPD0R9U6', 'qsa1YYj5D3D59skto0fb', 'VIRGIN MANGO', 'Pepino, miel de agave, puré de mango fresco, limón, ginger beer y hierbabuena.', '[{"label":"","price":19500,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('x1H6TJmQdoTHdoewWvRA', 'qsa1YYj5D3D59skto0fb', 'VIRGIN MOJITO', 'Flor de Jamaica, hierbabuena, miel de agave, limón, ginger beer.', '[{"label":"","price":19500,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('8YYD4gQCMYCkzsu9DGZX', 'lunch-y-dinner', 'JlatCbARFaeg9RSfC4QM', 'classici', 'CLASSICI', '', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('YWpY8yPQ90EpAKHG3UUV', '8YYD4gQCMYCkzsu9DGZX', 'MIMOSA', 'Zumo de naranja, vino espumoso, Cereza.', '[{"label":"","price":20900,"discounted":null}]'::jsonb, false, null, false, false, -1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('H7YFdSw6a4UmcnWmqMtK', '8YYD4gQCMYCkzsu9DGZX', 'BELLINI', 'Vino espumoso, puré de durazno.', '[{"label":"","price":18900,"discounted":null}]'::jsonb, false, null, false, false, -0.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Bl1jYfC58GgfzgMuzgQc', '8YYD4gQCMYCkzsu9DGZX', 'CARAJILLO 43', 'Licor 43, espresso, aceites cítricos, naranja.', '[{"label":"","price":30500,"discounted":null}]'::jsonb, false, null, false, false, -0.25);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('MLame7df8xHtwH2SBTQh', '8YYD4gQCMYCkzsu9DGZX', 'ESPRESO MARTINI', 'Vodka, licor de café y espresso.', '[{"label":"","price":36900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('hIayaM7pKZsGyBMoLAfh', '8YYD4gQCMYCkzsu9DGZX', 'NEGRONI', 'Ginebra, Vermouth Rosso y Campari.', '[{"label":"","price":40000,"discounted":null}]'::jsonb, false, null, false, false, 0.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('hEpQ7mAJ9Ko91TcJB9nv', '8YYD4gQCMYCkzsu9DGZX', 'NEGRONI D'' PANISSE', 'Ginebra, Vermouth Rosso, Campari y Cordial de piña deshidratada.', '[{"label":"","price":38000,"discounted":null}]'::jsonb, false, null, false, false, 0.75);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('afbCgFCp9t77nfZlA8Rg', '8YYD4gQCMYCkzsu9DGZX', 'OLD FASHIONED', 'Whiskey Jack Daniel''s, azúcar, Bitter de naranja y twist de naranja.', '[{"label":"","price":40000,"discounted":null}]'::jsonb, false, null, false, false, 0.875);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('WrwbVgCMAcISsQFSd2IE', '8YYD4gQCMYCkzsu9DGZX', 'DRY MARTINI', 'Ginebra, Vermouth extra dry, aceitunas.', '[{"label":"","price":36000,"discounted":null}]'::jsonb, false, null, false, false, 0.9375);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('ZD4SMV7vkXRUVj1ZEXf7', '8YYD4gQCMYCkzsu9DGZX', 'LYCHEE MARTINI', 'Ginebra, Vermouth extra dry, Lychee.', '[{"label":"","price":38900,"discounted":null}]'::jsonb, false, null, false, false, 0.96875);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('N1Gdp0lyC6fDPmY3ShSZ', '8YYD4gQCMYCkzsu9DGZX', 'STAR MARTINI', 'Vodka, Triple sec, Vino Espumoso, Almíbar de Maracuyá, Vainilla.', '[{"label":"","price":36000,"discounted":null}]'::jsonb, false, null, false, false, 0.984375);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('4olCkUpLe4OjIF0ZVsDk', '8YYD4gQCMYCkzsu9DGZX', 'MINT JULEP', 'Whiskey Jack Daniel’s, Hierbabuena, Bitter aromatic, Sirope simple.', '[{"label":"","price":38000,"discounted":null}]'::jsonb, false, null, false, false, 0.9921875);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('5TzeFkF8vbQCdovW7Ab7', '8YYD4gQCMYCkzsu9DGZX', 'MOSCOW MULE', 'Vodka, Almíbar de Jengibre, Hierbabuena, limón, Ginger Beer Mil 976.', '[{"label":"","price":38000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('eQmEucNN90VzJialgYq6', '8YYD4gQCMYCkzsu9DGZX', 'MARGARITA', 'Tequila Gran Centenario Reposado, Triple sec, Limón.', '[{"label":"","price":40000,"discounted":null}]'::jsonb, false, null, false, false, 2.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('wx8YNiKOoMy46ARHOF4c', '8YYD4gQCMYCkzsu9DGZX', 'MOJITO', 'Ron Bacardí, Hierbabuena, Limón, Soda.', '[{"label":"","price":30900,"discounted":null}]'::jsonb, false, null, false, false, 3.25);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('7RK1c3xExrqNbxRt4FDf', '8YYD4gQCMYCkzsu9DGZX', 'GIN MARTIN CITRUS', 'Martin miller''s Gin, Agua tonica, Mandarina, Limon.', '[{"label":"","price":50000,"discounted":null}]'::jsonb, false, null, false, false, 4.625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('VoiQlunlQwcig6G9jd0L', '8YYD4gQCMYCkzsu9DGZX', 'GIN HENDRICKS CLASSIC', 'Gin Hendrck''s, Pepino, Agua tonica.', '[{"label":"","price":47000,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('oNvoqEZQPwGGnVJeNZHx', 'lunch-y-dinner', null, 'bebidas', 'BEBIDAS', '', null, 'list', 10);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('ctX67UOJb4Nr4diJbA3z', 'lunch-y-dinner', 'oNvoqEZQPwGGnVJeNZHx', 'limonata', 'LIMONATA', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('g2gtpVQOWzzktfGBYz5I', 'ctX67UOJb4Nr4diJbA3z', 'LIMONA DE VINO', 'TINTO, BLANCO Y ROSÉ.', '[{"label":"","price":20900,"discounted":null}]'::jsonb, false, null, false, false, -1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('fX5PocfW967Sl350e6On', 'ctX67UOJb4Nr4diJbA3z', 'LIMONADA ITALIANA', '(CON LICOR APEROL)', '[{"label":"","price":22900,"discounted":null}]'::jsonb, false, null, false, false, -0.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('xXs7tculcj7C6QZAHdjA', 'ctX67UOJb4Nr4diJbA3z', 'PIÑA & ALBAHACA', '', '[{"label":"","price":11900,"discounted":null}]'::jsonb, false, null, false, false, -0.25);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('4hDhUlI37By2p6FAR2zc', 'ctX67UOJb4Nr4diJbA3z', 'COCO', '', '[{"label":"","price":11900,"discounted":null}]'::jsonb, false, null, false, false, -0.125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('warnOMOXbEgmXpN8voh3', 'ctX67UOJb4Nr4diJbA3z', 'HIERBABUENA', '', '[{"label":"","price":10900,"discounted":null}]'::jsonb, false, null, false, false, -0.0625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('FW1tmb8LXDv2Rt8RiK0e', 'ctX67UOJb4Nr4diJbA3z', 'NATURAL', '', '[{"label":"","price":8900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('SToC5qHsdZTHzjmE2Q9v', 'lunch-y-dinner', 'oNvoqEZQPwGGnVJeNZHx', 'jugos', 'JUGOS', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('OZQEYmzGxKazGgsaDckc', 'SToC5qHsdZTHzjmE2Q9v', 'JUGO DE MANDARINA', '', '[{"label":"","price":9900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('y0wxqxuHGBfr9bNb34eL', 'SToC5qHsdZTHzjmE2Q9v', 'MANGO-MARACUYÁ', '', '[{"label":"Agua","price":9900,"discounted":null},{"label":"Leche","price":10900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('xQC667NHdUom9FDmzn2f', 'SToC5qHsdZTHzjmE2Q9v', 'FRESA', '', '[{"label":"Agua","price":9900,"discounted":null},{"label":"Leche","price":10900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('vYp1PgSuGNEw0sYqE2SM', 'lunch-y-dinner', 'oNvoqEZQPwGGnVJeNZHx', 'sodas-italianas', 'SODAS ITALIANAS', '', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Mv129koKJU6eYl6EY3pk', 'vYp1PgSuGNEw0sYqE2SM', 'LYCHEE & DURAZNO', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('SoZNVpRoeiMl1FtgeqgS', 'vYp1PgSuGNEw0sYqE2SM', 'FRESA & ALBAHACA', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('H3cJlXJeoV2hLDFBLluq', 'vYp1PgSuGNEw0sYqE2SM', 'PIÑA & MANDARINA', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('lF59V7rGBZyb5Dbz83RM', 'vYp1PgSuGNEw0sYqE2SM', 'FRUTTO DELLA PASSIONE', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 9);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('beYW3QF68PQrRIRSKc4k', 'vYp1PgSuGNEw0sYqE2SM', 'SODA MICHELADA', '', '[{"label":"","price":8900,"discounted":null}]'::jsonb, false, null, false, false, 10);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('4gA2kaqDHLq3zGmg93kU', 'lunch-y-dinner', 'oNvoqEZQPwGGnVJeNZHx', 'cervezas-otros', 'CERVEZAS & OTROS', '', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('wqRi48d2hhz5S5nLGMka', '4gA2kaqDHLq3zGmg93kU', 'CORONA', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('N1wZqYmKj1OJldE2XaDN', '4gA2kaqDHLq3zGmg93kU', 'CORONA 0,0%', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 2.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('8fRwvSccWzEPfjisZB5g', '4gA2kaqDHLq3zGmg93kU', 'CLUB COLOMBIA DORADA', '', '[{"label":"","price":10400,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('zEUAmbqWjOEbg2dKfXYh', '4gA2kaqDHLq3zGmg93kU', 'STELLA ARTOIS', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('VCV7fHdqA4H6r4yGN8dL', '4gA2kaqDHLq3zGmg93kU', 'AGUA MANANTIAL', '', '[{"label":"","price":7200,"discounted":null}]'::jsonb, false, null, false, false, 4.625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('UmWsUG4SHJDadBdnAg2v', '4gA2kaqDHLq3zGmg93kU', 'COCA COLA', '', '[{"label":"","price":6900,"discounted":null}]'::jsonb, false, null, false, false, 4.9375);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('nkIujteG6g808Y2Kg0ca', '4gA2kaqDHLq3zGmg93kU', 'HATSU BLANCO', '', '[{"label":"","price":8900,"discounted":null}]'::jsonb, false, null, false, false, 5.25);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('P5V2BRpVzwqjRrlGZwD8__lunch-y-dinner', 'lunch-y-dinner', 'oNvoqEZQPwGGnVJeNZHx', 'bebidas-frias', 'BEBIDAS FRÍAS', '', null, 'list', 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Ztnw0EiqmEf8f4TSdP2j__lunch-y-dinner', 'P5V2BRpVzwqjRrlGZwD8__lunch-y-dinner', 'MILO FRAPPÉ', '', '[{"label":"","price":10500,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('aCF87o0Lw3rQU3J1CTNY__lunch-y-dinner', 'P5V2BRpVzwqjRrlGZwD8__lunch-y-dinner', 'TÉ CHAI FRAPPÉ', '', '[{"label":"","price":13900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('o5ejQG8lD6YjP2NVdMVx__lunch-y-dinner', 'P5V2BRpVzwqjRrlGZwD8__lunch-y-dinner', 'TÉ MATCHA FRAPPÉ', '', '[{"label":"","price":14900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('q350tWs7BiqCpmJhRF26', 'lunch-y-dinner', 'oNvoqEZQPwGGnVJeNZHx', 'preparaciones-especiales', 'PREPARACIONES ESPECIALES', '', null, 'list', 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('WVOtBPJarBw2ooObBSfh', 'q350tWs7BiqCpmJhRF26', 'FILTRADOS DE CAFE', 'Método de extracción por goteo de nuestro café de origen (2 tazas).', '[{"label":"V60","price":14000,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('nGJK5h4Bu41FfZRTBZi5', 'q350tWs7BiqCpmJhRF26', 'COLD BREW', 'Extracción de café frio por 24 horas.', '[{"label":"Clásico","price":9500,"discounted":null},{"label":"Latte","price":10000,"discounted":null},{"label":"Mandarina/Limón","price":10900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Kbi3RA0SZR5sdmkW1jPY', 'q350tWs7BiqCpmJhRF26', 'CON LICOR', '', '[{"label":"Mimosa Panisse","price":20900,"discounted":null},{"label":"Bellini","price":18900,"discounted":null},{"label":"Carajillo 43","price":30500,"discounted":null},{"label":"Espresso Martini","price":36900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('agPwVQhj8A7HNoCdBm8Q', 'lunch-y-dinner', null, 'caffe-panisse', 'CAFFÉ PANISSE', '', null, 'list', 11);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('aLvsNc6LPmvVWvpTPCSN__lunch-y-dinner', 'lunch-y-dinner', 'agPwVQhj8A7HNoCdBm8Q', 'capuccino-latte', 'CAPUCCINO/LATTE', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('yLCi6w58sZ1g463K67hA__lunch-y-dinner', 'aLvsNc6LPmvVWvpTPCSN__lunch-y-dinner', 'TRADICIONAL', '', '[{"label":"","price":7900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('cU5oVQ0e5hzYukOp5izE__lunch-y-dinner', 'aLvsNc6LPmvVWvpTPCSN__lunch-y-dinner', 'VAINILLA', '', '[{"label":"","price":10000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('fGwX4z9CO8OqUnHKefhG__lunch-y-dinner', 'aLvsNc6LPmvVWvpTPCSN__lunch-y-dinner', 'CARAMELO', '', '[{"label":"","price":10000,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('spSgQMbBApwlOdjy87El__lunch-y-dinner', 'aLvsNc6LPmvVWvpTPCSN__lunch-y-dinner', 'MOCACCINO', '', '[{"label":"Sin Licor","price":10000,"discounted":null},{"label":"Con Licor","price":16000,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('pthTTlp9Ly1MELRURuEa__lunch-y-dinner', 'lunch-y-dinner', 'agPwVQhj8A7HNoCdBm8Q', 'espresso', 'ESPRESSO', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('U6TDjlKT6E4lv6noI49h__lunch-y-dinner', 'pthTTlp9Ly1MELRURuEa__lunch-y-dinner', 'ESPRESSO', '', '[{"label":"","price":5500,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('9UiGL7fW5QvCfzJ0CQtB__lunch-y-dinner', 'pthTTlp9Ly1MELRURuEa__lunch-y-dinner', 'AMERICANO', '', '[{"label":"","price":6000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('U6Sgblv8t5tOdy7ZNaoD__lunch-y-dinner', 'pthTTlp9Ly1MELRURuEa__lunch-y-dinner', 'MACCHIATO', '', '[{"label":"","price":7000,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('VEyozh8C7nlDFNaHSflZ__lunch-y-dinner', 'lunch-y-dinner', 'agPwVQhj8A7HNoCdBm8Q', 'preparaciones-con-cafe-frias', 'PREPARACIONES CON CAFÉ FRÍAS', '', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('pdZZkMpDPKEr3IDY8o34__lunch-y-dinner', 'VEyozh8C7nlDFNaHSflZ__lunch-y-dinner', 'AMERICANO ICE', '', '[{"label":"","price":7000,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('qvEmNon194qfNDq8MfDK__lunch-y-dinner', 'VEyozh8C7nlDFNaHSflZ__lunch-y-dinner', 'LATTE', '', '[{"label":"Clasico","price":9900,"discounted":null},{"label":"Vainilla","price":12900,"discounted":null},{"label":"Caramelo","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('JuUlz5hyzbNSIw4P9JBK__lunch-y-dinner', 'VEyozh8C7nlDFNaHSflZ__lunch-y-dinner', 'FROZEN', '', '[{"label":"Cappuccino","price":15000,"discounted":null},{"label":"Caramelo","price":15900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('axnDPjsEGtRrSfyAZbVw__lunch-y-dinner', 'lunch-y-dinner', 'agPwVQhj8A7HNoCdBm8Q', 'bebidas-calientes', 'BEBIDAS CALIENTES', '', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('vuZAFJST7PiYIHKytRP7__lunch-y-dinner', 'axnDPjsEGtRrSfyAZbVw__lunch-y-dinner', 'MILO', '', '[{"label":"","price":8500,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('5wmWPUqmwJfiP3vQ7zIV__lunch-y-dinner', 'axnDPjsEGtRrSfyAZbVw__lunch-y-dinner', 'TÉ CHAI', '', '[{"label":"","price":9900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('paCO2Fj6iXHr295Ip9Ge__lunch-y-dinner', 'axnDPjsEGtRrSfyAZbVw__lunch-y-dinner', 'TÉ MATCHA', '', '[{"label":"","price":10900,"discounted":null}]'::jsonb, false, null, false, false, 1.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('PCl6X0gTeIGjow7Nx7tc__lunch-y-dinner', 'axnDPjsEGtRrSfyAZbVw__lunch-y-dinner', 'CHOCOLATE', '', '[{"label":"En Agua","price":6900,"discounted":null},{"label":"En Leche","price":7900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('qPfv2sYXESclx4NScJxF__lunch-y-dinner', 'axnDPjsEGtRrSfyAZbVw__lunch-y-dinner', 'INFUSIONES (A ELECCION)', '', '[{"label":"","price":6500,"discounted":null}]'::jsonb, false, null, false, false, 3.5);

-- ── Menú VINOS ──
insert into public.menus (slug, label, tagline, name, sort)
values ('vinos-y-bebidas', 'Vinos y Bebidas', 'Cava, coctelería y caffè', 'VINOS', 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('fI6yHWzb4FjTaksMXDw4', 'vinos-y-bebidas', null, 'vinos', 'VINOS', '', null, 'list', 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('RFV536ilulj30CsVtpIm', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'vinos-por-copa', 'VINOS POR COPA', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('cogca3ogAzSeZhbg1XCr', 'RFV536ilulj30CsVtpIm', 'COPA (TINTO, BLANCO, ROSÉ)', '', '[{"label":"","price":22900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Lvkob4SdquXG9z7zLkFD', 'RFV536ilulj30CsVtpIm', 'PICCINI MEMORO (TINTO, BLANCO, ROSÉ', '', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('ByY7wwjHiJrLYFMMmzQM', 'RFV536ilulj30CsVtpIm', 'TINTO DE VERANO', '', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('B8tns7de1FdkNLBNUPfh', 'RFV536ilulj30CsVtpIm', 'BLANCO DE VERANO', '', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, null, false, false, 2.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('gtuV3iOlX4tfxCWRSMYG', 'RFV536ilulj30CsVtpIm', 'VINO CALIENTE', '', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('U7ySLiBl7ZTmw9WMFv0X', 'RFV536ilulj30CsVtpIm', 'SANGRÍA', '', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('2NruVfF4PoQJZecOI2SR', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'della-casa', 'DELLA CASA', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('lGswL1ELTD6oefx0FdTZ', '2NruVfF4PoQJZecOI2SR', 'PICCINI MEMORO ( TINTO, BLANCO, ROSÉ)', '', '[{"label":"","price":92900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('6B4u7pQ26STmaBmypkcg', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'generosos', 'GENEROSOS', '', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('XWSczrzhu2u6XJ3kKOpA', '6B4u7pQ26STmaBmypkcg', 'JEREZ ESPAÑOL TÍO PEPE (copa)', '', '[{"label":"","price":28900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('ZEAdW5HpL3iT7XYQKS3A', '6B4u7pQ26STmaBmypkcg', 'JEREZ ESPAÑOL ELEGANTE AMONTILLADO(copa)', '', '[{"label":"","price":21900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('qKZRMLwiP9jwBUCPucYM', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'frizzante', 'FRIZZANTE', '', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('PleexbDNhnRv35DJ5lBq', 'qKZRMLwiP9jwBUCPucYM', 'PICCINI REGNO (TINTO, BLANCO, ROSÉ)', '', '[{"label":"","price":99900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('yeY28AV6wXaZfPG8oiF8', 'qKZRMLwiP9jwBUCPucYM', 'CHANDON GARDEN SPRITZ', '', '[{"label":"","price":159700,"discounted":null}]'::jsonb, false, null, false, false, 0.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('JLeTsMbYMbkOCOQ4Gatm', 'qKZRMLwiP9jwBUCPucYM', 'CHANDON BRUT ROSÉ', '', '[{"label":"","price":135000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('aAAWtBaYkdoW20Lcff6G', 'qKZRMLwiP9jwBUCPucYM', 'CHANDON EXTRA BRUT', '', '[{"label":"","price":120000,"discounted":null}]'::jsonb, false, null, false, false, 1.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('maewZ4jquh2qal4ZQyXu', 'qKZRMLwiP9jwBUCPucYM', 'MIONETTO PROSECO', '', '[{"label":"","price":119900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('25NkmPi0iiPbbCNGISNl', 'qKZRMLwiP9jwBUCPucYM', 'VEUVE CLICQUOT BRUT DO CHAMPAGNE', '', '[{"label":"Botella","price":900000,"discounted":null},{"label":"Media Botella","price":499000,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('xGxcjY5a2nBwMHVnfZgh', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'blanco', 'BLANCO', '', null, 'list', 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('WrHz4BLYPnsLjGWHnmZN', 'xGxcjY5a2nBwMHVnfZgh', 'MAR DE FRADES ALBARIÑO', '', '[{"label":"","price":189900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('a0LYGvPzGAkPLQavD1eh', 'xGxcjY5a2nBwMHVnfZgh', 'ENATE CHARDONNAY', '', '[{"label":"","price":169900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('UIpShjjQWGYsRy3g4OfW', 'xGxcjY5a2nBwMHVnfZgh', 'SANTA CAROLINA RESERVADO', 'SAUVIGNON BLANC', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('H1ppJqIGMZoPAEeRl7ow', 'xGxcjY5a2nBwMHVnfZgh', 'MUGA RESERVA', 'VIURA', '[{"label":"","price":149900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('eW6U7Sw9WhAtbObH0oQL', 'xGxcjY5a2nBwMHVnfZgh', 'MARA MARTÍN', 'GODELLO', '[{"label":"","price":124900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('jqXVVaUKfROiM5lwgut6', 'xGxcjY5a2nBwMHVnfZgh', 'RAMÓN BILBAO', 'VERDEJO', '[{"label":"","price":129900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('pSBjCTDLvyj6Y40W1joN', 'xGxcjY5a2nBwMHVnfZgh', 'MARQUÉS DEL RISCAL', 'VERDEJO', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('I0yPmnVxl18WoCN8MVGG', 'xGxcjY5a2nBwMHVnfZgh', 'FINCA LAS MORAS', 'CHARDONNAY', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('GheupBFeTjEn58MryhrS', 'xGxcjY5a2nBwMHVnfZgh', 'MICHEL TORINO', 'TORRONTÉS', '[{"label":"","price":93000,"discounted":null}]'::jsonb, false, null, false, false, 8);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('0saII9YI4Sp1FTHCvFJt', 'xGxcjY5a2nBwMHVnfZgh', 'PICCINI MEMORO', 'CHARDONNAY/VERMENTINO', '[{"label":"","price":92900,"discounted":null}]'::jsonb, false, null, false, false, 9);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('0Xnj0mLdRlxHQW2IXEFE', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'rose', 'ROSÉ', '', null, 'list', 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('423nWe3vhlQstZihS127', '0Xnj0mLdRlxHQW2IXEFE', 'RAMÓN BILBAO', 'GARNACHA', '[{"label":"","price":139900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('HZd5cLWL5VT8jMmmwS9r', '0Xnj0mLdRlxHQW2IXEFE', 'SANTA CAROLINA RESERVADO', 'CABERNET SAUVIGNON', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('2pZJLn29HpjR47nNNyY5', '0Xnj0mLdRlxHQW2IXEFE', 'ENATE', 'CABERNET SAUVIGNON', '[{"label":"","price":169900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('nG8Uf3d3tKibasCGrAUd', '0Xnj0mLdRlxHQW2IXEFE', 'FINCA LA CELIA', 'MALBEC', '[{"label":"","price":125900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('dyHbQ3j5w5l9FlJcCXQ3', '0Xnj0mLdRlxHQW2IXEFE', 'JP CHENET', '', '[{"label":"","price":103900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('izrMHE0qdITRvwhFxqOv', '0Xnj0mLdRlxHQW2IXEFE', 'MICHEL TORINO', 'MALBEC', '[{"label":"","price":93000,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Q6zNWEyFaIQazGnE34wO', '0Xnj0mLdRlxHQW2IXEFE', 'PICCINI MEMORO', 'NEGRO AMARO NERO D''AVOLA', '[{"label":"","price":92900,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('ruui0ICspeE1WlhDelOP', '0Xnj0mLdRlxHQW2IXEFE', 'VIÑA TARAPACÁ', 'CABERNET SAUVIGNON', '[{"label":"","price":85900,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('3dY1mQZwJMItEccXizOs', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'tinto', 'TINTO', '', null, 'list', 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('packrMOBFFQpwhgHf6hn', '3dY1mQZwJMItEccXizOs', 'MARQUÉS DE VARGAS RESERVA', 'TEMPRANILLO', '[{"label":"","price":239000,"discounted":null}]'::jsonb, false, null, false, false, -1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Yo9mFKY9WojZcNSTn3An', '3dY1mQZwJMItEccXizOs', 'MARQUÉS DEL RISCAL RESERVA', 'TEMPRANILLO', '[{"label":"","price":219900,"discounted":null}]'::jsonb, false, null, false, false, -0.5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('RZ9M2pB7cy9nJDijmhU6', '3dY1mQZwJMItEccXizOs', 'MARQUÉS DE ARIENZO CRIANZA', 'TEMPRANILLO', '[{"label":"","price":175900,"discounted":null}]'::jsonb, false, null, false, false, -0.25);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('0Be2vPXMKOlDJUsFDykv', '3dY1mQZwJMItEccXizOs', 'ENATE-CABERNET SAUVIGNON', 'MERLOT', '[{"label":"","price":159900,"discounted":null}]'::jsonb, false, null, false, false, -0.125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('thkrrkISBJuaOY6wRrOS', '3dY1mQZwJMItEccXizOs', 'ENATE-CABERNET SAUVIGNON', 'TEMPRANILLO', '[{"label":"","price":159900,"discounted":null}]'::jsonb, false, null, false, false, -0.0625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('jYAM9Cn3PyLyuHS4kffn', '3dY1mQZwJMItEccXizOs', 'BERONIA CRIANZA', 'TEMPRANILLO', '[{"label":"","price":174900,"discounted":null}]'::jsonb, false, null, false, false, -0.03125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('ZMM5m0PdHXlnxaG1ibxt', '3dY1mQZwJMItEccXizOs', 'NORTON DOC', 'MALBEC', '[{"label":"","price":170900,"discounted":null}]'::jsonb, false, null, false, false, -0.015625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('DQP8zVQiam4gNIKIQoN1', '3dY1mQZwJMItEccXizOs', 'PROTOS ROBLE', 'TEMPRANILLO', '[{"label":"","price":166900,"discounted":null}]'::jsonb, false, null, false, false, -0.0078125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('rKx9x0L8zgDgjaY2vbQS', '3dY1mQZwJMItEccXizOs', 'RUFFINO', 'SANGIOVESE', '[{"label":"","price":175900,"discounted":null}]'::jsonb, false, null, false, false, -0.00390625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('i7SYRlfRaPHpJ0Uqbqbf', '3dY1mQZwJMItEccXizOs', 'PASQUA LAPACIO PRIMITIVO DE SALENTO', 'PRIMITIVO', '[{"label":"","price":146900,"discounted":null}]'::jsonb, false, null, false, false, -0.001953125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('8wbQzlQsM12NLtXkmffZ', '3dY1mQZwJMItEccXizOs', 'RISCAL DO CASTILLA', 'TEMPRANILLO', '[{"label":"","price":13900,"discounted":null}]'::jsonb, false, null, false, false, -0.0009765625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('iRX28twkNAd0KYyz3kyB', '3dY1mQZwJMItEccXizOs', 'MORANDÉ PIONERO RESERVA', 'MERLOT', '[{"label":"","price":134900,"discounted":null}]'::jsonb, false, null, false, false, -0.00048828125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('Pc3Or28NRNselBei7VcI', '3dY1mQZwJMItEccXizOs', 'SANTA RITA 120 RESERVA ESPECIAL', 'CARMÉNÉRE', '[{"label":"","price":132900,"discounted":null}]'::jsonb, false, null, false, false, -0.000244140625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('9RLddAn20lz7F5BVnbKm', '3dY1mQZwJMItEccXizOs', 'TRAPICHE RESERVA', 'SYRAH', '[{"label":"","price":129900,"discounted":null}]'::jsonb, false, null, false, false, -0.0001220703125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('vrrR7dUrhUob8fow9Kui', '3dY1mQZwJMItEccXizOs', 'LA CELIA RESERVA', 'MALBEC', '[{"label":"","price":109900,"discounted":null}]'::jsonb, false, null, false, false, -0.00006103515625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('eUNJPnxV8sRdWeQijHoY', '3dY1mQZwJMItEccXizOs', 'PASQUA MONTEPULCIANO D''ABRUZZO', 'MONTEPULCIANO', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, -0.000030517578125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('vrPTZaQyZJ4yTKlHYSmV', '3dY1mQZwJMItEccXizOs', 'FINCA LAS MORAS', 'BONARDA', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, -0.0000152587890625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('OWTcRfb6mfm3qWtDkFKB', '3dY1mQZwJMItEccXizOs', 'MICHEL TORINO', 'MALBEC', '[{"label":"","price":93000,"discounted":null}]'::jsonb, false, null, false, false, -0.00000762939453125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('zrt1An3yixIdnbylMxcq', '3dY1mQZwJMItEccXizOs', 'PICCINI MEMORO', 'NEGRO AMARO NERO D''AVOLA', '[{"label":"","price":92900,"discounted":null}]'::jsonb, false, null, false, false, -0.000003814697265625);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('7i7oYhwzN6E65IPnpVKz', '3dY1mQZwJMItEccXizOs', 'PICCINI ROSSO  IGT TOSCANA', 'SANGIOVESE', '[{"label":"","price":90000,"discounted":null}]'::jsonb, false, null, false, false, -0.0000019073486328125);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('dBykkAqXhj5EhJfuenCO', '3dY1mQZwJMItEccXizOs', 'RAMÓN BILBAO CRIANZA', 'TEMPRANILLO', '[{"label":"","price":129900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('g4E4AMrT7sEyluk2XCoJ', '3dY1mQZwJMItEccXizOs', 'SANTA CAROLINA RESERVADO', 'CABERNET SAUVIGNON', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('q9oS8YRiFqdTQqIud0L0', '3dY1mQZwJMItEccXizOs', 'SANTA CAROLINA RESERVADO', 'MERLOT', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('cADiuI5qqLCHr07hs425', '3dY1mQZwJMItEccXizOs', 'SANTA CAROLINA RESERVADO', 'CARMÉNÉRE', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('0CdKBpI7M0duvH4DtyRQ', '3dY1mQZwJMItEccXizOs', 'TRAPICHE RESERVA', 'CABERNET SAUVIGNON', '[{"label":"","price":109900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('sekd7Xu4HPOfL79Zwd8m', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'postres', 'POSTRES', 'Vinos de cosecha tardia', null, 'list', 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('w9gf5yWIMEDCYdecfuD1', 'sekd7Xu4HPOfL79Zwd8m', 'MORANDÉ LATE HARVEST', 'SAUVIGNON BLANC', '[{"label":"Media Botella","price":79900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('RbD1bIr6fPhQTLJEcxrM', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'medias-botellas', 'MEDIAS BOTELLAS', '', null, 'list', 8);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('nTElgy8J4KHLLkcC7kFb', 'RbD1bIr6fPhQTLJEcxrM', 'RISCAL TEMPRANILLO', 'SYRAH (tinto)', '[{"label":"","price":69900,"discounted":null}]'::jsonb, false, null, false, false, 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('gJ5MJFm4UuNj7Nsm7aGE', 'RbD1bIr6fPhQTLJEcxrM', 'SANTA CAROLINA RESERVADO', 'CABERNET SAUVIGNON (tinto)', '[{"label":"","price":52900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('H6tdCDCqIMwwbQvylXde', 'RbD1bIr6fPhQTLJEcxrM', 'SANTA CAROLINA RESERVADO', 'SAUVIGNON BLANC (Blanco)', '[{"label":"","price":50900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('7VuVpfEDUxWiMxJcFEas', 'RbD1bIr6fPhQTLJEcxrM', 'RAMON BILBAO CRIANZA', 'TEMPRANILLO', '[{"label":"","price":68900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('fDryGjEiBt3zhl0Ny7WC', 'vinos-y-bebidas', 'fI6yHWzb4FjTaksMXDw4', 'sangrias', 'SANGRÍAS', '', null, 'list', 9);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('jfusDC8KAun5ZE0qQNw7', 'fDryGjEiBt3zhl0Ny7WC', 'DELLA CASA (TINTO, BLANCO, ROSÉ)', '', '[{"label":"","price":100900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('JEXItFhdIf56vdDOuddu', 'fDryGjEiBt3zhl0Ny7WC', 'LAMBRUSCO ( TINTO, BLANCO, ROSÉ)', '', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, 1.5);


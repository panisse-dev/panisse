-- ══════════════════════════════════════════════════════════════════
-- Carta de Roka (sede Pilares del Bosque) + columna de sede en menús.
-- Roka es una marca aparte que convive con Panisse en Pilares. Se
-- agrega menus.locations (text[]): null = todas las sedes; para Roka,
-- {pilares}. No se toca ningún dato de Panisse.
-- Generado desde scratchpad/roka-data.json (build-roka.mjs).
-- ══════════════════════════════════════════════════════════════════

alter table public.menus add column if not exists locations text[];

-- ── Menú ROKA ──
insert into public.menus (slug, label, tagline, name, sort, locations)
values ('roka-carta', 'Carta Roka', 'Cocina nikkei, peruana y parrilla', 'ROKA', 5, array['pilares']);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-entradas', 'roka-carta', null, 'entradas', 'Entradas', '', null, 'list', 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-nikkei', 'roka-carta', 'roka-carta-entradas', 'nikkei', 'Nikkei', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-nikkei-p1', 'roka-carta-nikkei', 'Langostinos al fuego', 'Sellados a la parrilla con mantequilla asiática, jengibre, togarashi y limón.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, true, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-nikkei-p2', 'roka-carta-nikkei', 'Tacos Nikkei', 'Mayo spicy, nori crocante, arroz de sushi, queso crema, aguacate y camarones. (Ligeramente picante)', '[{"label":"","price":30900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-nikkei-p3', 'roka-carta-nikkei', 'Kanikama Crispy', 'Palmitos crocantes, queso crema, teriyaki, mayo asiática (dulce) y grana padano.', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-ceviches', 'roka-carta', 'roka-carta-entradas', 'ceviches', 'Ceviches', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-ceviches-p1', 'roka-carta-ceviches', 'Ceviche Nikkei', 'Pulpo, camarón, tilapia, arroz de sushi y leche de tigre de ají amarillo ahumado.', '[{"label":"","price":47900,"discounted":null}]'::jsonb, false, null, true, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-ceviches-p2', 'roka-carta-ceviches', 'Cremoso Inca', 'Pescado blanco, leche de tigre de ají amarillo y maíz chulpi.', '[{"label":"","price":33900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-ceviches-p3', 'roka-carta-ceviches', 'Clásico Peruano', 'Pesca blanca, leche de tigre y maíz chulpi.', '[{"label":"","price":30000,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-peru', 'roka-carta', 'roka-carta-entradas', 'peru', 'Perú', '', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-peru-p1', 'roka-carta-peru', 'Pulpo al Fuego', 'Pulpo, papas nativas crocantes y chimichurri nikkei.', '[{"label":"","price":60900,"discounted":null}]'::jsonb, false, null, true, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-peru-p2', 'roka-carta-peru', 'Anticuchos', 'Brochetas de lomo a la parrilla, ají panca, papa amarilla y mayonesa peruana.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-grill', 'roka-carta', 'roka-carta-entradas', 'grill', 'Grill', '', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-grill-p1', 'roka-carta-grill', 'Chorizos al fuego', 'Chorizos de la casa, papas nativas crocantes y chimichurri asiático.', '[{"label":"","price":28900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-grill-p2', 'roka-carta-grill', 'Queso de la casa', 'Queso semiduro en miel de maracuyá.', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-grill-p3', 'roka-carta-grill', 'Panceta de cerdo', 'Chicharrones tradicionales con salsa teriyaki cítrica.', '[{"label":"","price":25000,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-grill-p4', 'roka-carta-grill', 'Chinchulines', 'Chinchulín crujiente de res.', '[{"label":"","price":30900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-sopas', 'roka-carta', 'roka-carta-entradas', 'sopas', 'Sopas', '', null, 'list', 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-sopas-p1', 'roka-carta-sopas', 'Coco Thai', 'Sopa tailandesa a base de coco, vegetales al wok, pollo, aromatizada con albahaca y naranja. Recomendado: adicional de camarones.', '[{"label":"","price":25000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-menu-principal', 'roka-carta', null, 'menu-principal', 'Menú Principal', '', null, 'list', 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-pescados-y-mariscos', 'roka-carta', 'roka-carta-menu-principal', 'pescados-y-mariscos', 'Pescados y Mariscos', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-pescados-y-mariscos-p1', 'roka-carta-pescados-y-mariscos', 'Camarones Shuga', 'Camarones tempura, mayonesa dulce asiática y arroz al wok.', '[{"label":"","price":42900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-pescados-y-mariscos-p2', 'roka-carta-pescados-y-mariscos', 'Camarones Dinamita', 'Camarones crocantes, salsa mayo picante y arroz al wok.', '[{"label":"","price":42900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-pescados-y-mariscos-p3', 'roka-carta-pescados-y-mariscos', 'Salmón Maracu-Tao', 'Filete de salmón, miel de maracuyá, vegetales al wok y puré de papa.', '[{"label":"","price":56900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-pescados-y-mariscos-p4', 'roka-carta-pescados-y-mariscos', 'Salmón Nikkei', 'Filete de salmón, reducción cítrica de teriyaki, vegetales al wok y puré de papa.', '[{"label":"","price":56900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-aves', 'roka-carta', 'roka-carta-menu-principal', 'aves', 'Aves', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-aves-p1', 'roka-carta-aves', 'Pollo Sweet Chilli', 'Suprema de pollo envuelta en tocineta, salsa agridulce asiática ligeramente picante y puré de papa.', '[{"label":"","price":47900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-carnes', 'roka-carta', 'roka-carta-menu-principal', 'carnes', 'Carnes', '', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-carnes-p1', 'roka-carta-carnes', 'Lomo trufado', 'Solomo a la parrilla, salsa agridulce trufada, gyoza crocante y puré al miso.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, null, true, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-carnes-p2', 'roka-carta-carnes', 'Ramen al wok', 'Fideos al wok en mantequilla de togarashi, solomo de res sellado a la parrilla, finalizado con grana padano y cebollín.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, null, true, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-carnes-p3', 'roka-carta-carnes', 'Costillas estilo Mandarín', 'Costilla de cerdo glaseada en reducción cítrica de teriyaki y puré de papa.', '[{"label":"","price":49900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-carnes-p4', 'roka-carta-carnes', 'Lomo saltado', 'Solomo al wok con vegetales y papas nativas, acompañado con arroz blanco.', '[{"label":"","price":48900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-carnes-p5', 'roka-carta-carnes', 'Cerdo Robatayaki', 'Cerdo albardado en tocineta, salsa asiática cítrica, queso crema y puré de papa.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-arroces-y-cremosos', 'roka-carta', null, 'arroces-y-cremosos', 'Arroces y Cremosos', '', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-arroces-y-cremosos-p1', 'roka-carta-arroces-y-cremosos', 'Arroz Niku', 'Lomo a la parrilla, camarones, gyoza crocante sobre arroz cremoso de coco, champiñones y espárragos.', '[{"label":"","price":62900,"discounted":null}]'::jsonb, false, null, true, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-arroces-y-cremosos-p2', 'roka-carta-arroces-y-cremosos', 'Arroz Yakimeshi', 'Cerdo glaseado en salsa teriyaki, camarones, arroz frito al wok, mix asiático y topping de queso crema.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-arroces-y-cremosos-p3', 'roka-carta-arroces-y-cremosos', 'Cremoso de Entrañita', 'Láminas de entraña a la parrilla y arroz cremoso con setas.', '[{"label":"","price":48900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-arroces-y-cremosos-p4', 'roka-carta-arroces-y-cremosos', 'Cremoso de Mariscos', 'Arroz cremoso de mariscos con ajíes peruanos, terminado con ensaladilla acevichada y edamames.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-arroces-y-cremosos-p5', 'roka-carta-arroces-y-cremosos', 'Cremoso Limeño', 'Lomo saltado peruano y arroz cremoso con toques de ají amarillo.', '[{"label":"","price":56900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-premium-pokes', 'roka-carta', null, 'premium-pokes', 'Premium Pokes', '', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-premium-pokes-p1', 'roka-carta-premium-pokes', 'Mayo Shrimp', 'Camarones crispy, mayo asiática (dulce), aguacate, pepino, zanahoria, repollo kimchi, semillas de sésamo, base de shari (arroz de sushi).', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-premium-pokes-p2', 'roka-carta-premium-pokes', 'Spicy Shrimp', 'Camarones crispy, spicy mayo (picante), aguacate, pepino, zanahoria, repollo kimchi, semillas de sésamo, base de shari (arroz de sushi).', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-menu-infantil', 'roka-carta', null, 'menu-infantil', 'Menú Infantil', '', null, 'list', 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-menu-infantil-p1', 'roka-carta-menu-infantil', 'Tornados de Pollo', 'Tenders de pollo crujientes en panko y papas a la francesa.', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-grill-2', 'roka-carta', null, 'grill-2', 'Grill', 'Todos nuestros cortes son madurados y empacados al vacío. Acompañados con ensalada nikkei y papas de la casa, francesas o sour.', null, 'list', 5);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-cortes-tradicionales', 'roka-carta', 'roka-carta-grill-2', 'cortes-tradicionales', 'Cortes Tradicionales', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-tradicionales-p1', 'roka-carta-cortes-tradicionales', 'Pechuga a las brasas', 'Jugoso filete de pechuga a la parrilla.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-tradicionales-p2', 'roka-carta-cortes-tradicionales', 'Churrasco', '400 gr de filete de lomo ancho de res asado a la parrilla, caracterizado por su capa de grasa en los costados que potencia su sabor y presentación.', '[{"label":"","price":57900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-tradicionales-p3', 'roka-carta-cortes-tradicionales', 'Bife chorizo', '400 gr de chata de res, con grasa en la parte superior de excelente sabor.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-tradicionales-p4', 'roka-carta-cortes-tradicionales', 'Punta de anca', '400 gr de corte del cuarto trasero de la res, con recubrimiento externo de grasa, de textura firme y jugosa.', '[{"label":"","price":59900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-tradicionales-p5', 'roka-carta-cortes-tradicionales', 'Baby beef', '400 gr de corte magro de solomillo de res, de inigualable terneza.', '[{"label":"","price":60900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-tradicionales-p6', 'roka-carta-cortes-tradicionales', 'Filet mignon', 'Medallones de solomito de res, envuelto en tocineta y terminado con champiñones a la parrilla.', '[{"label":"","price":62900,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-cortes-exclusivos', 'roka-carta', 'roka-carta-grill-2', 'cortes-exclusivos', 'Cortes Exclusivos', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-exclusivos-p1', 'roka-carta-cortes-exclusivos', 'Ribeye', '400 gr del corte superior de la res, tierno y jugoso.', '[{"label":"","price":57900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-exclusivos-p2', 'roka-carta-cortes-exclusivos', 'Chateaubriand', '400 gr de solomillo, sin exceso de grasa y de muy buena textura.', '[{"label":"","price":64900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-cortes-certified-angus-beef', 'roka-carta', 'roka-carta-grill-2', 'cortes-certified-angus-beef', 'Cortes Certified Angus Beef', 'Los cortes de la marca Certified Angus Beef® son de la más alta calidad, con excelente marmoleo y sabor. Acompañados con ensalada y papas de la casa.', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-certified-angus-beef-p1', 'roka-carta-cortes-certified-angus-beef', 'Asado de Tira Certified Angus Beef', 'Corte con mayor marmoleo, suave y jugoso, seleccionado de la mejor parte de la costilla de res.', '[{"label":"","price":110900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-certified-angus-beef-p2', 'roka-carta-cortes-certified-angus-beef', 'Picanha Certified Angus Beef', 'Perfecta punta de anca con terneza garantizada.', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-cortes-certified-angus-beef-p3', 'roka-carta-cortes-certified-angus-beef', 'New York Certified Angus Beef', 'Lomo angosto con un poco de grasa subcutánea que ayuda a aumentar su sabor y jugosidad, terneza garantizada.', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-carta-hamburguesas', 'roka-carta', 'roka-carta-grill-2', 'hamburguesas', 'Hamburguesas', 'Todas nuestras hamburguesas vienen acompañadas con papas de la casa.', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-carta-hamburguesas-p1', 'roka-carta-hamburguesas', 'Hamburguesa de la casa', 'Pan brioche artesanal, carne 100% Certified Angus Beef, mermelada de tocineta, mozzarella y vegetales.', '[{"label":"","price":48900,"discounted":null}]'::jsonb, false, null, false, false, 1);

-- ── Menú VINOS Y BEBIDAS ──
insert into public.menus (slug, label, tagline, name, sort, locations)
values ('roka-bebidas', 'Vinos y Bebidas Roka', 'Vinos, cócteles y más', 'VINOS Y BEBIDAS', 6, array['pilares']);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-vinos', 'roka-bebidas', null, 'vinos', 'Vinos', '', null, 'list', 0);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-por-copas', 'roka-bebidas', 'roka-bebidas-vinos', 'por-copas', 'Por Copas', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-por-copas-p1', 'roka-bebidas-por-copas', 'Copa', 'Tinto, blanco o rosé.', '[{"label":"","price":22900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-por-copas-p2', 'roka-bebidas-por-copas', 'Santa Carolina Reservado', 'Sauvignon Blanc – Merlot · Carménère.', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-por-copas-p3', 'roka-bebidas-por-copas', 'Tinto de verano', '', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-por-copas-p4', 'roka-bebidas-por-copas', 'Blanco de verano', '', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-por-copas-p5', 'roka-bebidas-por-copas', 'Vino caliente', '', '[{"label":"","price":24900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-por-copas-p6', 'roka-bebidas-por-copas', 'Sangría', '', '[{"label":"","price":26900,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-de-la-casa', 'roka-bebidas', 'roka-bebidas-vinos', 'de-la-casa', 'De la Casa', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-de-la-casa-p1', 'roka-bebidas-de-la-casa', 'Santa Carolina Reservado', 'Sauvignon Blanc – Rosado · Carménère.', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-espumantes', 'roka-bebidas', 'roka-bebidas-vinos', 'espumantes', 'Espumantes', '', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-espumantes-p1', 'roka-bebidas-espumantes', 'Piccini Regno Lambrusco', 'Blanco – Rosado · Tinto.', '[{"label":"","price":99900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-espumantes-p2', 'roka-bebidas-espumantes', 'Chandon Garden Spritz', '', '[{"label":"","price":159700,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-espumantes-p3', 'roka-bebidas-espumantes', 'Chandon Extra Brut', '', '[{"label":"","price":120000,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-espumantes-p4', 'roka-bebidas-espumantes', 'Chandon Brut Rosé', '', '[{"label":"","price":135000,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-espumantes-p5', 'roka-bebidas-espumantes', 'Mionetto Prosecco', '', '[{"label":"","price":119900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-espumantes-p6', 'roka-bebidas-espumantes', 'Veuve Clicquot Brut DO Champagne', '', '[{"label":"Botella","price":900000,"discounted":null},{"label":"Media botella","price":499000,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-blancos', 'roka-bebidas', 'roka-bebidas-vinos', 'blancos', 'Blancos', '', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p1', 'roka-bebidas-blancos', 'Mar de Frades', '', '[{"label":"","price":189900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p2', 'roka-bebidas-blancos', 'Enate', 'Chardonnay.', '[{"label":"","price":169900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p3', 'roka-bebidas-blancos', 'Santa Carolina Reservado', 'Sauvignon Blanc.', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p4', 'roka-bebidas-blancos', 'Muga Reserva', 'Viura.', '[{"label":"","price":149000,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p5', 'roka-bebidas-blancos', 'Mara Martín', 'Godello.', '[{"label":"","price":124900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p6', 'roka-bebidas-blancos', 'Ramón Bilbao', 'Verdejo.', '[{"label":"","price":129900,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p7', 'roka-bebidas-blancos', 'Marqués del Riscal', 'Verdejo.', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p8', 'roka-bebidas-blancos', 'Finca las Moras', 'Chardonnay.', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 8);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p9', 'roka-bebidas-blancos', 'Michel Torino', 'Torrontés.', '[{"label":"","price":93000,"discounted":null}]'::jsonb, false, null, false, false, 9);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-blancos-p10', 'roka-bebidas-blancos', 'Piccini Memoro', 'Chardonnay / Vermentino.', '[{"label":"","price":92900,"discounted":null}]'::jsonb, false, null, false, false, 10);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-rosados', 'roka-bebidas', 'roka-bebidas-vinos', 'rosados', 'Rosados', '', null, 'list', 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-rosados-p1', 'roka-bebidas-rosados', 'Ramón Bilbao', 'Garnacha.', '[{"label":"","price":139900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-rosados-p2', 'roka-bebidas-rosados', 'Santa Carolina Reservado', 'Cabernet Sauvignon.', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-rosados-p3', 'roka-bebidas-rosados', 'Enate', 'Cabernet Sauvignon.', '[{"label":"","price":169900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-rosados-p4', 'roka-bebidas-rosados', 'Finca La Celia', 'Malbec.', '[{"label":"","price":125900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-rosados-p5', 'roka-bebidas-rosados', 'JP Chenet', 'Cabernet Sauvignon.', '[{"label":"","price":103900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-rosados-p6', 'roka-bebidas-rosados', 'Michel Torino', 'Malbec.', '[{"label":"","price":93000,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-rosados-p7', 'roka-bebidas-rosados', 'Piccini Memoro', 'Negroamaro / Nero d''Avola.', '[{"label":"","price":92900,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-rosados-p8', 'roka-bebidas-rosados', 'Viña Tarapacá', 'Cabernet Sauvignon.', '[{"label":"","price":85900,"discounted":null}]'::jsonb, false, null, false, false, 8);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-tintos', 'roka-bebidas', 'roka-bebidas-vinos', 'tintos', 'Tintos', '', null, 'list', 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p1', 'roka-bebidas-tintos', 'Marqués de Vargas Reserva', 'Tempranillo.', '[{"label":"","price":239000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p2', 'roka-bebidas-tintos', 'Marqués del Riscal Reserva', 'Tempranillo.', '[{"label":"","price":219000,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p3', 'roka-bebidas-tintos', 'Marqués de Arienzo Crianza', 'Tempranillo.', '[{"label":"","price":175900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p4', 'roka-bebidas-tintos', 'Enate', 'Cabernet Sauvignon – Merlot.', '[{"label":"","price":159900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p5', 'roka-bebidas-tintos', 'Enate Cabernet Sauvignon', 'Tempranillo.', '[{"label":"","price":159900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p6', 'roka-bebidas-tintos', 'Beronia Crianza', 'Tempranillo.', '[{"label":"","price":174900,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p7', 'roka-bebidas-tintos', 'Norton DOC', 'Malbec.', '[{"label":"","price":170900,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p8', 'roka-bebidas-tintos', 'Protos Roble', 'Tempranillo.', '[{"label":"","price":166900,"discounted":null}]'::jsonb, false, null, false, false, 8);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p9', 'roka-bebidas-tintos', 'Ruffino', 'Sangiovese.', '[{"label":"","price":175900,"discounted":null}]'::jsonb, false, null, false, false, 9);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p10', 'roka-bebidas-tintos', 'Pasqua Lapacio Primitivo de Salento', 'Primitivo.', '[{"label":"","price":146900,"discounted":null}]'::jsonb, false, null, false, false, 10);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p11', 'roka-bebidas-tintos', 'Riscal DO Castilla', 'Tempranillo.', '[{"label":"","price":136900,"discounted":null}]'::jsonb, false, null, false, false, 11);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p12', 'roka-bebidas-tintos', 'Morandé Pionero Reserva', 'Merlot.', '[{"label":"","price":134900,"discounted":null}]'::jsonb, false, null, false, false, 12);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p13', 'roka-bebidas-tintos', 'Santa Rita 120 Reserva Especial', 'Carménère.', '[{"label":"","price":132900,"discounted":null}]'::jsonb, false, null, false, false, 13);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p14', 'roka-bebidas-tintos', 'Trapiche Reserva (Syrah)', 'Syrah.', '[{"label":"","price":129900,"discounted":null}]'::jsonb, false, null, false, false, 14);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p15', 'roka-bebidas-tintos', 'La Celia Reserva', 'Malbec.', '[{"label":"","price":109900,"discounted":null}]'::jsonb, false, null, false, false, 15);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p16', 'roka-bebidas-tintos', 'Pasqua Montepulciano d''Abruzzo', 'Montepulciano.', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, 16);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p17', 'roka-bebidas-tintos', 'Finca las Moras', 'Bonarda.', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 17);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p18', 'roka-bebidas-tintos', 'Ramón Bilbao Crianza', 'Tempranillo.', '[{"label":"","price":129900,"discounted":null}]'::jsonb, false, null, false, false, 18);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p19', 'roka-bebidas-tintos', 'Santa Carolina Reservado (Cabernet Sauvignon)', 'Cabernet Sauvignon.', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 19);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p20', 'roka-bebidas-tintos', 'Santa Carolina Reservado (Merlot)', 'Merlot.', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 20);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p21', 'roka-bebidas-tintos', 'Santa Carolina Reservado (Carménère)', 'Carménère.', '[{"label":"","price":86900,"discounted":null}]'::jsonb, false, null, false, false, 21);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-tintos-p22', 'roka-bebidas-tintos', 'Trapiche Reserva (Cabernet Sauvignon)', 'Cabernet Sauvignon.', '[{"label":"","price":109900,"discounted":null}]'::jsonb, false, null, false, false, 22);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-generosos', 'roka-bebidas', 'roka-bebidas-vinos', 'generosos', 'Generosos', '', null, 'list', 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-generosos-p1', 'roka-bebidas-generosos', 'Jerez Español Tío Pepe (Copa)', '', '[{"label":"","price":28900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-generosos-p2', 'roka-bebidas-generosos', 'Jerez Español Elegante Amontillado - Medium Dry (Copa)', '', '[{"label":"","price":21900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-postres-cosecha-tardia', 'roka-bebidas', 'roka-bebidas-vinos', 'postres-cosecha-tardia', 'Postres · Cosecha Tardía', '', null, 'list', 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-postres-cosecha-tardia-p1', 'roka-bebidas-postres-cosecha-tardia', 'Morandé Late Harvest', 'Sauvignon Blanc (media botella).', '[{"label":"","price":79900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-medias-botellas', 'roka-bebidas', 'roka-bebidas-vinos', 'medias-botellas', 'Medias Botellas', '', null, 'list', 8);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-medias-botellas-p1', 'roka-bebidas-medias-botellas', 'Riscal Tempranillo', 'Syrah (tinto).', '[{"label":"","price":69900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-medias-botellas-p2', 'roka-bebidas-medias-botellas', 'Santa Carolina Reservado', 'Cabernet Sauvignon (tinto).', '[{"label":"","price":52900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-medias-botellas-p3', 'roka-bebidas-medias-botellas', 'Santa Carolina Reservado', 'Sauvignon Blanc (blanco).', '[{"label":"","price":50900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-medias-botellas-p4', 'roka-bebidas-medias-botellas', 'Ramón Bilbao Crianza', 'Tempranillo.', '[{"label":"","price":68900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-sangrias', 'roka-bebidas', 'roka-bebidas-vinos', 'sangrias', 'Sangrías', '', null, 'list', 9);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-sangrias-p1', 'roka-bebidas-sangrias', 'Della Casa', 'Tinto, blanco o rosé (botella).', '[{"label":"","price":100900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-sangrias-p2', 'roka-bebidas-sangrias', 'Lambrusco', 'Tinto, blanco o rosé (botella).', '[{"label":"","price":120900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-cocteles', 'roka-bebidas', null, 'cocteles', 'Cócteles', '', null, 'list', 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-signature-cocktails', 'roka-bebidas', 'roka-bebidas-cocteles', 'signature-cocktails', 'Signature Cocktails', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-signature-cocktails-p1', 'roka-bebidas-signature-cocktails', 'Akai Rubí', 'Pisco Tabernero Quebranta, licor de maracuyá, miel de agave, albahaca, mora y limón.', '[{"label":"","price":40900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-signature-cocktails-p2', 'roka-bebidas-signature-cocktails', 'Taru', 'Jack Daniel''s Old 7, vodka, pimienta, anís, vainilla, zumo de piña y romero.', '[{"label":"","price":40000,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-signature-cocktails-p3', 'roka-bebidas-signature-cocktails', 'Samurái', 'Vodka Belvedere, Jägermeister, tamarindo, Martini Vermouth Dry y hierbabuena.', '[{"label":"","price":46000,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-signature-cocktails-p4', 'roka-bebidas-signature-cocktails', 'Bayas del Bosque', 'Ron blanco, bayas de goji, espuma de limón, ron Cacique añejo y crema de casis.', '[{"label":"","price":36000,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-signature-cocktails-p5', 'roka-bebidas-signature-cocktails', 'Tsuki', 'Tequila, mezcal 400 Conejos, hoja de coca, pimienta negra, limonaria y espuma de limón.', '[{"label":"","price":38000,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-signature-cocktails-p6', 'roka-bebidas-signature-cocktails', 'Oishi', 'Jägermeister, gin, maracuyá, licor de naranja y arándanos, hierbabuena.', '[{"label":"","price":38000,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-signature-cocktails-p7', 'roka-bebidas-signature-cocktails', 'Osaka', 'Mezcal 400 Conejos, ron Sailor Jerry, piña, horchata y hierbabuena.', '[{"label":"","price":42000,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-classic-cocktails', 'roka-bebidas', 'roka-bebidas-cocteles', 'classic-cocktails', 'Classic Cocktails', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p1', 'roka-bebidas-classic-cocktails', 'Moscow Mule', 'Vodka, jengibre, hierbabuena y ginger beer Mil 976.', '[{"label":"","price":38000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p2', 'roka-bebidas-classic-cocktails', 'Old Fashioned', 'Jack Daniel''s Old No. 7, azúcar y piel de naranja.', '[{"label":"","price":38000,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p3', 'roka-bebidas-classic-cocktails', 'Martini', 'Gin, Martini blanco y aceitunas verdes.', '[{"label":"","price":36000,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p4', 'roka-bebidas-classic-cocktails', 'Piña Colada', 'Ron Bacardi Carta Blanca, piña y coco.', '[{"label":"","price":32000,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p5', 'roka-bebidas-classic-cocktails', 'Pisco Sour', 'Pisco Tabernero La Botija Quebranta.', '[{"label":"","price":34000,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p6', 'roka-bebidas-classic-cocktails', 'Margarita', 'Tequila Gran Centenario Reposado.', '[{"label":"","price":40000,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p7', 'roka-bebidas-classic-cocktails', 'Penicillin', 'Jack Daniel''s Old No. 7, Johnnie Walker Double Black, jengibre y limón.', '[{"label":"","price":36000,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p8', 'roka-bebidas-classic-cocktails', 'Caipi de la casa', 'Vodka, moras, limón, maracuyá y hierbabuena.', '[{"label":"","price":30000,"discounted":null}]'::jsonb, false, null, false, false, 8);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p9', 'roka-bebidas-classic-cocktails', 'Mai Tai de la casa', 'Ron Viejo de Caldas Roble Blanco, ron Sailor Jerry, horchata, hierbabuena y piña.', '[{"label":"","price":34000,"discounted":null}]'::jsonb, false, null, false, false, 9);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p10', 'roka-bebidas-classic-cocktails', 'Pisco Sour Herbal', 'Pisco Tabernero Botija Quebranta, hoja de coca, pimienta negra y limonaria.', '[{"label":"","price":34000,"discounted":null}]'::jsonb, false, null, false, false, 10);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-classic-cocktails-p11', 'roka-bebidas-classic-cocktails', 'Martini Lychee', 'Gin, Martini Vermouth Dry y lychee.', '[{"label":"","price":38900,"discounted":null}]'::jsonb, false, null, false, false, 11);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-gin-tonic-experience', 'roka-bebidas', 'roka-bebidas-cocteles', 'gin-tonic-experience', 'Gin Tonic Experience', '', null, 'list', 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-gin-tonic-experience-p1', 'roka-bebidas-gin-tonic-experience', 'Gin Martin Citrus', 'Martin Miller''s Gin, agua tónica, mandarina y limón.', '[{"label":"","price":50000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-gin-tonic-experience-p2', 'roka-bebidas-gin-tonic-experience', 'Gin de Indias', 'Gin, tamarindo, agua tónica y hierbabuena.', '[{"label":"","price":40000,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-gin-tonic-experience-p3', 'roka-bebidas-gin-tonic-experience', 'Gin Bosque Herbal', 'Gin, hoja de coca, pimienta negra, limonaria y agua tónica.', '[{"label":"","price":38000,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-gin-tonic-experience-p4', 'roka-bebidas-gin-tonic-experience', 'Gin Hendrick''s Classic', 'Gin Hendrick''s, pepino, agua tónica y romero.', '[{"label":"","price":47000,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-mocktails-sin-alcohol', 'roka-bebidas', 'roka-bebidas-cocteles', 'mocktails-sin-alcohol', 'Mocktails (sin alcohol)', '', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-mocktails-sin-alcohol-p1', 'roka-bebidas-mocktails-sin-alcohol', 'Horchata Morada', 'Chicha morada, horchata y coco.', '[{"label":"","price":22000,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-mocktails-sin-alcohol-p2', 'roka-bebidas-mocktails-sin-alcohol', 'Mulatico', 'Pepino, mango y hierbabuena.', '[{"label":"","price":19500,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-mocktails-sin-alcohol-p3', 'roka-bebidas-mocktails-sin-alcohol', 'Virgin Mojito', 'Mora, hierbabuena y miel de agave real.', '[{"label":"","price":19500,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-cervezas', 'roka-bebidas', null, 'cervezas', 'Cervezas', '', null, 'list', 2);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-importadas', 'roka-bebidas', 'roka-bebidas-cervezas', 'importadas', 'Importadas', '', null, 'list', 0);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-importadas-p1', 'roka-bebidas-importadas', 'Corona', '', '[{"label":"","price":11900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-importadas-p2', 'roka-bebidas-importadas', 'Corona 0,0%', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-importadas-p3', 'roka-bebidas-importadas', 'Stella Artois', '', '[{"label":"","price":11900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-nacionales', 'roka-bebidas', 'roka-bebidas-cervezas', 'nacionales', 'Nacionales', '', null, 'list', 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-nacionales-p1', 'roka-bebidas-nacionales', 'Club Colombia', '', '[{"label":"","price":10400,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-sodas', 'roka-bebidas', null, 'sodas', 'Sodas', 'Base Schweppes.', null, 'list', 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-sodas-p1', 'roka-bebidas-sodas', 'Tamarindo Herbal', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-sodas-p2', 'roka-bebidas-sodas', 'Maracuyá Hierbabuena', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-sodas-p3', 'roka-bebidas-sodas', 'Limón Jengibre', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-sodas-p4', 'roka-bebidas-sodas', 'Jamaica Canela', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-sodas-p5', 'roka-bebidas-sodas', 'Lychee', '', '[{"label":"","price":12900,"discounted":null}]'::jsonb, false, null, false, false, 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-sodas-p6', 'roka-bebidas-sodas', 'Soda Michelada', '', '[{"label":"","price":8900,"discounted":null}]'::jsonb, false, null, false, false, 6);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-sodas-p7', 'roka-bebidas-sodas', 'Soda Schweppes', '', '[{"label":"","price":6000,"discounted":null}]'::jsonb, false, null, false, false, 7);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-limonadas', 'roka-bebidas', null, 'limonadas', 'Limonadas', '', null, 'list', 4);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-limonadas-p1', 'roka-bebidas-limonadas', 'Limonada de Coco', '', '[{"label":"","price":11900,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-limonadas-p2', 'roka-bebidas-limonadas', 'Limonada de Lychees', '', '[{"label":"","price":12000,"discounted":null}]'::jsonb, false, null, false, false, 2);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-limonadas-p3', 'roka-bebidas-limonadas', 'Limonada Natural', '', '[{"label":"","price":8900,"discounted":null}]'::jsonb, false, null, false, false, 3);
insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)
values ('roka-bebidas-aguas-tonicas-y-gaseosas', 'roka-bebidas', null, 'aguas-tonicas-y-gaseosas', 'Aguas, Tónicas y Gaseosas', '', null, 'list', 5);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-aguas-tonicas-y-gaseosas-p1', 'roka-bebidas-aguas-tonicas-y-gaseosas', 'Manantial', 'Agua.', '[{"label":"","price":7200,"discounted":null}]'::jsonb, false, null, false, false, 1);
insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)
values ('roka-bebidas-aguas-tonicas-y-gaseosas-p2', 'roka-bebidas-aguas-tonicas-y-gaseosas', 'Coca-Cola / Zero', '', '[{"label":"","price":6900,"discounted":null}]'::jsonb, false, null, false, false, 2);


-- ══════════════════════════════════════════════════════════════════
-- Catálogo D'Amore (Cerritos) + reglas de las decoraciones
--
-- Hasta ahora las decoraciones eran una sola lista (las de ROKA) sin
-- reglas. Ahora cada una sabe:
--   · en qué sede se ofrece (location_id; vacío = en las dos),
--   · con cuántos días de anticipación hay que pedirla (advance_days),
--   · si hay que pagarla por adelantado (prepaid).
-- Con eso, al reservar solo se ofrecen las que de verdad alcanzan a
-- prepararse para esa fecha.
-- ══════════════════════════════════════════════════════════════════

alter table public.decorations add column if not exists location_id text;
alter table public.decorations add column if not exists advance_days int not null default 0;
alter table public.decorations add column if not exists prepaid boolean not null default false;

-- Las de ROKA son de Pilares.
update public.decorations set location_id = 'pilares'
 where id in ('rose','silver','rose_cocktail','silver_cocktail');

-- ── Catálogo D'Amore (Cerritos) ──
-- Un día de anticipación y pago del 100% por adelantado.
insert into public.decorations (id, name, description, price, sort, active, image, location_id, advance_days, prepaid)
values
  ('damore_cono', 'Cono Rosa Tradicional',
   'Cono con una rosa roja natural · Tarjeta con mensaje · Postre In Love o Mini Cake Noir Chocolate',
   55000, 10, true,
   'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/8f539317-3baa-43d7-8181-0bd4ffd73e1b.jpg',
   'cerritos', 1, true),
  ('damore_globos', 'Bouquet de Globos Corazón',
   '10 globos corazón rojos con helio · Tarjeta con mensaje · Postre In Love o Mini Cake Noir Chocolate',
   100000, 11, true,
   'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/f28993a9-f23f-4c77-9fd2-fac6d8040c94.jpg',
   'cerritos', 1, true),
  ('damore_bouquet_24', 'Bouquet D''Amore · 24 rosas',
   'Bouquet de 24 rosas seleccionadas · Tarjeta con mensaje',
   120000, 12, true,
   'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/03a0a8e4-c255-4542-9045-bd4d01b296cf.jpg',
   'cerritos', 1, true),
  ('damore_bouquet_36', 'Bouquet D''Amore · 36 rosas',
   'Bouquet de 36 rosas seleccionadas · Tarjeta con mensaje',
   180000, 13, true,
   'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/03a0a8e4-c255-4542-9045-bd4d01b296cf.jpg',
   'cerritos', 1, true),
  ('damore_premium', 'Premium Love',
   'Bouquet de mesa con 60 rosas · Velas · Tarjeta con mensaje',
   250000, 14, true,
   'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/75c7bc79-18da-4e4d-8e86-9e4c120709ab.jpg',
   'cerritos', 1, true),
  ('damore_camino', 'Camino Rosso',
   'Camino de 48 rosas sobre la mesa · Velas · Tarjeta con mensaje',
   250000, 15, true,
   'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/e7b49650-9bcb-4248-a0a6-ace0c4bf2d9d.jpg',
   'cerritos', 1, true)
on conflict (id) do update set
  name = excluded.name, description = excluded.description, price = excluded.price,
  sort = excluded.sort, image = excluded.image, location_id = excluded.location_id,
  advance_days = excluded.advance_days, prepaid = excluded.prepaid;

-- ── Lo que ve el cliente: solo lo de su sede, y se le dice cuáles no
--    alcanzan para la fecha que eligió (en vez de esconderlas).
create or replace function public.public_decorations(p_location text default null, p_date date default null)
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', d.id, 'name', d.name, 'description', d.description,
    'price', d.price, 'image', d.image,
    'advanceDays', d.advance_days, 'prepaid', d.prepaid,
    'available', p_date is null or d.advance_days = 0 or
                 p_date >= ((now() at time zone 'America/Bogota')::date + d.advance_days)
  ) order by d.sort, d.name), '[]'::jsonb)
  from decorations d
  where d.active
    and (d.location_id is null or p_location is null or d.location_id = p_location);
$$;

grant execute on function public.public_decorations(text, date) to anon, authenticated;

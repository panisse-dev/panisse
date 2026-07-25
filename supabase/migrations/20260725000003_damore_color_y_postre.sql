-- ══════════════════════════════════════════════════════════════════
-- D'Amore: tono de las rosas y postre de acompañamiento
--
--  · Las decoraciones con rosas dejan elegir el tono (rojas, blancas o
--    rosadas), como en la hoja de "Rosas tradicionales" del catálogo.
--  · Las que traen postre incluido (cono y globos) dejan elegir cuál.
--    Las demás lo ofrecen como complemento por un valor adicional.
--  · Lo que elija el cliente queda guardado en su reserva y se ve en el
--    panel y en el correo.
-- ══════════════════════════════════════════════════════════════════

alter table public.decorations add column if not exists color_options text[] not null default '{}';
-- 'none' = sin postre · 'included' = va incluido y elige cuál · 'optional' = lo puede sumar
alter table public.decorations add column if not exists dessert_mode text not null default 'none';
alter table public.decorations add column if not exists dessert_price int not null default 0;

-- Los postres que se pueden elegir (con su foto del catálogo).
create table if not exists public.decoration_desserts (
  id text primary key,
  name text not null,
  image text,
  sort int not null default 0,
  active boolean not null default true
);

insert into public.decoration_desserts (id, name, image, sort) values
  ('in_love', 'Postre In Love',
   'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/4e5043aa-e407-4cb9-af56-5c266901ea65.jpg', 0),
  ('mini_cake', 'Mini Cake Noir Chocolate',
   'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/f2d1615f-1d51-484a-8005-5687f5f57f6c.jpg', 1)
on conflict (id) do update set name = excluded.name, image = excluded.image;

alter table public.decoration_desserts enable row level security;

-- ── Fotos completas (las anteriores salían recortadas) y reglas ──
update public.decorations set
  image = 'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/c29d3dc9-dd47-4e70-ae62-932a957580d9.jpg',
  color_options = array['Rojas','Blancas','Rosadas'], dessert_mode = 'included', dessert_price = 0
 where id = 'damore_cono';

update public.decorations set
  image = 'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/8062bf04-0de6-4e15-af5e-07500b3bed03.jpg',
  dessert_mode = 'included', dessert_price = 0
 where id = 'damore_globos';

update public.decorations set
  image = 'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/56a709d8-116d-445b-af39-8cf9281e3fc1.jpg',
  color_options = array['Rojas','Blancas','Rosadas'], dessert_mode = 'optional', dessert_price = 26900
 where id in ('damore_bouquet_24','damore_bouquet_36');

update public.decorations set
  image = 'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/2e11f0fd-755e-4346-8c28-8240b72955c7.jpg',
  color_options = array['Rojas','Blancas','Rosadas'], dessert_mode = 'optional', dessert_price = 26900
 where id = 'damore_premium';

update public.decorations set
  image = 'https://vaefzheeuvpzmospjiee.supabase.co/storage/v1/object/public/product-images/products/0573f03b-138f-4c8b-8bd3-eacf5817cf03.jpg',
  color_options = array['Rojas','Blancas','Rosadas'], dessert_mode = 'optional', dessert_price = 26900
 where id = 'damore_camino';

-- ── Lo que ve el cliente ──
create or replace function public.public_decorations(p_location text default null, p_date date default null)
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', d.id, 'name', d.name, 'description', d.description,
    'price', d.price, 'image', d.image,
    'advanceDays', d.advance_days, 'prepaid', d.prepaid,
    'colorOptions', to_jsonb(d.color_options),
    'dessertMode', d.dessert_mode, 'dessertPrice', d.dessert_price,
    'available', p_date is null or d.advance_days = 0 or
                 p_date >= ((now() at time zone 'America/Bogota')::date + d.advance_days)
  ) order by d.sort, d.name), '[]'::jsonb)
  from decorations d
  where d.active
    and (d.location_id is null or p_location is null or d.location_id = p_location);
$$;

create or replace function public.public_decoration_desserts()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', x.id, 'name', x.name, 'image', x.image)
                            order by x.sort), '[]'::jsonb)
  from decoration_desserts x where x.active;
$$;

-- ── Guardar la elección completa en la reserva ──
create or replace function public.reservation_set_decoration(
  p_id uuid, p_decoration_id text, p jsonb default '{}'::jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_dec decorations%rowtype;
  v_color text := nullif(btrim(coalesce(p->>'color','')), '');
  v_dessert text := nullif(btrim(coalesce(p->>'dessert','')), '');
  v_dessert_name text;
  v_message text := nullif(left(btrim(coalesce(p->>'message','')), 200), '');
  v_total int;
begin
  if coalesce(p_decoration_id, '') = '' then
    update reservations set decoration = null where id = p_id;
    return;
  end if;
  select * into v_dec from decorations where id = p_decoration_id and active;
  if not found then
    raise exception 'Esa decoración no está disponible';
  end if;

  -- El tono solo se guarda si esa decoración lo ofrece.
  if v_color is not null and not (v_color = any(v_dec.color_options)) then
    v_color := null;
  end if;

  if v_dessert is not null and v_dec.dessert_mode <> 'none' then
    select name into v_dessert_name from decoration_desserts where id = v_dessert and active;
  end if;

  v_total := v_dec.price +
    case when v_dessert_name is not null and v_dec.dessert_mode = 'optional'
         then v_dec.dessert_price else 0 end;

  update reservations set decoration = jsonb_strip_nulls(jsonb_build_object(
    'id', v_dec.id, 'name', v_dec.name, 'description', v_dec.description,
    'price', v_dec.price, 'image', v_dec.image,
    'color', v_color,
    'dessert', v_dessert_name,
    'dessertPrice', case when v_dessert_name is not null and v_dec.dessert_mode = 'optional'
                         then v_dec.dessert_price else null end,
    'message', v_message,
    'total', v_total
  )) where id = p_id;
end
$$;

grant execute on function public.public_decoration_desserts() to anon, authenticated;
grant execute on function public.reservation_set_decoration(uuid, text, jsonb) to anon, authenticated;

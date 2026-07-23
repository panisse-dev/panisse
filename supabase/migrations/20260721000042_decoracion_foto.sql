-- Cada decoración puede tener su foto, para que el cliente vea cómo se ve
-- antes de elegirla. La foto se sube desde el panel (igual que los platos).

alter table public.decorations add column if not exists image text;

create or replace function public.public_decorations()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', d.id, 'name', d.name, 'description', d.description,
    'price', d.price, 'image', d.image
  ) order by d.sort), '[]'::jsonb)
  from decorations d where d.active;
$$;

create or replace function public.staff_decorations(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', d.id, 'name', d.name, 'description', d.description,
      'price', d.price, 'active', d.active, 'image', d.image
    ) order by d.sort)
    from decorations d
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_update_decoration(p_code text, p_id text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update decorations set
    name = case when p ? 'name' then left(btrim(p->>'name'), 60) else name end,
    description = case when p ? 'description' then left(btrim(p->>'description'), 200) else description end,
    price = case when p ? 'price' then greatest(0, (p->>'price')::int) else price end,
    active = case when p ? 'active' then (p->>'active')::boolean else active end,
    image = case when p ? 'image' then nullif(btrim(p->>'image'), '') else image end
  where id = p_id;
  if not found then raise exception 'Decoración no encontrada'; end if;
end
$$;

-- La reserva guarda también la foto, para verla en el panel y en la ficha.
create or replace function public.reservation_set_decoration(p_id uuid, p_decoration_id text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_dec decorations%rowtype;
begin
  if coalesce(p_decoration_id, '') = '' then
    update reservations set decoration = null where id = p_id;
    return;
  end if;
  select * into v_dec from decorations where id = p_decoration_id and active;
  if not found then
    raise exception 'Esa decoración no está disponible';
  end if;
  update reservations set decoration = jsonb_build_object(
    'id', v_dec.id, 'name', v_dec.name, 'description', v_dec.description,
    'price', v_dec.price, 'image', v_dec.image
  ) where id = p_id;
end
$$;

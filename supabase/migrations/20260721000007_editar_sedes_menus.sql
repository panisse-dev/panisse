-- Editar desde el panel: los datos de cada sede (nombre, dirección, teléfono,
-- WhatsApp) y los títulos de los menús (Brunch / Lunch y Dinner / Vinos).

-- ── Sedes (lectura para el panel, con todos los campos) ──
create or replace function public.staff_locations(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', l.id, 'name', l.name, 'address', l.address,
      'phone', l.phone, 'whatsapp', l.whatsapp, 'active', l.active
    ) order by l.sort)
    from locations l
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_update_location(p_code text, p_id text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update locations set
    name = case when p ? 'name' then left(btrim(p->>'name'), 80) else name end,
    address = case when p ? 'address' then left(btrim(p->>'address'), 200) else address end,
    phone = case when p ? 'phone' then left(btrim(p->>'phone'), 40) else phone end,
    whatsapp = case when p ? 'whatsapp' then left(btrim(p->>'whatsapp'), 40) else whatsapp end,
    active = case when p ? 'active' then (p->>'active')::boolean else active end
  where id = p_id;
  if not found then raise exception 'Sede no encontrada'; end if;
end
$$;

-- ── Menús (títulos) ──
create or replace function public.staff_menus(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'slug', m.slug, 'label', m.label, 'tagline', m.tagline, 'name', m.name
    ) order by m.sort)
    from menus m
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_update_menu(p_code text, p_slug text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  update menus set
    label = case when p ? 'label' then left(btrim(p->>'label'), 60) else label end,
    tagline = case when p ? 'tagline' then left(btrim(p->>'tagline'), 120) else tagline end,
    name = case when p ? 'name' then left(btrim(p->>'name'), 80) else name end
  where slug = p_slug;
  if not found then raise exception 'Menú no encontrado'; end if;
end
$$;

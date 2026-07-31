-- ══════════════════════════════════════════════════════════════════
-- Las decoraciones del panel, filtradas por sede.
--
-- El catálogo D'Amore es solo de Cerritos (decorations.location_id),
-- y la carta que ve el cliente ya lo respetaba. El panel no: traía
-- todas, así que en Pilares del Bosque salían las de Cerritos.
--
-- Regla: una decoración sin sede se ofrece en todas; una con sede solo
-- en la suya. Quien administra una sola sede ve únicamente las de ella;
-- la administración general las ve todas y ahora sabe de cuál es cada
-- una (locationId).
--
-- De paso se cierra el hueco de edición: sin esto, quien administra
-- Pilares podía cambiarle el precio a una decoración de Cerritos.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_decorations(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
declare v_loc text;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', d.id, 'name', d.name, 'description', d.description,
      'price', d.price, 'active', d.active, 'image', d.image,
      'locationId', d.location_id
    ) order by d.sort)
    from decorations d
    where v_loc is null or d.location_id is null or d.location_id = v_loc
  ), '[]'::jsonb);
end
$$;

create or replace function public.staff_update_decoration(p_code text, p_id text, p jsonb)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_loc text;
  v_dec_loc text;
  v_found boolean;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);

  select location_id, true into v_dec_loc, v_found from decorations where id = p_id;
  if not v_found then raise exception 'Decoración no encontrada'; end if;

  -- Quien administra una sede no toca las decoraciones de otra.
  if v_loc is not null and v_dec_loc is not null and v_dec_loc <> v_loc then
    raise exception 'Esa decoración es de otra sede' using errcode = '42501';
  end if;

  update decorations set
    name = case when p ? 'name' then left(btrim(p->>'name'), 60) else name end,
    description = case when p ? 'description' then left(btrim(p->>'description'), 200) else description end,
    price = case when p ? 'price' then greatest(0, (p->>'price')::int) else price end,
    active = case when p ? 'active' then (p->>'active')::boolean else active end,
    image = case when p ? 'image' then nullif(btrim(p->>'image'), '') else image end
  where id = p_id;
end
$$;

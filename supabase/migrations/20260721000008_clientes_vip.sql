-- ══════════════════════════════════════════════════════════════════
-- Clientes: VIP, lista negra y "recurrente"
--
-- Replica la sección Usuarios de Precompro (VIP / Lista negra / clientes
-- que repiten). Todo se apoya en la tabla `clients` que ya existe y que
-- se llena sola con pedidos y reservas. Sólo agregamos dos marcas y el
-- conteo de reservas para saber quién repite. Aditivo: nada de lo que ya
-- funciona cambia.
-- ══════════════════════════════════════════════════════════════════

alter table public.clients
  add column if not exists vip boolean not null default false,
  add column if not exists blacklisted boolean not null default false;

create index if not exists clients_vip_idx on public.clients (vip) where vip;
create index if not exists clients_blacklisted_idx on public.clients (blacklisted) where blacklisted;

-- ── Lista de clientes con marcas + actividad (pedidos y reservas) ──
-- Un cliente es "recurrente" si tiene 2 o más visitas entre pedidos y
-- reservas efectivas (cumplidas/confirmadas). Eso lo calcula la pantalla.
create or replace function public.staff_clients(p_code text)
returns jsonb
language plpgsql stable
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'phone', c.phone,
      'email', c.email,
      'birthday', c.birthday,
      'notes', c.notes,
      'vip', c.vip,
      'blacklisted', c.blacklisted,
      'createdAt', c.created_at,
      'lastActivityAt', c.last_activity_at,
      'ordersCount', (select count(*) from orders o where o.client_id = c.id),
      'totalSpent', (select coalesce(sum(o.total),0) from orders o where o.client_id = c.id),
      'lastOrderAt', (select max(o.created_at) from orders o where o.client_id = c.id),
      'reservationsCount', (
        select count(*) from reservations r
        where r.client_id = c.id and r.status in ('confirmada','cumplida')
      ),
      'lastReservationAt', (
        select max(r.reserved_date) from reservations r where r.client_id = c.id
      )
    ) order by c.vip desc, c.last_activity_at desc)
    from clients c
  ), '[]'::jsonb);
end
$$;

-- ── Alta/edición de cliente (ahora también VIP y lista negra) ──
create or replace function public.staff_upsert_client(p_code text, p jsonb)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_id uuid;
  v_name text := left(btrim(coalesce(p->>'name','')), 80);
  v_phone text := left(btrim(coalesce(p->>'phone','')), 40);
  v_digits text := nullif(regexp_replace(coalesce(p->>'phone',''), '\D', '', 'g'), '');
  v_email text := nullif(left(btrim(coalesce(p->>'email','')), 120), '');
  v_notes text := left(btrim(coalesce(p->>'notes','')), 500);
  v_birthday date;
begin
  perform assert_staff(p_code);
  if v_name = '' then
    raise exception 'Falta el nombre';
  end if;
  begin
    v_birthday := nullif(p->>'birthday','')::date;
  exception when others then
    v_birthday := null;
  end;

  if coalesce(p->>'id','') <> '' then
    v_id := (p->>'id')::uuid;
    update clients set
      name = v_name, phone = v_phone, phone_digits = v_digits,
      email = v_email, birthday = v_birthday, notes = v_notes,
      vip = coalesce((p->>'vip')::boolean, vip),
      blacklisted = coalesce((p->>'blacklisted')::boolean, blacklisted),
      last_activity_at = now()
    where id = v_id;
    if not found then raise exception 'Cliente no encontrado'; end if;
  else
    insert into clients (name, phone, phone_digits, email, birthday, notes, vip, blacklisted)
    values (
      v_name, v_phone, v_digits, v_email, v_birthday, v_notes,
      coalesce((p->>'vip')::boolean, false),
      coalesce((p->>'blacklisted')::boolean, false)
    )
    returning id into v_id;
  end if;
  return v_id;
exception
  when unique_violation then
    raise exception 'Ya existe un cliente con ese teléfono';
end
$$;

-- ── Marca rápida (VIP / lista negra) sin abrir el formulario ──
create or replace function public.staff_set_client_flag(p_code text, p_id uuid, p_flag text, p_value boolean)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  perform assert_staff(p_code);
  if p_flag = 'vip' then
    update clients set vip = coalesce(p_value, false), last_activity_at = last_activity_at where id = p_id;
  elsif p_flag = 'blacklisted' then
    update clients set blacklisted = coalesce(p_value, false) where id = p_id;
  else
    raise exception 'Marca inválida';
  end if;
end
$$;

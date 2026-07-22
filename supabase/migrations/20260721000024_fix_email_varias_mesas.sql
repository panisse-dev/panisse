-- Corrige de nuevo lo mismo que arregló 20260721000017: al reescribir
-- staff_create_reservation para soportar varias mesas, se volvió a colar
-- nullif(v_email,'') en customer_email (columna not null default ''). Cuando
-- el correo es opcional y viene vacío debe guardarse como '' y no como NULL.
-- Se conserva todo el soporte de varias mesas de 20260721000023.

create or replace function public.staff_create_reservation(p_code text, p jsonb)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_loc text;
  v_target_loc text;
  v_name text := left(btrim(coalesce(p->>'name','')), 80);
  v_phone text := left(btrim(coalesce(p->>'phone','')), 40);
  v_email text := lower(left(btrim(coalesce(p->>'email','')), 120));
  v_party int := coalesce(nullif(p->>'party','')::int, 0);
  v_note text := left(btrim(coalesce(p->>'note','')), 300);
  v_source text := lower(coalesce(nullif(p->>'source',''), 'telefono'));
  v_date date;
  v_time time;
  v_tables uuid[];
  v_table uuid;
  v_phone_digits text;
  v_client_id uuid;
  v_code text;
  v_id uuid;
begin
  perform assert_staff(p_code);
  v_loc := staff_location(p_code);
  if v_source not in ('web','telefono','google','walkin','otro') then v_source := 'otro'; end if;
  if v_party < 1 or v_party > 50 then raise exception 'Número de personas no válido'; end if;
  if v_name = '' then raise exception 'Escribe el nombre'; end if;

  begin
    v_date := (p->>'date')::date;
    v_time := (p->>'time')::time;
  exception when others then
    raise exception 'Fecha u hora no válidas';
  end;

  if v_loc is not null then v_target_loc := v_loc;
  else v_target_loc := coalesce(nullif(p->>'location',''), 'cerritos'); end if;
  if not exists (select 1 from locations where id = v_target_loc) then
    raise exception 'Sede no válida';
  end if;

  v_tables := reservation_tables_from_payload(p);
  if array_length(v_tables, 1) is not null then
    if exists (select 1 from unnest(v_tables) tid
               left join restaurant_tables t on t.id = tid
               where t.id is null or t.location_id <> v_target_loc) then
      raise exception 'Alguna mesa no es de esta sede';
    end if;
    v_table := v_tables[1];
  end if;

  v_phone_digits := nullif(regexp_replace(v_phone, '\D', '', 'g'), '');
  if v_email <> '' then
    select id into v_client_id from clients where lower(email) = v_email limit 1;
  end if;
  if v_client_id is null and v_phone_digits is not null then
    select id into v_client_id from clients where phone_digits = v_phone_digits limit 1;
  end if;
  if v_client_id is null and (v_phone_digits is not null or v_email <> '') then
    begin
      insert into clients (name, phone, phone_digits, email)
      values (v_name, v_phone, v_phone_digits, nullif(v_email,''))
      returning id into v_client_id;
    exception when unique_violation then
      select id into v_client_id from clients where phone_digits = v_phone_digits limit 1;
    end;
  elsif v_client_id is not null then
    update clients set last_activity_at = now() where id = v_client_id;
  end if;

  v_code := nextval('reservation_code_seq')::text;
  insert into reservations (
    code, reserved_date, reserved_time, party_size, client_id,
    customer_name, customer_phone, customer_email, note,
    status, is_walk_in, table_id, location_id, source
  ) values (
    v_code, v_date, v_time, v_party, v_client_id,
    v_name, v_phone, v_email, v_note,
    'confirmada', false, v_table, v_target_loc, v_source
  ) returning id into v_id;

  if array_length(v_tables, 1) is not null then
    insert into reservation_tables (reservation_id, table_id)
    select v_id, tid from unnest(v_tables) tid on conflict do nothing;
  end if;

  return jsonb_build_object('id', v_id, 'code', v_code, 'status', 'confirmada');
end
$$;

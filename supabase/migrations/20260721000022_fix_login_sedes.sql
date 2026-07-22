-- ══════════════════════════════════════════════════════════════════
-- Arreglo del login del panel para las claves de sede
--
-- staff_verify (la función que revisa la clave al entrar) sólo miraba la
-- clave del dueño (app_config), pero NO las claves de las sedes (que viven
-- en staff_members). Por eso "cerritos2026" y "pilares2026" no dejaban
-- entrar, aunque el resto del sistema sí las reconoce (assert_staff). Se
-- iguala staff_verify a assert_staff: vale la clave del dueño o la de una sede.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.staff_verify(p_code text)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select coalesce(p_code, '') <> '' and (
    exists (select 1 from app_config where key = 'staff_code' and value = p_code)
    or exists (select 1 from staff_members where code = p_code)
  )
$$;

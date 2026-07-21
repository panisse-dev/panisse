-- Los bloqueadores de anuncios/privacidad suelen bloquear cualquier petición
-- cuya URL contenga "analytics". Como la función se llamaba staff_analytics,
-- a los administradores con bloqueador les fallaba la pantalla de analítica.
-- Creamos un nombre neutro en español (staff_resumen) que ningún bloqueador
-- toca; por dentro reutiliza la misma función. Dejamos staff_analytics para no
-- romper la versión que aún esté publicada.
create or replace function public.staff_resumen(p_code text, p_from date, p_to date)
returns jsonb
language sql
security definer set search_path = public
as $$
  select public.staff_analytics(p_code, p_from, p_to);
$$;

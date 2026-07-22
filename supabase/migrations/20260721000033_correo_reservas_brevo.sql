-- ══════════════════════════════════════════════════════════════════
-- Correo automático al cliente cuando llega una reserva (vía Brevo).
--
-- Al crear una reserva con correo, la base envía sola un email de "reserva
-- recibida" usando Brevo (servicio de correo). Se usa pg_net para llamar la
-- API de Brevo sin bloquear la reserva. La clave de Brevo se guarda en una
-- tabla privada (app_secrets); mientras no esté puesta, no se envía nada.
-- ══════════════════════════════════════════════════════════════════

create extension if not exists pg_net;

-- Tabla privada para claves de servicios (solo la leen funciones internas).
create table if not exists public.app_secrets (
  key text primary key,
  value text not null default ''
);
alter table public.app_secrets enable row level security;  -- sin políticas: nadie la lee por la API

insert into public.app_secrets (key, value) values
  ('brevo_api_key', ''),
  ('brevo_sender_email', 'gerenciapanisse@gmail.com'),
  ('brevo_sender_name', 'PANISSE')
on conflict (key) do nothing;

-- Envía el correo de "reserva recibida" al crear la reserva.
create or replace function public.reservation_email_notify()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_key text;
  v_sender_email text;
  v_sender_name text;
  v_sede text;
  v_fecha text;
  v_hora text;
  v_meses text[] := array['enero','febrero','marzo','abril','mayo','junio','julio',
                          'agosto','septiembre','octubre','noviembre','diciembre'];
  v_html text;
begin
  -- Sin correo del cliente, no hay a quién enviarle.
  if coalesce(new.customer_email, '') = '' then return new; end if;

  select value into v_key from app_secrets where key = 'brevo_api_key';
  if coalesce(v_key, '') = '' then return new; end if;  -- aún no hay clave: no envía

  select value into v_sender_email from app_secrets where key = 'brevo_sender_email';
  select value into v_sender_name from app_secrets where key = 'brevo_sender_name';
  select name into v_sede from locations where id = new.location_id;

  v_fecha := extract(day from new.reserved_date)::text || ' de ' ||
             v_meses[extract(month from new.reserved_date)::int];
  v_hora := lower(to_char(new.reserved_time, 'HH12:MI am'));

  v_html :=
    '<div style="font-family:Georgia,serif;max-width:480px;margin:0 auto;background:#f6f6f5;padding:32px 24px;color:#10202f;">' ||
      '<div style="text-align:center;">' ||
        '<p style="letter-spacing:3px;font-size:11px;color:#8f7434;text-transform:uppercase;margin:0;">PANISSE</p>' ||
        '<h1 style="color:#11572e;font-size:24px;margin:10px 0 6px;">¡Reserva recibida!</h1>' ||
        '<p style="font-size:15px;margin:0;">Hola <b>' || coalesce(new.customer_name, '') ||
          '</b>, recibimos tu reserva. ¡Te esperamos!</p>' ||
      '</div>' ||
      '<table style="width:100%;margin:22px 0;border-collapse:collapse;border-top:1px solid #d9bb73;border-bottom:1px solid #d9bb73;font-size:15px;">' ||
        '<tr><td style="padding:9px 0;color:#8f7434;">Personas</td><td style="text-align:right;">' || new.party_size || '</td></tr>' ||
        '<tr><td style="padding:9px 0;color:#8f7434;border-top:1px solid #eee;">Día</td><td style="text-align:right;border-top:1px solid #eee;">' || v_fecha || '</td></tr>' ||
        '<tr><td style="padding:9px 0;color:#8f7434;border-top:1px solid #eee;">Hora</td><td style="text-align:right;border-top:1px solid #eee;">' || v_hora || '</td></tr>' ||
        case when v_sede is not null then
          '<tr><td style="padding:9px 0;color:#8f7434;border-top:1px solid #eee;">Sede</td><td style="text-align:right;border-top:1px solid #eee;">' || v_sede || '</td></tr>'
        else '' end ||
      '</table>' ||
      '<p style="font-size:13px;color:#47535e;text-align:center;margin:0;">Si necesitas cambiar algo, escríbenos por WhatsApp. ¡Gracias por elegirnos!</p>' ||
    '</div>';

  -- Envío asíncrono (no bloquea la reserva). Si algo falla, la reserva igual queda.
  begin
    perform net.http_post(
      url := 'https://api.brevo.com/v3/smtp/email',
      headers := jsonb_build_object(
        'api-key', v_key,
        'content-type', 'application/json',
        'accept', 'application/json'
      ),
      body := jsonb_build_object(
        'sender', jsonb_build_object('name', coalesce(v_sender_name,'PANISSE'), 'email', v_sender_email),
        'to', jsonb_build_array(jsonb_build_object('email', new.customer_email, 'name', coalesce(new.customer_name,''))),
        'subject', 'Tu reserva en PANISSE',
        'htmlContent', v_html
      )
    );
  exception when others then
    -- Nunca tumbar la reserva por un problema de correo.
    null;
  end;

  return new;
end
$$;

drop trigger if exists trg_reservation_email on public.reservations;
create trigger trg_reservation_email
  after insert on public.reservations
  for each row execute function public.reservation_email_notify();

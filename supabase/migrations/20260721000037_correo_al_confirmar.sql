-- (1) El correo dice "Reserva recibida" mientras está pendiente y "Reserva
--     confirmada" cuando ya se confirmó (según el estado de la reserva).
-- (2) Al confirmar una reserva desde el panel, el correo sale automáticamente.

create or replace function public.send_reservation_email(p_id uuid)
returns boolean
language plpgsql
security definer set search_path = public
as $$
declare
  r reservations;
  v_key text;
  v_sender_email text;
  v_sender_name text;
  v_sede text;
  v_wa text;
  v_table text;
  v_zone text;
  v_mesa text;
  v_fecha text;
  v_hora text;
  v_titulo text;
  v_sub text;
  v_meses text[] := array['enero','febrero','marzo','abril','mayo','junio','julio',
                          'agosto','septiembre','octubre','noviembre','diciembre'];
  v_wa_url text;
  v_html text;
begin
  select * into r from reservations where id = p_id;
  if r.id is null or coalesce(r.customer_email,'') = '' then return false; end if;

  select value into v_key from app_secrets where key = 'brevo_api_key';
  if coalesce(v_key,'') = '' then return false; end if;

  select value into v_sender_email from app_secrets where key = 'brevo_sender_email';
  select value into v_sender_name from app_secrets where key = 'brevo_sender_name';
  select name, nullif(regexp_replace(coalesce(whatsapp,''), '\D', '', 'g'), '')
    into v_sede, v_wa from locations where id = r.location_id;
  v_wa := coalesce(v_wa, '573107081217');

  if r.table_id is not null then
    select t.name, z.name into v_table, v_zone
    from restaurant_tables t join zones z on z.id = t.zone_id
    where t.id = r.table_id;
  end if;
  v_mesa := case
    when v_table is not null and v_zone is not null then v_zone || ' · ' || v_table
    when v_table is not null then v_table
    else 'Por asignar'
  end;

  if r.status in ('confirmada','cumplida') then
    v_titulo := 'Reserva confirmada';
    v_sub := 'tu reserva en PANISSE quedó confirmada. ¡Te esperamos!';
  else
    v_titulo := 'Reserva recibida';
    v_sub := 'recibimos tu reserva. En breve te confirmamos. ¡Te esperamos!';
  end if;

  v_fecha := extract(day from r.reserved_date)::text || ' de ' ||
             v_meses[extract(month from r.reserved_date)::int];
  v_hora := lower(to_char(r.reserved_time, 'HH12:MI am'));
  v_wa_url := 'https://wa.me/' || v_wa ||
              '?text=Hola%2C%20quiero%20modificar%20o%20cancelar%20mi%20reserva%20%23' || r.code;

  v_html :=
  '<div style="background:#eef0ec;padding:24px 12px;font-family:Georgia,Times New Roman,serif;">' ||
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;margin:0 auto;background:#f6f6f5;border:1px solid #e3d6b4;">' ||
      '<tr><td style="padding:30px 28px 6px;text-align:center;">' ||
        '<div style="width:56px;height:56px;margin:0 auto;border-radius:28px;background:#11572e;color:#ffffff;font-size:30px;line-height:56px;">&#10003;</div>' ||
        '<p style="letter-spacing:3px;font-size:11px;color:#8f7434;text-transform:uppercase;margin:16px 0 0;">PANISSE</p>' ||
        '<h1 style="color:#11572e;font-size:25px;margin:6px 0 4px;">' || v_titulo || '</h1>' ||
        '<p style="font-size:15px;color:#10202f;margin:6px 0 0;">Hola <b>' || coalesce(r.customer_name,'') ||
          '</b>, ' || v_sub || '</p>' ||
      '</td></tr>' ||
      '<tr><td style="padding:6px 24px;">' ||
        '<p style="letter-spacing:2px;font-size:10px;color:#8f7434;text-transform:uppercase;text-align:center;margin:16px 0 8px;">Información de tu reserva</p>' ||
        '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-top:1px solid #d9bb73;border-bottom:1px solid #d9bb73;">' ||
          '<tr>' ||
            '<td style="padding:13px 4px;text-align:center;border-right:1px solid #eadfbf;">' ||
              '<div style="font-size:17px;color:#041b31;font-weight:bold;">' || r.party_size || '</div>' ||
              '<div style="font-size:9px;letter-spacing:1px;color:#8f7c66;text-transform:uppercase;">Personas</div></td>' ||
            '<td style="padding:13px 4px;text-align:center;border-right:1px solid #eadfbf;">' ||
              '<div style="font-size:13px;color:#041b31;font-weight:bold;">' || v_fecha || '</div>' ||
              '<div style="font-size:9px;letter-spacing:1px;color:#8f7c66;text-transform:uppercase;">Día</div></td>' ||
            '<td style="padding:13px 4px;text-align:center;border-right:1px solid #eadfbf;">' ||
              '<div style="font-size:13px;color:#041b31;font-weight:bold;">' || v_hora || '</div>' ||
              '<div style="font-size:9px;letter-spacing:1px;color:#8f7c66;text-transform:uppercase;">Hora</div></td>' ||
            '<td style="padding:13px 4px;text-align:center;">' ||
              '<div style="font-size:12px;color:#041b31;font-weight:bold;">' || v_mesa || '</div>' ||
              '<div style="font-size:9px;letter-spacing:1px;color:#8f7c66;text-transform:uppercase;">Zona</div></td>' ||
          '</tr>' ||
        '</table>' ||
        case when v_sede is not null then
          '<p style="text-align:center;font-size:12px;color:#6d7680;margin:10px 0 0;">Sede: ' || v_sede || '</p>'
        else '' end ||
      '</td></tr>' ||
      '<tr><td style="padding:22px 28px 30px;text-align:center;">' ||
        '<a href="' || v_wa_url || '" style="display:inline-block;background:#041b31;color:#d9bb73;text-decoration:none;font-size:14px;font-weight:bold;padding:14px 30px;letter-spacing:0.5px;">Modificar o cancelar</a>' ||
        '<p style="font-size:12px;color:#6d7680;margin:16px 0 0;">Con ese botón nos escribes por WhatsApp y te ayudamos a cambiar o cancelar tu reserva. ¡Te esperamos!</p>' ||
      '</td></tr>' ||
    '</table>' ||
  '</div>';

  begin
    perform net.http_post(
      url := 'https://api.brevo.com/v3/smtp/email',
      headers := jsonb_build_object('api-key', v_key, 'content-type', 'application/json', 'accept', 'application/json'),
      body := jsonb_build_object(
        'sender', jsonb_build_object('name', coalesce(v_sender_name,'PANISSE'), 'email', v_sender_email),
        'to', jsonb_build_array(jsonb_build_object('email', r.customer_email, 'name', coalesce(r.customer_name,''))),
        'subject', case when r.status in ('confirmada','cumplida') then 'Reserva confirmada · PANISSE' else 'Tu reserva en PANISSE' end,
        'htmlContent', v_html
      )
    );
  exception when others then
    return false;
  end;
  return true;
end
$$;

-- Al confirmar la reserva desde el panel, mandar el correo automáticamente.
create or replace function public.staff_set_reservation_status(p_code text, p_id uuid, p_status text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_old text;
begin
  perform assert_staff(p_code);
  if p_status not in ('pendiente','confirmada','cancelada','cumplida','no_show') then
    raise exception 'Estado inválido';
  end if;
  select status into v_old from reservations where id = p_id;
  update reservations set status = p_status, status_at = now() where id = p_id;
  -- Al pasar a "confirmada" (y si no lo estaba ya), sale el correo solo.
  if p_status = 'confirmada' and coalesce(v_old,'') <> 'confirmada' then
    perform send_reservation_email(p_id);
  end if;
end
$$;

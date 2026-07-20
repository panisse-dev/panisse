// Sube fotos de productos a Storage (bucket product-images).
// Sólo el personal: exige la clave staff en el header x-staff-code,
// verificada contra app_config con el service role.
import { createClient } from "npm:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-staff-code",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "content-type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const code = req.headers.get("x-staff-code") ?? "";
  const { data: cfg } = await supa
    .from("app_config")
    .select("value")
    .eq("key", "staff_code")
    .single();
  if (!cfg || !code || cfg.value !== code) {
    return json({ error: "No autorizado" }, 401);
  }

  const contentType = req.headers.get("content-type") || "";
  if (!contentType.startsWith("image/")) {
    return json({ error: "Sube una imagen (jpg, png o webp)" }, 400);
  }
  const buf = await req.arrayBuffer();
  if (buf.byteLength === 0) return json({ error: "Archivo vacío" }, 400);
  if (buf.byteLength > 6_000_000) {
    return json({ error: "La imagen supera 6 MB" }, 413);
  }

  const ext =
    contentType === "image/png" ? "png" :
    contentType === "image/jpeg" ? "jpg" :
    contentType === "image/webp" ? "webp" : "img";
  const name = `products/${crypto.randomUUID()}.${ext}`;

  const { error } = await supa.storage
    .from("product-images")
    .upload(name, buf, { contentType, cacheControl: "31536000" });
  if (error) return json({ error: error.message }, 500);

  const { data: pub } = supa.storage.from("product-images").getPublicUrl(name);
  return json({ url: pub.publicUrl });
});

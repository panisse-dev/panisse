#!/usr/bin/env node
// Genera la migración de datos (seed) para Supabase a partir de
// web/src/data/menu.json. Vuelca restaurante, menús, secciones,
// subsecciones y productos. Si un id de Firestore se repite entre
// menús, se le agrega el slug del menú para mantener ambos.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const data = JSON.parse(readFileSync(join(root, "web/src/data/menu.json"), "utf8"));

const q = (s) => (s == null ? "null" : `'${String(s).replace(/'/g, "''")}'`);
const qj = (v) => `'${JSON.stringify(v).replace(/'/g, "''")}'::jsonb`;

const lines = [];
lines.push("-- Datos iniciales generados desde web/src/data/menu.json");
lines.push("-- (node scripts/gen-supabase-seed.mjs)");
lines.push("");

const r = data.restaurant;
lines.push(
  `insert into public.restaurant_info (name, logo, instagram, whatsapp, address, city, currency)\n` +
    `values (${q(r.name)}, ${q(r.logo)}, ${q(r.instagram)}, ${q(r.whatsapp)}, ${q(r.address)}, ${q(r.city)}, ${q(r.currency)});`
);
lines.push("");

const seenSections = new Set();
const seenProducts = new Set();
let dupSections = 0;
let dupProducts = 0;
let nProducts = 0;

const uniqueId = (id, set, menuSlug, isSection) => {
  if (!set.has(id)) {
    set.add(id);
    return id;
  }
  if (isSection) dupSections++;
  else dupProducts++;
  const alt = `${id}__${menuSlug}`;
  set.add(alt);
  return alt;
};

data.menus.forEach((m, mi) => {
  lines.push(`-- ── Menú ${m.name} ──`);
  lines.push(
    `insert into public.menus (slug, label, tagline, name, sort)\n` +
      `values (${q(m.slug)}, ${q(m.label)}, ${q(m.tagline)}, ${q(m.name)}, ${mi});`
  );

  const emitProducts = (products, sectionId) => {
    for (const p of products) {
      const pid = uniqueId(p.id, seenProducts, m.slug, false);
      nProducts++;
      lines.push(
        `insert into public.products (id, section_id, name, description, prices, hide_price, image, is_new, veg, sort)\n` +
          `values (${q(pid)}, ${q(sectionId)}, ${q(p.name)}, ${q(p.description)}, ${qj(p.prices)}, ${p.hidePrice}, ${q(p.image)}, ${p.isNew}, ${p.veg}, ${p.order ?? 0});`
      );
    }
  };

  m.sections.forEach((s, si) => {
    const sid = uniqueId(s.id, seenSections, m.slug, true);
    lines.push(
      `insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)\n` +
        `values (${q(sid)}, ${q(m.slug)}, null, ${q(s.slug)}, ${q(s.name)}, ${q(s.description)}, ${q(s.image)}, ${q(s.layout)}, ${si});`
    );
    emitProducts(s.products, sid);
    (s.subsections || []).forEach((ss, ssi) => {
      const ssid = uniqueId(ss.id, seenSections, m.slug, true);
      lines.push(
        `insert into public.sections (id, menu_slug, parent_id, slug, name, description, image, layout, sort)\n` +
          `values (${q(ssid)}, ${q(m.slug)}, ${q(sid)}, ${q(ss.slug)}, ${q(ss.name)}, ${q(ss.description)}, null, ${q(ss.layout)}, ${ssi});`
      );
      emitProducts(ss.products, ssid);
    });
  });
  lines.push("");
});

const out = join(root, "supabase/migrations/20260719000002_seed.sql");
writeFileSync(out, lines.join("\n") + "\n");
console.log(
  `OK → ${out}\nmenus=${data.menus.length} products=${nProducts} dupSections=${dupSections} dupProducts=${dupProducts}`
);

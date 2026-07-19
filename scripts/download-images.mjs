import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';

const full = JSON.parse(readFileSync('data/raw/menus_full.json', 'utf8'));
const restaurant = JSON.parse(readFileSync('data/raw/restaurant.json', 'utf8'));
const location = JSON.parse(readFileSync('data/raw/location.json', 'utf8'));

mkdirSync('images/products', { recursive: true });
mkdirSync('images/categories', { recursive: true });
mkdirSync('images/menus', { recursive: true });
mkdirSync('images/restaurant', { recursive: true });

// Build download list: {url, dir, name}
const jobs = [];
const seen = new Set();
const add = (url, dir) => {
  if (typeof url !== 'string' || !/^https?:\/\//.test(url)) return;
  if (seen.has(url)) return;
  seen.add(url);
  let base = url.split('/').pop().split('?')[0];
  if (!/\.\w{2,5}$/.test(base)) base += '.img';
  jobs.push({ url, dir, name: base });
};

for (const m of full.menus) {
  add(m.background_url, 'menus');
  add(m.banner_background_url, 'menus');
  for (const c of m.categories) { add(c.image_url, 'categories'); if (c.design?.banner) add(c.design.banner, 'categories'); }
  for (const p of m.products) {
    const imgs = Array.isArray(p.image) ? p.image : (p.image ? [p.image] : []);
    imgs.forEach(im => add(typeof im === 'string' ? im : (im?.url || im?.src), 'products'));
  }
}
add(restaurant.main_menu_url, 'restaurant');
add(restaurant.logo_url, 'restaurant');
add(location.logo_url, 'restaurant');

console.log(`Downloading ${jobs.length} images...`);
const mapping = [];
let ok = 0, fail = 0;
const CONC = 8;
for (let i = 0; i < jobs.length; i += CONC) {
  const batch = jobs.slice(i, i + CONC);
  await Promise.all(batch.map(async (job) => {
    const dest = `images/${job.dir}/${job.name}`;
    try {
      if (existsSync(dest)) { mapping.push({ ...job, dest, status: 'exists' }); ok++; return; }
      const r = await fetch(job.url);
      if (!r.ok) { mapping.push({ ...job, dest, status: 'http_' + r.status }); fail++; return; }
      const buf = Buffer.from(await r.arrayBuffer());
      writeFileSync(dest, buf);
      mapping.push({ ...job, dest, status: 'ok', bytes: buf.length });
      ok++;
    } catch (e) {
      mapping.push({ ...job, dest, status: 'err_' + e.message }); fail++;
    }
  }));
  process.stdout.write(`\r  ${Math.min(i + CONC, jobs.length)}/${jobs.length}`);
}
console.log(`\nDone. ok=${ok} fail=${fail}`);
writeFileSync('data/raw/image_mapping.json', JSON.stringify(mapping, null, 2));
const failed = mapping.filter(m => m.status !== 'ok' && m.status !== 'exists');
if (failed.length) console.log('FAILED:', JSON.stringify(failed, null, 2));

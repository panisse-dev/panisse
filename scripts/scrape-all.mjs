import { listCollection, getDoc } from './fs-lib.mjs';
import { writeFileSync, mkdirSync } from 'node:fs';

const REST = 'toscana';
const LOC = '1vr1yK8rCvD7eaiZXHDj';

mkdirSync('data/raw', { recursive: true });

// Restaurant + location metadata
const restaurant = await getDoc(`restaurants/${REST}`);
const location = await getDoc(`restaurants/${REST}/locations/${LOC}`);
writeFileSync('data/raw/restaurant.json', JSON.stringify(restaurant, null, 2));
writeFileSync('data/raw/location.json', JSON.stringify(location, null, 2));

// Menus
const menus = await listCollection(`restaurants/${REST}/locations/${LOC}/menus`, { orderBy: 'order' });
writeFileSync('data/raw/menus.json', JSON.stringify(menus, null, 2));

const full = { restaurant: { _id: restaurant._id, name: restaurant.name, currency: restaurant.currency, country: restaurant.country, instagram: restaurant.socialLinks?.instagram }, location: { _id: location._id, name: location.name }, menus: [] };

for (const menu of menus) {
  const categories = await listCollection(`restaurants/${REST}/locations/${LOC}/menus/${menu._id}/categories`, { orderBy: 'order' });
  const products = await listCollection(`restaurants/${REST}/locations/${LOC}/menus/${menu._id}/products`, { orderBy: 'order' });
  const cats = Array.isArray(categories) ? categories : [];
  const prods = Array.isArray(products) ? products : [];
  writeFileSync(`data/raw/menu_${menu.name.trim().replace(/[^a-zA-Z0-9]+/g,'_')}_categories.json`, JSON.stringify(cats, null, 2));
  writeFileSync(`data/raw/menu_${menu.name.trim().replace(/[^a-zA-Z0-9]+/g,'_')}_products.json`, JSON.stringify(prods, null, 2));
  full.menus.push({
    _id: menu._id, name: menu.name.trim(), order: menu.order, active: menu.active, hide: menu.hide,
    background_url: menu.background_url, banner_background_url: menu.banner_background_url,
    categories: cats, products: prods
  });
  console.log(`${menu.name.trim().padEnd(18)} cats=${cats.length}  prods=${prods.length}`);
}

writeFileSync('data/raw/menus_full.json', JSON.stringify(full, null, 2));

// Image URL inventory
const imgUrls = new Set();
const collect = (u) => { if (typeof u === 'string' && /^https?:\/\//.test(u)) imgUrls.add(u); };
for (const m of full.menus) {
  collect(m.background_url); collect(m.banner_background_url);
  for (const c of m.categories) { collect(c.image_url); if (c.design?.banner) collect(c.design.banner); }
  for (const p of m.products) {
    if (Array.isArray(p.image)) p.image.forEach(im => collect(typeof im === 'string' ? im : im?.url || im?.src));
    else collect(p.image);
  }
}
collect(restaurant.main_menu_url); collect(location.logo_url);
writeFileSync('data/raw/image_urls.json', JSON.stringify([...imgUrls], null, 2));
console.log(`\nTotal unique image URLs: ${imgUrls.size}`);
console.log('Saved raw data to data/raw/');

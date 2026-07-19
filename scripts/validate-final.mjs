import { listCollection } from './fs-lib.mjs';
import { readFileSync, statSync, existsSync } from 'node:fs';

const REST = 'toscana', LOC = '1vr1yK8rCvD7eaiZXHDj';
const saved = JSON.parse(readFileSync('data/raw/menus_full.json', 'utf8'));
const imgMap = JSON.parse(readFileSync('data/raw/image_mapping.json', 'utf8'));

console.log('=== RE-VERIFICACIÓN INDEPENDIENTE CONTRA FIRESTORE (en vivo) ===\n');
let allOk = true;
for (const menu of saved.menus) {
  const liveCats = await listCollection(`restaurants/${REST}/locations/${LOC}/menus/${menu._id}/categories`);
  const liveProds = await listCollection(`restaurants/${REST}/locations/${LOC}/menus/${menu._id}/products`);
  const lc = Array.isArray(liveCats) ? liveCats.length : -1;
  const lp = Array.isArray(liveProds) ? liveProds.length : -1;
  const sc = menu.categories.length, sp = menu.products.length;
  // Compare product id sets
  const liveIds = new Set(liveProds.map(p => p._id));
  const savedIds = new Set(menu.products.map(p => p._id));
  const missing = [...liveIds].filter(x => !savedIds.has(x));
  const extra = [...savedIds].filter(x => !liveIds.has(x));
  const ok = lc === sc && lp === sp && missing.length === 0 && extra.length === 0;
  if (!ok) allOk = false;
  console.log(`${menu.name.trim().padEnd(18)} cats live/saved=${lc}/${sc}  prods live/saved=${lp}/${sp}  faltantes=${missing.length} sobrantes=${extra.length}  ${ok ? '✅' : '❌'}`);
  if (missing.length) console.log('   FALTANTES:', missing);
}

console.log('\n=== VERIFICACIÓN DE IMÁGENES ===');
let imgOk = 0, imgBad = 0;
for (const m of imgMap) {
  const p = m.dest;
  if (existsSync(p) && statSync(p).size > 100) imgOk++;
  else { imgBad++; console.log('  ⚠️ imagen inválida o vacía:', p, m.status); }
}
console.log(`Imágenes válidas: ${imgOk}/${imgMap.length}  (inválidas: ${imgBad})`);

// Total unique products
const uniq = new Set();
for (const m of saved.menus) for (const p of m.products) uniq.add(p._id);
console.log(`\nProductos únicos totales (todos los menús): ${uniq.size}`);

console.log(`\n=== RESULTADO GLOBAL: ${allOk && imgBad === 0 ? '✅ TODO COMPLETO Y VERIFICADO' : '❌ REVISAR INCIDENCIAS'} ===`);

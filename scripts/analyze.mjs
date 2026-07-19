import { readFileSync } from 'node:fs';
const full = JSON.parse(readFileSync('data/raw/menus_full.json', 'utf8'));

console.log('=== MENU SUMMARY ===');
const byMenu = {};
for (const m of full.menus) {
  byMenu[m.name] = { cats: m.categories.length, prods: m.products.length, prodIds: new Set(m.products.map(p=>p._id)) };
  console.log(`${m.name.padEnd(18)} cats=${m.categories.length} prods=${m.products.length}`);
}

// Unique products across all menus by _id and by name
const allProdIds = new Set();
const nameCount = {};
let withImage = 0, totalPriceEntries = 0, multiPrice = 0, disabledCount = 0;
const productTypes = {};
for (const m of full.menus) {
  for (const p of m.products) {
    allProdIds.add(p._id);
    const nm = (p.product_name||'').trim();
    nameCount[nm] = (nameCount[nm]||0)+1;
    const imgs = Array.isArray(p.image) ? p.image : (p.image ? [p.image] : []);
    if (imgs.length) withImage++;
    if (Array.isArray(p.price)) { totalPriceEntries += p.price.length; if (p.price.length>1) multiPrice++; }
    if (p.disabled) disabledCount++;
    productTypes[p.product_type] = (productTypes[p.product_type]||0)+1;
  }
}
console.log('\n=== TOTALS ===');
console.log('Unique product _ids across all menus:', allProdIds.size);
console.log('Product rows across all menus (sum):', full.menus.reduce((s,m)=>s+m.products.length,0));
console.log('Product types:', JSON.stringify(productTypes));
console.log('Product rows with >=1 image:', withImage);
console.log('Product rows with multiple prices:', multiPrice);
console.log('Product rows disabled:', disabledCount);

// Overlap BRUNCH vs LUNCH
const B = byMenu['BRUNCH'].prodIds, L = byMenu['LUNCH Y DINNER'].prodIds;
if (B && L) {
  const inter = [...B].filter(x=>L.has(x)).length;
  console.log(`\nBRUNCH∩LUNCH shared _ids: ${inter} | only BRUNCH: ${[...B].filter(x=>!L.has(x)).length} | only LUNCH: ${[...L].filter(x=>!B.has(x)).length}`);
}

// Sample of a product WITH image to see format
outer:
for (const m of full.menus) for (const p of m.products) {
  const imgs = Array.isArray(p.image) ? p.image : (p.image?[p.image]:[]);
  if (imgs.length) { console.log('\n=== SAMPLE PRODUCT WITH IMAGE ==='); console.log(JSON.stringify(p, null, 2).slice(0,1200)); break outer; }
}

// Sample product with options/subproducts
outer2:
for (const m of full.menus) for (const p of m.products) {
  if ((p.options&&p.options.length) || (p.subProducts&&p.subProducts.length)) {
    console.log('\n=== SAMPLE PRODUCT WITH OPTIONS/SUBPRODUCTS ==='); console.log(JSON.stringify({name:p.product_name, options:p.options, subProducts:p.subProducts, price:p.price}, null, 2).slice(0,1500)); break outer2;
  }
}

// Category hierarchy types
const hierarchies = {};
for (const m of full.menus) for (const c of m.categories) hierarchies[c.hierarchy] = (hierarchies[c.hierarchy]||0)+1;
console.log('\nCategory hierarchies:', JSON.stringify(hierarchies));

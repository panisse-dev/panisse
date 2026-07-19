import { readFileSync, writeFileSync } from 'node:fs';

const full = JSON.parse(readFileSync('data/raw/menus_full.json', 'utf8'));
const imgMap = JSON.parse(readFileSync('data/raw/image_mapping.json', 'utf8'));
const urlToLocal = Object.fromEntries(imgMap.map(m => [m.url, `images/${m.dir}/${m.name}`]));

// ---- helpers ----
const stripHtml = (s) => (s == null ? '' : String(s)
  .replace(/<br\s*\/?>/gi, ' ')
  .replace(/<[^>]+>/g, ' ')
  .replace(/&nbsp;/gi, ' ')
  .replace(/&amp;/gi, '&')
  .replace(/&aacute;/gi, 'á').replace(/&eacute;/gi, 'é').replace(/&iacute;/gi, 'í')
  .replace(/&oacute;/gi, 'ó').replace(/&uacute;/gi, 'ú').replace(/&ntilde;/gi, 'ñ')
  .replace(/\s+/g, ' ').trim());

const fmtCOP = (n) => (n == null || n === '' ? '' : '$' + Number(n).toLocaleString('es-CO'));

const csvCell = (v) => {
  const s = v == null ? '' : String(v);
  return /[",\n;]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
};
const toCSV = (rows, headers) => [headers.join(','), ...rows.map(r => headers.map(h => csvCell(r[h])).join(','))].join('\n');

// ---- validation + normalization ----
const validation = { menus: [], issues: [] };
const allRows = [];          // one row per (menu, product)
const uniqueProducts = {};   // _id -> { product, menus:Set }

for (const menu of full.menus) {
  const catById = Object.fromEntries(menu.categories.map(c => [c._id, c]));
  const menuName = menu.name.trim();
  // resolve category path (root > sub)
  const catPath = (c) => {
    if (!c) return { root: '', sub: '', path: '' };
    if (c.hierarchy && c.hierarchy !== 'root' && catById[c.hierarchy]) {
      const parent = catById[c.hierarchy];
      return { root: (parent.name || '').trim(), sub: (c.name || '').trim(), path: `${(parent.name||'').trim()} > ${(c.name||'').trim()}` };
    }
    return { root: (c.name || '').trim(), sub: '', path: (c.name || '').trim() };
  };

  let unresolvedCat = 0, unresolvedParent = 0;
  for (const c of menu.categories) {
    if (c.hierarchy && c.hierarchy !== 'root' && !catById[c.hierarchy]) unresolvedParent++;
  }

  // sort products by category order then product order
  const prodSorted = menu.products.slice().sort((a, b) => {
    const ca = catById[a.product_category], cb = catById[b.product_category];
    const oa = ca ? ca.order : 999, ob = cb ? cb.order : 999;
    if (oa !== ob) return oa - ob;
    return (a.order ?? 0) - (b.order ?? 0);
  });

  for (const p of prodSorted) {
    let cat = catById[p.product_category] || p.category || null;
    const isOrphan = !catById[p.product_category] && !p.category;
    if (isOrphan) unresolvedCat++;
    const cp = isOrphan ? { root: '(SIN CATEGORÍA)', sub: '', path: '(SIN CATEGORÍA)' } : catPath(cat);
    const imgs = (Array.isArray(p.image) ? p.image : (p.image ? [p.image] : []))
      .map(im => typeof im === 'string' ? im : (im?.url || im?.src)).filter(Boolean);
    const prices = Array.isArray(p.price) ? p.price : (p.price != null ? [{ price: p.price }] : []);
    const basePrice = prices.length ? prices[0].price : '';
    const variants = prices.map(pr => (pr.label ? pr.label + ': ' : '') + fmtCOP(pr.price) + (pr.discountedPrice ? ` (oferta ${fmtCOP(pr.discountedPrice)})` : '')).join(' | ');

    const row = {
      menu: menuName,
      categoria_raiz: cp.root,
      subcategoria: cp.sub,
      categoria_ruta: cp.path,
      orden_categoria: cat ? cat.order : '',
      producto: (p.product_name || '').trim(),
      descripcion: stripHtml(p.description),
      precio: fmtCOP(basePrice),
      precio_num: basePrice,
      variantes_precio: prices.length > 1 ? variants : '',
      num_variantes: prices.length,
      recomendado: p.recommended ? 'sí' : '',
      nuevo: p.new ? 'sí' : '',
      oculto_en_web: p.disabled ? 'sí' : '',
      precio_oculto: p.hidePrice ? 'sí' : '',
      num_imagenes: imgs.length,
      imagen_archivo: imgs.map(u => (urlToLocal[u] || u).split('/').pop()).join(' | '),
      imagen_url: imgs.join(' | '),
      product_id: p._id,
      category_id: p.product_category || (cat && cat._id) || '',
      product_type: p.product_type || '',
    };
    allRows.push(row);

    if (!uniqueProducts[p._id]) uniqueProducts[p._id] = { row: { ...row }, menus: new Set() };
    uniqueProducts[p._id].menus.add(menuName);
  }

  validation.menus.push({ menu: menuName, categorias: menu.categories.length, productos: menu.products.length, categorias_sin_padre: unresolvedParent, productos_sin_categoria: unresolvedCat });
  if (unresolvedParent) validation.issues.push(`${menuName}: ${unresolvedParent} subcategorías con padre no encontrado`);
  if (unresolvedCat) validation.issues.push(`${menuName}: ${unresolvedCat} productos sin categoría resuelta`);
}

// ---- CSV: full (per menu-product) ----
const headersFull = ['menu','categoria_raiz','subcategoria','categoria_ruta','orden_categoria','producto','descripcion','precio','precio_num','variantes_precio','num_variantes','recomendado','nuevo','oculto_en_web','precio_oculto','num_imagenes','imagen_archivo','imagen_url','product_id','category_id','product_type'];
writeFileSync('data/menu_panisse_completo.csv', toCSV(allRows, headersFull));

// ---- CSV: unique products ----
const uniqRows = Object.values(uniqueProducts).map(u => ({ ...u.row, menus: [...u.menus].join(' | '), menu: undefined }));
const headersUniq = ['menus','categoria_raiz','subcategoria','producto','descripcion','precio','variantes_precio','recomendado','nuevo','num_imagenes','imagen_archivo','imagen_url','product_id'];
writeFileSync('data/productos_unicos.csv', toCSV(uniqRows, headersUniq));

// ---- clean normalized JSON ----
writeFileSync('data/menu_normalizado.json', JSON.stringify({
  restaurante: full.restaurant, sede: full.location,
  menus: full.menus.map(m => ({ _id: m._id, name: m.name.trim(), order: m.order, active: m.active, hide: m.hide,
    background_url: m.background_url, banner_background_url: m.banner_background_url })),
  filas: allRows,
}, null, 2));

// ---- summary ----
validation.total_filas = allRows.length;
validation.productos_unicos = Object.keys(uniqueProducts).length;
validation.filas_con_imagen = allRows.filter(r => r.num_imagenes > 0).length;
validation.productos_unicos_con_imagen = uniqRows.filter(r => r.num_imagenes > 0).length;
writeFileSync('data/validacion.json', JSON.stringify(validation, null, 2));

console.log('=== VALIDATION ===');
console.log(JSON.stringify(validation, null, 2));
console.log('\nWrote: data/menu_panisse_completo.csv, data/productos_unicos.csv, data/menu_normalizado.json, data/validacion.json');

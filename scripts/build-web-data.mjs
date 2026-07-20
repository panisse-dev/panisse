// Transforms data/raw/menus_full.json into web/src/data/menu.json (clean tree for the site)
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';

const full = JSON.parse(readFileSync('data/raw/menus_full.json', 'utf8'));

const stripHtml = (s) => (s == null ? '' : String(s)
  .replace(/<br\s*\/?>/gi, ' ')
  .replace(/<[^>]+>/g, ' ')
  .replace(/&nbsp;/gi, ' ')
  .replace(/&amp;/gi, '&')
  .replace(/\s+/g, ' ').trim());

const slugify = (s) => s.toLowerCase()
  .normalize('NFD').replace(/[̀-ͯ]/g, '')
  .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');

const MENU_CONFIG = {
  'a0cef4c4-c3ec-41c8-8f9a-0241323fcc43': { slug: 'brunch', label: 'Brunch', tagline: 'Desayunos y antojos de la mañana' },
  '4d1181ef-d153-4942-8d86-cf696890c016': { slug: 'lunch-y-dinner', label: 'Lunch y Dinner', tagline: 'Cocina italiana para almorzar y cenar' },
  '726e6ed2-70a2-40e7-b1dc-50ac007d0d76': { slug: 'vinos-y-bebidas', label: 'Vinos y Bebidas', tagline: 'Cava, coctelería y caffè' },
};

const localImage = (url, dir) => {
  if (!url) return null;
  const base = url.split('/').pop().split('?')[0];
  const rel = `/images/${dir}/${base}`;
  return existsSync(`web/public${rel}`) ? rel : null;
};

const isVeg = (p) => Array.isArray(p.tags) && p.tags.some(t => {
  const d = ((t && (t.description || t.label)) || '').toLowerCase();
  return d.startsWith('ve');
});

const mapProduct = (p) => {
  const prices = (Array.isArray(p.price) ? p.price : [])
    .filter(pr => pr && pr.disable !== true && pr.price != null)
    .map(pr => ({ label: (pr.label || '').trim(), price: pr.price, discounted: pr.discountedPrice ?? null }));
  const imgs = (Array.isArray(p.image) ? p.image : (p.image ? [p.image] : []))
    .map(im => (typeof im === 'string' ? im : im?.url || im?.src)).filter(Boolean);
  return {
    id: p._id,
    name: (p.product_name || '').trim(),
    description: stripHtml(p.description),
    prices,
    hidePrice: !!p.hidePrice,
    image: localImage(imgs[0], 'products'),
    isNew: !!p.new,
    veg: isVeg(p),
    order: p.order ?? 0,
  };
};

const warnings = [];
const outMenus = [];

for (const menu of full.menus) {
  const cfg = MENU_CONFIG[menu._id];
  if (!cfg) continue; // skip DOMICILIO (inactive delivery menu)

  // Las categorías con disabled:true están apagadas para ESTE menú (así es como la
  // plataforma muestra distinto contenido por menú sobre un catálogo duplicado).
  const cats = menu.categories
    .filter(c => !c.disabled)
    .map(c => ({ ...c, name: (c.name || '').trim() }));
  const catById = Object.fromEntries(cats.map(c => [c._id, c]));

  // Resolve orphan subcategory parents (parent doc missing from THIS menu's copy) by
  // name using other menus' category copies. Subcategories whose parent exists but is
  // disabled are dropped silently — igual que en menupp (el padre no se renderiza).
  const disabledIds = new Set(menu.categories.filter(c => c.disabled).map(c => c._id));
  const allCatsAllMenus = full.menus.flatMap(m => m.categories);
  const keptAfterParents = [];
  for (const c of cats) {
    if (c.hierarchy !== 'root' && !catById[c.hierarchy]) {
      if (disabledIds.has(c.hierarchy)) continue; // parent disabled → subcat never shows
      const parentElsewhere = allCatsAllMenus.find(x => x._id === c.hierarchy);
      const parentName = parentElsewhere ? (parentElsewhere.name || '').trim() : null;
      const sameNameRoot = parentName ? cats.find(x => x.hierarchy === 'root' && x.name === parentName) : null;
      if (sameNameRoot) {
        warnings.push(`${cfg.label}: subcategoría "${c.name}" re-vinculada a raíz "${sameNameRoot.name}" (padre original ausente)`);
        c.hierarchy = sameNameRoot._id;
      } else {
        warnings.push(`${cfg.label}: subcategoría "${c.name}" promovida a raíz (padre ausente)`);
        c.hierarchy = 'root';
      }
    }
    keptAfterParents.push(c);
  }
  cats.length = 0;
  cats.push(...keptAfterParents);

  // Deduplicate categories with identical name + parent (merge, remap products)
  const remap = {};
  const seenKey = {};
  const keptCats = [];
  for (const c of cats.sort((a, b) => (a.order ?? 0) - (b.order ?? 0))) {
    const key = `${c.hierarchy}::${c.name}`;
    // Only merge duplicate SUBcategories (same name + same parent). Root sections with the
    // same name (e.g. the two "BEBIDAS" sections) are legitimately distinct.
    if (c.hierarchy !== 'root' && seenKey[key]) {
      remap[c._id] = seenKey[key];
      warnings.push(`${cfg.label}: categoría duplicada "${c.name}" fusionada`);
    } else {
      seenKey[key] = c._id;
      keptCats.push(c);
    }
  }
  const keptById = Object.fromEntries(keptCats.map(c => [c._id, c]));

  // Assign products to categories
  const prodsByCat = {};
  let orphanProducts = 0;
  for (const p of menu.products) {
    if (p.disabled) continue; // producto apagado por el restaurante
    let cid = p.product_category;
    if (remap[cid]) cid = remap[cid];
    if (!keptById[cid]) { orphanProducts++; continue; }
    const mapped = mapProduct(p);
    // A product whose every price is disabled was switched off by the restaurant
    // (sold out / seasonal). Exclude it, but surface the decision.
    if (!mapped.hidePrice && mapped.prices.length === 0) {
      warnings.push(`${cfg.label}: "${mapped.name}" excluido (su precio está desactivado en la plataforma — plato no disponible)`);
      continue;
    }
    (prodsByCat[cid] ||= []).push(mapped);
  }
  if (orphanProducts) warnings.push(`${cfg.label}: ${orphanProducts} productos no visibles en este menú (su categoría está desactivada o eliminada para este menú — igual que en menupp)`);
  for (const arr of Object.values(prodsByCat)) arr.sort((a, b) => a.order - b.order);

  // Build tree
  const roots = keptCats.filter(c => c.hierarchy === 'root').sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  const usedSlugs = {};
  const uniqueSlug = (name) => {
    let s = slugify(name) || 'seccion';
    if (usedSlugs[s]) { usedSlugs[s]++; s = `${s}-${usedSlugs[s]}`; } else usedSlugs[s] = 1;
    return s;
  };

  const sections = [];
  for (const root of roots) {
    const subs = keptCats.filter(c => c.hierarchy === root._id).sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
    const direct = prodsByCat[root._id] || [];
    // menupp usaba col-6 (hybrid) = tarjetas y col-12 (list) = lista de ancho completo
    const layoutOf = (c) => (c.styles === 'col-6' || c.type === 'hybrid' ? 'cards' : 'list');
    const subsections = subs.map(sc => ({
      id: sc._id,
      slug: uniqueSlug(sc.name),
      name: sc.name,
      description: stripHtml(sc.description),
      layout: layoutOf(sc),
      products: prodsByCat[sc._id] || [],
    })).filter(ss => ss.products.length > 0);
    if (direct.length === 0 && subsections.length === 0) continue; // drop empty section
    sections.push({
      id: root._id,
      slug: uniqueSlug(root.name),
      name: root.name,
      description: stripHtml(root.description),
      image: localImage(root.image_url, 'categories'),
      layout: layoutOf(root),
      products: direct,
      subsections,
    });
  }

  const totalProducts = sections.reduce((s, sec) => s + sec.products.length + sec.subsections.reduce((x, ss) => x + ss.products.length, 0), 0);
  outMenus.push({
    slug: cfg.slug,
    label: cfg.label,
    tagline: cfg.tagline,
    name: menu.name.trim(),
    sections,
    totalProducts,
  });
  console.log(`${cfg.label.padEnd(16)} secciones=${sections.length}  productos=${totalProducts}`);
}

const out = {
  restaurant: {
    name: 'PANISSE',
    logo: '/images/restaurant/77690b74-5642-40b9-b93f-616216c8a646.webp',
    instagram: 'panisse.pei',
    whatsapp: '+573128179235',
    address: 'Mall Pilares del Bosque, Local 2',
    city: 'Pereira',
    currency: 'COP',
  },
  menus: outMenus,
};

mkdirSync('web/src/data', { recursive: true });
writeFileSync('web/src/data/menu.json', JSON.stringify(out, null, 1));
console.log('\nWARNINGS:');
warnings.forEach(w => console.log(' -', w));
console.log('\nWrote web/src/data/menu.json');

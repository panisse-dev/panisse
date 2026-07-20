# PANISSE — Menú digital propio

## 🌐 La página nueva (carpeta `web/`)

Sitio propio construido con **Next.js 16 + Tailwind CSS 4** (estándar actual de la industria, lo que usa Vercel). 100% estático y pre-renderizado → carga casi instantánea al escanear el QR.

- **Inicio** (`/`): logo dorado PANISSE, 3 tarjetas de menú, WhatsApp e Instagram.
- **Menús** (`/menu/brunch`, `/menu/lunch-y-dinner`, `/menu/vinos-y-bebidas`): carta tipográfica estilo italiano (papel marfil, tinta azul noche, filetes dorados), navegación sticky por secciones con scroll-spy, búsqueda por plato o ingrediente, ficha de producto con foto, insignias 🌿 vegetariano y NUEVO, y "Mi selección" (favoritos con total, para mostrar al mesero).

```bash
cd web && npm run dev    # desarrollo
cd web && npm run build  # producción
```

El contenido sale de `web/src/data/menu.json`, generado por `node scripts/build-web-data.mjs` a partir de los datos extraídos. Las imágenes viven en `web/public/images/`.

### 🗄️ Backend en Supabase

Todo el backend vive en **Supabase** (proyecto `panisse`, ref `vaefzheeuvpzmospjiee`, cuenta panisse-dev):

- **Base de datos**: `menus` / `sections` / `products` (la carta), `clients` (nombre, celular, correo, cumpleaños), `orders` + `order_items` (pedidos), `events` (analítica) y `app_config` (clave del panel).
- **La carta pública lee de la base en vivo** (`get_menu_data`): lo que se edita en el panel aparece al instante, sin redesplegar. El JSON del build (`web/src/data/menu.json`) queda solo como esqueleto de carga instantánea.
- **Seguridad**: RLS bloquea clientes/pedidos para anónimos; todas las operaciones del panel pasan por funciones `staff_*` que verifican la clave (tabla `app_config`, llave `staff_code` — ahí se cambia).
- **Fotos de productos**: bucket `product-images` (subida vía Edge Function `admin-upload`, protegida con la clave del panel).
- **Migraciones**: `supabase/migrations/` (`supabase db push` para aplicar). El seed se regenera con `node scripts/gen-supabase-seed.mjs`.

### 🧾 Pedidos + panel de administración (`/admin`)

- **Cliente**: agrega platos al carrito, hace el pedido (nombre, teléfono, nota y opcionalmente correo/cumpleaños, que alimentan la base de clientes) y ve el estado en vivo. Solo recoger en tienda; se paga al recoger.
- **Panel** (protegido con clave, réplica de menüpp):
  - **Pedidos**: tiempo real con alerta sonora, avance de estado **Recibido → En preparación → Listo → Recogido**, aviso por WhatsApp, notas internas e historial por día.
  - **Menú**: editar nombre, descripción, precios (con variantes y oferta), foto, etiquetas (Nuevo/Veg), esconder precio y mostrar/ocultar cada producto o editar categorías.
  - **Clientes**: tabla con búsqueda, # pedidos y total gastado por cliente, agregar/editar/eliminar y exportar CSV.
  - **Analítica**: visitas, sesiones, vistas de producto, pedidos, ingresos y conversión; gráficas por día/día de semana/hora, productos y categorías top, y dispositivos.

---

# Extracción completa del menú (paso 1)

Extracción del menú de PANISSE alojado en `menupp.co`, como primer paso para recrear la página en un sitio propio.

**Página original:** https://menupp.co/toscana/group/022biQOSR0vwAYqXSczE
**Fecha de extracción:** 2026-07-18
**Fuente de datos:** base de datos Firebase/Firestore del proyecto `menupp-next` (lectura pública), verificada en vivo.

---

## ✅ Qué se extrajo (todo verificado 1×1 contra la base de datos)

| Menú | Categorías | Productos | Nota |
|------|-----------:|----------:|------|
| **BRUNCH** | 59 | 251 | Menú principal (catálogo completo) |
| **LUNCH Y DINNER** | 59 | 250 | Casi idéntico a BRUNCH (247 productos compartidos) |
| **VINOS** | 27 | 130 | En la web aparece como "VINOS Y BEBIDAS" |
| **DOMICILIO** | 1 | 11 | Menú de domicilio (inactivo en la web) |
| **TOTAL filas** | — | **642** | Suma de todos los menús |
| **Productos ÚNICOS** | — | **263** | Sin duplicar entre menús |

- **49 imágenes** descargadas (44 de productos + fondos, banners y logo).
- Cada menú tiene su propia lista de productos. **BRUNCH y LUNCH Y DINNER son prácticamente el mismo menú** (el restaurante duplicó el catálogo en ambos, seguramente por horario). VINOS es un subconjunto de vinos y bebidas. DOMICILIO es el de delivery.

> **Verificación:** se volvió a consultar la base de datos en vivo y coincide al 100% en categorías, productos e imágenes. Resultado: **✅ TODO COMPLETO Y VERIFICADO**.

---

## 📁 Archivos que te sirven (carpeta `data/`)

| Archivo | Para qué |
|---------|----------|
| **`MENU_PANISSE.xlsx`** | ⭐ **Empieza por aquí.** Excel con una hoja por menú (productos agrupados por categoría, igual que la web), hoja RESUMEN y hoja de productos únicos. |
| `menu_panisse_completo.csv` | Tabla con TODAS las filas (642). Una fila por producto y menú. |
| `productos_unicos.csv` | Los 263 productos sin duplicar, con la columna "menús" indicando en cuáles aparece cada uno. |
| `menu_normalizado.json` | Datos limpios y estructurados (para construir la nueva web). |
| `validacion.json` | Reporte de validación. |
| `raw/` | Datos crudos tal cual salen de la base de datos (respaldo íntegro por menú). |

### Columnas de las tablas
`menu`, `categoria_raiz`, `subcategoria`, `categoria_ruta`, `producto`, `descripcion` (sin HTML),
`precio`, `variantes_precio` (tamaños/opciones con su precio), `recomendado`, `nuevo`,
`oculto_en_web`, `num_imagenes`, `imagen_archivo` (nombre del archivo en `images/`), `imagen_url` (original), `product_id`, `category_id`.

---

## 🖼️ Imágenes (carpeta `images/`)

- `images/products/` — 44 fotos de productos (`.webp`, 720×720). El nombre coincide con la columna `imagen_archivo` del CSV.
- `images/categories/` — imágenes de categoría.
- `images/menus/` — fondos y banners de los menús.
- `images/restaurant/` — logo de la sede y fondo decorativo.

---

## 🔧 Scripts (carpeta `scripts/`) — reproducible

| Script | Función |
|--------|---------|
| `fs-lib.mjs` | Utilidades para leer Firestore. |
| `discover.mjs` | Descubre sedes, menús y grupos. |
| `scrape-all.mjs` | Descarga todos los datos de los 4 menús. |
| `download-images.mjs` | Descarga todas las imágenes. |
| `build.mjs` | Genera los CSV y el JSON normalizado. |
| `make_xlsx.py` | Genera el Excel `MENU_PANISSE.xlsx`. |
| `validate-final.mjs` | Re-verifica todo contra la base de datos en vivo. |

Para volver a ejecutar todo:
```bash
node scripts/scrape-all.mjs && node scripts/download-images.mjs && node scripts/build.mjs && python3 scripts/make_xlsx.py && node scripts/validate-final.mjs
```

---

## ℹ️ Datos del restaurante detectados
- **Nombre:** PANISSE · **Moneda:** COP (peso colombiano) · **País:** Colombia · **Idioma:** es
- **Instagram:** @panisse.pei
- **Sede con menú:** Mall Pilares del Bosque, Local 2, Pereira · Tel/WhatsApp: +57 312 817 9235
- **Colores de marca:** dorado `#D9BB73`, oscuro `#04111D`, verde `#11572E`
- **Tipografías usadas en la web:** DM Serif Display, Playfair Display, Outfit

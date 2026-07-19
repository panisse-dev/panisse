import { getDoc, listCollection } from './fs-lib.mjs';

const REST = 'toscana';

// 1. Restaurant
const restaurant = await getDoc(`restaurants/${REST}`);
console.log('RESTAURANT:', restaurant.name, '| currency:', restaurant.currency?.value, '| locations_count:', restaurant.locations_count);

// 2. Locations
const locations = await listCollection(`restaurants/${REST}/locations`);
console.log('\nLOCATIONS:', Array.isArray(locations) ? locations.length : locations);
if (Array.isArray(locations)) {
  for (const loc of locations) {
    // menus per location
    const menus = await listCollection(`restaurants/${REST}/locations/${loc._id}/menus`, { orderBy: 'order' });
    const menuInfo = Array.isArray(menus)
      ? menus.map(m => `${m.name}(${m._id.slice(0,8)}) hide=${m.hide} active=${m.active}`)
      : JSON.stringify(menus);
    console.log(`  - ${loc.name} [${loc._id}] visibility=${loc.visibility} -> ${Array.isArray(menus)?menus.length:'?'} menus`);
    if (Array.isArray(menus)) menus.forEach(m => console.log(`       * ${m.name} | id=${m._id} | order=${m.order} | hide=${m.hide} | active=${m.active}`));
  }
}

// 3. Groups (the shared page URL used a group id)
console.log('\nGROUPS:');
for (const path of [`restaurants/${REST}/groups`, `restaurants/${REST}/locations/1vr1yK8rCvD7eaiZXHDj/groups`]) {
  const groups = await listCollection(path);
  console.log(` path=${path}:`, Array.isArray(groups) ? `${groups.length} groups` : JSON.stringify(groups));
  if (Array.isArray(groups)) groups.forEach(g => console.log('   group:', JSON.stringify(g).slice(0,400)));
}

// Direct group doc attempts
for (const path of [
  `restaurants/${REST}/groups/022biQOSR0vwAYqXSczE`,
  `groups/022biQOSR0vwAYqXSczE`,
  `restaurants/${REST}/locations/1vr1yK8rCvD7eaiZXHDj/groups/022biQOSR0vwAYqXSczE`,
]) {
  const g = await getDoc(path);
  console.log(` direct ${path}:`, g.__error ? `ERR ${g.__status}` : JSON.stringify(g).slice(0,500));
}

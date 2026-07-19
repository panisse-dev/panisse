// Shared Firestore REST helpers for the menupp-next project (PANISSE / toscana)
export const KEY = 'AIzaSyB8dEYuV3KXNySYUXBlxEqvQzWiII_r2mU';
export const PROJECT = 'menupp-next';
export const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

// Convert a Firestore REST typed value into a plain JS value
export function parseValue(v) {
  if (v == null) return null;
  if ('nullValue' in v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('timestampValue' in v) return v.timestampValue;
  if ('referenceValue' in v) return v.referenceValue;
  if ('geoPointValue' in v) return { _lat: v.geoPointValue.latitude, _long: v.geoPointValue.longitude };
  if ('bytesValue' in v) return v.bytesValue;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(parseValue);
  if ('mapValue' in v) return parseFields(v.mapValue.fields || {});
  return null;
}

export function parseFields(fields) {
  const o = {};
  for (const k of Object.keys(fields)) o[k] = parseValue(fields[k]);
  return o;
}

// Parse a full document into { _id, ...fields }
export function parseDoc(doc) {
  const id = doc.name.split('/').pop();
  return { _id: id, ...parseFields(doc.fields || {}) };
}

// Fetch a single document
export async function getDoc(path) {
  const r = await fetch(`${BASE}/${path}?key=${KEY}`);
  const j = await r.json();
  if (j.error) return { __error: j.error.message, __status: r.status };
  return parseDoc(j);
}

// List all documents in a collection (handles pagination)
export async function listCollection(path, { pageSize = 300, orderBy = null } = {}) {
  const all = [];
  let token = null, pages = 0;
  do {
    let url = `${BASE}/${path}?key=${KEY}&pageSize=${pageSize}`;
    if (orderBy) url += `&orderBy=${orderBy}`;
    if (token) url += `&pageToken=${encodeURIComponent(token)}`;
    const r = await fetch(url);
    const j = await r.json();
    if (j.error) return { __error: j.error.message, __status: r.status, partial: all };
    (j.documents || []).forEach(d => all.push(parseDoc(d)));
    token = j.nextPageToken;
    pages++;
  } while (token && pages < 50);
  return all;
}

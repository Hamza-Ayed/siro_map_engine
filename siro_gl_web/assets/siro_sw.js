// Siro GL web cache: a service worker that keeps map tiles, glyphs and
// sprites, so a map that was open once opens again without the network.
//
// Cache-first with a count limit. A hit moves the entry to the newest end, so
// the oldest entries are the ones dropped (least recently used by count).
// Only successful GET responses for map resources are stored. Everything else
// goes straight to the network.
//
// Enable it from the app's index.html; see docs/web/SERVICE_WORKER.md.

const CACHE_NAME = 'siro-gl-map-v1';
const MAX_ENTRIES = 2000;

// Tiles (.pbf, .mvt, raster images), glyph ranges and sprite sheets.
function isMapResource(url) {
  const path = new URL(url).pathname;
  return (
    /\.(pbf|mvt|png|jpe?g|webp)$/i.test(path) ||
    /\/glyphs\//.test(path) ||
    /\/sprites?\b/.test(path) ||
    /\/tiles\//.test(path)
  );
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const hit = await cache.match(request);
  if (hit) {
    // Move the entry to the newest end, so it is the last to be dropped.
    await cache.delete(request);
    await cache.put(request, hit.clone());
    return hit;
  }

  const response = await fetch(request);
  if (response.ok) {
    await cache.put(request, response.clone());
    const keys = await cache.keys();
    for (let i = 0; i < keys.length - MAX_ENTRIES; i++) {
      await cache.delete(keys[i]);
    }
  }
  return response;
}

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET' || !isMapResource(request.url)) return;
  event.respondWith(cacheFirst(request));
});

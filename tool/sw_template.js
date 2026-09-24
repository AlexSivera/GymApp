// GymApp service worker — makes the PWA open and work without a connection.
//
// GENERATED FILE: tool/generate_service_worker.dart copies this template to
// build/web/sw.js after `flutter build web`, filling in the build version
// and the precache list (every file of that build, minus the ones listed as
// excluded there). Edit the template, not build/web/sw.js.
//
// Why not Flutter's own service worker: since Flutter 3.22 it is deprecated
// and the generated flutter_service_worker.js just unregisters itself, so the
// app needed the network on every launch.
//
// Strategy
// - install: download the whole app (code, engine, fonts, images) into a
//   cache named after this build's content hash, then take over right away.
// - activate: delete caches of older builds.
// - fetch: answer from that cache first, so launching works offline and is
//   instant; anything not precached (the animated exercise GIFs, ~30 MB) is
//   cached the first time it's seen, in a cache that survives updates.
// - updates: every deploy changes this file (new hash), the browser notices on
//   the next launch and installs the new build in the background; it is used
//   from the launch after that.

const VERSION = '__VERSION__';
const PRECACHE = __PRECACHE__;
const CACHE = `gymapp-${VERSION}`;
const MEDIA_CACHE = 'gymapp-media-v1';

// Flutter's loader picks the "chromium" CanvasKit build on Chromium browsers
// and the generic one elsewhere, with this same check — so only the engine
// this browser will actually ask for is downloaded (they're ~6-7 MB each).
const isChromium = typeof Intl.v8BreakIterator !== 'undefined' && typeof Intl.Segmenter !== 'undefined';
const engineFiles = isChromium
  ? ['canvaskit/chromium/canvaskit.js', 'canvaskit/chromium/canvaskit.wasm']
  : ['canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm'];

const scopeUrl = new URL(self.registration.scope);
const toUrl = (path) => new URL(path, scopeUrl).href;

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    const files = ['./', ...PRECACHE, ...engineFiles];
    // In small batches, bypassing the HTTP cache so this build's files
    // aren't mixed with stale copies of the previous one.
    for (let i = 0; i < files.length; i += 8) {
      await Promise.all(files.slice(i, i + 8).map(async (path) => {
        const response = await fetch(new Request(toUrl(path), { cache: 'no-cache' }));
        if (!response.ok) throw new Error(`precache ${path}: ${response.status}`);
        await cache.put(toUrl(path), response);
      }));
    }
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys
      .filter((key) => key.startsWith('gymapp-') && key !== CACHE && key !== MEDIA_CACHE)
      .map((key) => caches.delete(key)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== scopeUrl.origin || !url.pathname.startsWith(scopeUrl.pathname)) return;

  // Any page load inside the app (including deep links like #/workout,
  // which share the same document) gets the cached shell.
  if (request.mode === 'navigate') {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE);
      return (await cache.match(toUrl('./'))) ||
        (await cache.match(toUrl('index.html'))) ||
        fetch(request);
    })());
    return;
  }

  event.respondWith((async () => {
    const cached = await caches.match(request, { ignoreSearch: true });
    if (cached) return cached;
    const response = await fetch(request);
    // Not part of the precache (e.g. an exercise GIF): keep it for next
    // time, offline included.
    if (response.ok && response.type === 'basic') {
      const copy = response.clone();
      caches.open(MEDIA_CACHE).then((cache) => cache.put(request, copy));
    }
    return response;
  })());
});

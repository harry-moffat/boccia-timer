"use strict";

const CACHE_NAME = "boccia-timer-shell-v1";
const APP_SHELL = [
  "./",
  "./index.html",
  "./bocciatimer.html",
  "./manifest.webmanifest",
  "./1minute.wav",
  "./30seconds.wav",
  "./timeup.wav",
  "./favicon-16.png",
  "./favicon-32.png",
  "./apple-touch-icon.png",
  "./icon-192.png",
  "./icon-512.png"
];

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache =>
      // The source tree has bocciatimer.html; the deployed artifact also has
      // index.html. Cache whichever entry points exist in the current context.
      Promise.all(APP_SHELL.map(url => cache.add(url).catch(() => undefined)))
    )
  );
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(key => key.startsWith("boccia-timer-") && key !== CACHE_NAME)
          .map(key => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== "GET" || url.origin !== self.location.origin) return;

  event.respondWith(
    fetch(request, { cache: "no-store" })
      .then(response => {
        if (response.ok) {
          return caches.open(CACHE_NAME)
            .then(cache => cache.put(request, response.clone()))
            .catch(() => undefined)
            .then(() => response);
        }
        return response;
      })
      .catch(async () => {
        const cached = await caches.match(request, { ignoreSearch: true });
        if (cached) return cached;
        if (request.mode === "navigate") {
          const fallback = (await caches.match("./index.html")) ||
                           (await caches.match("./bocciatimer.html")) ||
                           (await caches.match("./"));
          return fallback || Response.error();
        }
        return Response.error();
      })
  );
});

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project shape

One file, `bocciatimer.html` (~1090 lines): inline `<style>`, inline `<script>` (`"use strict"`, vanilla ES6), no framework, no build step, no dependencies, no tests. The only external assets are `1minute.wav`, `30seconds.wav` and `timeup.wav`, loaded by relative path, plus the favicons (`favicon-16.png`, `favicon-32.png`, `apple-touch-icon.png`) — cosmetic only, the page works without them. Keep it that way — "self-contained" is the point, since this runs from a laptop at competition venues.

`logo.svg` is the master artwork; every PNG in the folder is rendered from it (see README).

`BocciaTimer.app` is a native Dock launcher — a WKWebView window around this folder's HTML, compiled from `launcher.swift` (`./build-app.sh` builds both arches, `lipo`s them together, re-signs and probes; the universal binary is committed). It resolves the HTML from the bundle's own location rather than a hardcoded path — that is what makes the repo relocatable, so don't replace it with an absolute path. The executable bit on `Contents/MacOS/launcher` is part of the commit (mode 100755); if it is ever lost the app fails to launch with no visible error. Rebuild its icon with `iconutil -c icns` when the artwork changes.

After touching `launcher.swift` or the HTML's storage/audio/fullscreen behaviour, verify with `BocciaTimer.app/Contents/MacOS/launcher --probe` (twice — the second run's `persistPrev:"yes"` proves localStorage survives relaunch), and click "Open TV display" to confirm the second window still loads. The launcher needs `isElementFullscreenEnabled` (the page's F key uses `requestFullscreen`), `mediaTypesRequiringUserActionForPlayback = []` (the cue sounds fire without a gesture), and its `WKUIDelegate` (the TV display window); don't drop any of them when editing it. `createWebViewWith` must build its web view from the configuration WebKit hands in — a fresh one is an API violation — and must re-issue `file://` loads with `loadFileURL`, since a returned web view doesn't inherit the parent's read grant.

Almost every change lands in that one file. There is nothing to build, lint or transpile.

## Running it

`.claude/launch.json` defines a preview server named `boccia-timer`; start it with the preview tooling rather than Bash, then open http://localhost:8777/bocciatimer.html.

```bash
python3 -m http.server 8777
```

Prefer HTTP for development. `file://` also works in current Chrome (verified on 150: cues load, `localStorage` works, no console errors) and in the Dock launcher's WKWebView (verified via `--probe`). Don't assume that holds in every browser; if audio goes silent when opened directly, serve over HTTP before debugging anything else.

## Verifying changes

There is no test suite, so verify in the browser: drive the app by calling its functions directly through the JS console tool (`toggleClock('red')`, `startAux(...)`, `saveEnd()`, `state.end = 5; autoTiebreak(); renderScores()`), then assert on the DOM and check the console for errors.

Layout regressions need measuring, not eyeballing: `body` has `overflow: hidden`, so elements that collide or overflow are silently clipped rather than visibly broken. Use `getBoundingClientRect()` to check gaps between the strip's clusters, and test at 1024×600 as well as 1920×1080 — the two behave differently (see Bottom strip below).

Reset any state you set for testing, including `localStorage`, so you don't leave a fake match banked.

## Architecture

### Clocks are deadline-based

A clock stores `deadline` (a `Date.now()` timestamp) while running and `remaining` (ms) while paused; nothing decrements. A single `setInterval(tick, 100)` re-renders every clock from the current time, and is also where the 60s/30s/expiry audio cues fire. Any new countdown must be driven from `tick()` — don't add a second interval.

The warm-up/break timer (`aux`) is deliberately **not** an entry in the `clocks` map: it has no side, `playClock()`'s "pause the other side" logic assumes exactly two, and the 60-second cue in `tick()` would fire the instant a 1:00 break started. It has its own `tickAux()`, called from `tick()`. Its warning threshold is per-use: `startAux(..., warnMs)` — the Break passes 15 s, everything else defaults to 30 s.

An expired player clock flashes for `EXPIRED_FLASH_MS` (5 s, stamped in `expiredAt`) and then sits steady at 0:00; `tick()` keeps rendering a stopped clock while its `expired` class is still on so the flash can end without the clock running.

### `pauseClock(side, countBall)` — the subtlest invariant

Stopping a clock is how a throw gets counted, so every call site must classify itself:

- **Throw-flow pauses** pass `countBall = true` — the operator stopping a clock (`toggleClock`), or starting the other side (`playClock`).
- **Administrative pauses** leave it `false` — `startAux`, `openEndEntry`, `openFinal`. Warm-up or opening a dialog must never record a phantom throw. `saveEnd()` auto-starts the between-ends break (`startBreak()`), which is such a pause.

New code that pauses a clock has to make this choice deliberately.

Layered on top: the first counted throw of an end is the **jack** and is skipped (`jackThrown`), except in a tiebreak end, where the jack starts on the cross and `state.tb` suppresses the skip.

### Match state

```js
const state = { red: 0, blue: 0, end: 1, ends: [], tb: false };
```

`red`/`blue` are cumulative totals; `ends` is the per-end history (`{red, blue, tb}`). Persisted to `localStorage` under `boccia.match` on every mutation via `persistMatch()`, and restored by `loadMatch()` with type/range checks — a mid-match refresh at a venue must not lose the match. Names, countries and game time persist separately under `boccia.<field>`.

Two rules that are easy to break:

- **A tiebreak end scores no points.** `saveEnd()` pushes the entry but skips the `state.red +=` lines when `state.tb`. The tiebreak only decides the winner, which `openFinal()` resolves from the last `tb: true` entry when the totals are level.
- **`autoTiebreak()` must be called wherever the end number changes** (`endplus`, `endminus`, `saveEnd`, `resetends`). It ticks the box on ends 5 and 7; a manual override stands until the end changes again.

Manual `.scorebtn` +/− adjust totals without touching `ends`, so they remain the operator's escape hatch — the final card's totals row reads `state.red`/`state.blue`, not a sum of `ends`.

### Display mode (`?display` / `#display`)

For extended-display setups: the plain URL is the **controller** (full UI, on the laptop) and `bocciatimer.html#display` is a **passive mirror** for the TV, opened via the "Open TV display" button. Either form sets the flag, but the button opens the **hash** form — a query string is unreliable on a `file://` URL, where the path plus `?display` can be read as the filename. In the Dock app that second window exists only because `launcher.swift` adopts `WKUIDelegate`: WebKit drops `window.open()` outright without one, so removing that delegate silently kills the TV display. The button reports a null return by relabelling itself, which is what an un-rebuilt app shows. The controller owns everything — the display never runs logic, never writes `localStorage` (`persistMatch()` and the name/gametime writes are `DISPLAY`-guarded) and never plays audio (all cues route through `cue()`, which is silent when `DISPLAY`).

Sync is one-way snapshots: `broadcastState()` runs from `tick()`, serialises the full picture (`buildSnapshot()`) and sends **only when the JSON differs from the last send** — clocks store a fixed `deadline` while running, so the snapshot is stable between real events and the mirror ticks smoothly on its own local `tick()`. Transport is `BroadcastChannel('boccia')` plus `localStorage['boccia.sync']` as a storage-event fallback for `file://` and as the freshly-opened display's initial state; `loadMatch()` must never read `boccia.sync`. A new display posts `'hello'`, which the controller answers by clearing `lastSnap` so the next tick resends.

Anything new that the screen can show must be added to `buildSnapshot()` *and* `applySnapshot()`, or the TV will silently not show it. The display renders through the same functions as the controller (`renderClock`, `renderScores`, `renderBalls`, `renderFinal`, ...) — keep it that way rather than duplicating render code, and keep `renderFinal()` free of side effects (`openFinal()` = pause + `renderFinal()` + show) since the display calls it from a snapshot.

### Presentation mode

`setControlsHidden()` hides setup chrome (`#controls`, `#stripbtns`, `.adjrow`, `.scorebtn`) and is driven automatically by `fullscreenchange`, since fullscreen *is* the "put it on the TV" action. `#matchbtns` (Warm-up / Break / End Complete / Match Done) is deliberately **not** hidden — those are needed mid-match while presenting. Put new operator controls there, not in `#controls`, if they're needed during a match.

### TV-first styling

Every size is viewport-relative with a `min(Xvw, Yvh)` clamp so the layout survives both a laptop window and a 1920×1080 TV. Follow that pattern rather than fixed pixels. Colour vocabulary: panel red `#c8102e` / blue `#0033cc`; the brighter `#ff2244` / `#2266ff` for marks on black; `#ffea00` for warnings.

Overlays (`.overlay.show`) are built with `createElement`/`textContent`, never `innerHTML`, because player names are user input.

### Bottom strip centring

`#endlabel` and `#stripright` both take `flex: 1 1 0` so the ball dots land at the true centre of the bar. Neither carries `min-width: 0` — that's intentional: without it, a narrow window makes the dots slide off-centre instead of letting the button cluster overlap them. The dots only centre exactly when the side clusters fit within equal halves, which holds at 1920 in presentation mode. Widening anything in the strip can break that, so re-measure after touching it.

# Boccia Match Timer

Match timer and scoreboard for boccia, designed to be mirrored to a TV during
live matches. It is a dependency-free static web app: the interface lives in
one HTML file, with local audio, icons and offline-app support alongside it.
There is no package install or application build step.

## Use the hosted timer

Open the **[hosted Boccia Match Timer](https://harry-moffat.github.io/boccia-timer/)**.
This is the recommended way to use and share the timer. The same link works on
Mac, Windows, iPad, iPhone and Android. After the first successful online
visit, the timer is cached for offline use.

- On iPhone or iPad, open the link in Safari and choose **Share → Add to Home
  Screen**.
- In Chrome or Edge, use **Install app** from the address bar or browser menu.
- Installation is optional; the timer also works as a normal browser page.

[Download the ready-to-share QR code](BocciaTimer-share-QR.png).

The **Open TV display** button opens a passive scoreboard window to drag onto an
extended display. Allow the popup if the browser asks. The controller and TV
window must be in the same browser on the same device.

The hosted timer is deployed automatically whenever a commit is pushed to
`main`. Saving a local file alone does not publish it. A timer that is already
open is never reloaded during a match. Close and reopen it while online to get
the newest deployed version; while offline, it continues using the last cached
version.

## Running it

Open `bocciatimer.html` in a browser, or serve the folder:

```bash
python3 -m http.server 8777
```

then visit http://localhost:8777/bocciatimer.html. The three `.wav` files must
sit alongside the HTML for the audio cues to play. `manifest.webmanifest` and
`service-worker.js` provide installation and offline caching. Opening the HTML
directly with `file://` still runs the timer, but install/offline support needs
HTTP or HTTPS.

Press **F** for fullscreen, which also switches to presentation mode (setup
controls hidden). **H** toggles the controls on their own; the gear in the top
right brings them back.

## Publishing updates

GitHub Actions deploys `.github/workflows/pages.yml` on every push to `main`.
The workflow copies an explicit set of timer assets into the Pages artifact and
publishes `bocciatimer.html` as the site's root `index.html`.

To publish a change:

1. Test and commit it locally.
2. Push the commit to `main`.
3. Confirm the **Deploy to GitHub Pages** workflow succeeds in GitHub Actions.

The public URL stays the same across releases.

## From the Dock (macOS)

`BocciaTimer.app` in this folder is a small native app (source:
`launcher.swift`, universal binary committed to the repo) that shows
`bocciatimer.html` in its own window using macOS's built-in WebKit engine. No
browser is involved: it appears in Cmd-Tab and the Dock as **BocciaTimer**
with its own icon, Cmd-Q quits it, Cmd-R reloads, and ⌃⌘F (or the page's
**F** key) goes fullscreen. Requires macOS 12.3+.

It finds the HTML **relative to itself** rather than by absolute path, so the
folder can be moved, renamed or cloned onto another Mac and the app still opens
the right file — as long as `BocciaTimer.app` stays next to
`bocciatimer.html`. Move the app out on its own and it shows an alert instead.

Match state saves into the app's own WebKit storage — separate from every
browser. A match started in the app won't appear if you open the HTML in
Chrome or Safari, and vice versa.

**Open TV display** opens the scoreboard mirror as a second app window, to drag
onto a TV running as an extended display. That needs a binary built from
`launcher.swift` at or after the commit that added its `WKUIDelegate`; on an
older build the button relabels itself to *Use a browser for TV* instead of
opening anything. Rebuild with the command below to get it.

To pin it: drag `BocciaTimer.app` onto the Dock. If you later move the folder,
the existing Dock tile still points at the old location — drag it in again from
the new one.

The bundle is ad-hoc signed for local use, not notarized for public Mac
distribution. macOS may block a ZIP downloaded from GitHub. Share the hosted
web link with coaches; developers who need this launcher should clone the
repository.

After editing `launcher.swift`, rebuild the binary into the bundle:

```bash
./build-app.sh
```

That builds both architectures, combines them into a universal binary, re-signs
the bundle and runs the probe twice. To do it by hand instead (arm64 only — add
a second `-target x86_64-apple-macos12.3` build plus `lipo -create` to keep it
universal):

```bash
xcrun swiftc -O -parse-as-library launcher.swift -o BocciaTimer.app/Contents/MacOS/launcher -target arm64-apple-macos12.3 -framework Cocoa -framework WebKit && codesign --force -s - BocciaTimer.app
```

`BocciaTimer.app/Contents/MacOS/launcher --probe` prints a one-line JSON
health report (localStorage, audio cues, fullscreen, app state) and exits —
run it twice to confirm storage persists between launches.

The bundle's icon is built from `logo.svg` (see **Logo** below).

## Logo

`logo.svg` is the master artwork: a clock face split red / blue like the two
player panels, yellow ring and hands, boccia-green quarter marks, on the white
tile the other Boccia Australia apps use. The PNGs beside it
(`favicon-16`, `favicon-32`, `apple-touch-icon`, `icon-192`, `icon-512`,
`logo-1024`) are rendered from it, and the first three are referenced from the
HTML `<head>`.

To regenerate them after editing the SVG, render at 1024 and downscale:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless \
  --default-background-color=00000000 --window-size=1024,1024 \
  --screenshot=logo-1024.png logo.svg
```

then `sips -z <size> <size>` for each size, and `iconutil -c icns` over an
`AppIcon.iconset` for the Dock app's `.icns`.

## Controls

| Key / button | Action |
| --- | --- |
| **R** / **B** | Start or stop the red / blue clock (clicking a clock does the same) |
| **Warm-up 2:00** | 2-minute warm-up countdown; press again to restart it |
| **Break 1:00** | 1-minute between-ends countdown, shown with the current score |
| **End Complete** | Enter the end's score, bank it, and reset the clocks |
| **Match Done** | Final score card with the end-by-end breakdown |
| **Undo ball** | Remove the last counted ball |
| **Reset All** | Click twice: full new match — clocks, scores, end number, throw dots |

Starting a player's clock pauses the other side, and stopping a clock counts
that side's ball automatically, including the first completed clock run of an
end.

## Tiebreak ends

The **Tiebreak** checkbox ticks itself on ends 5 and 7 and can be overridden by
hand. A tiebreak end's points do not count toward the match score — it only
decides the winner, shown as a bullet on the final card.

## State

Player names, countries, game time and the current match (scores, end number,
per-end history) persist in `localStorage`, so a refresh mid-match is safe.
This data stays in that browser or app profile; it is not uploaded or shared
between devices. Clearing browser site data removes both saved match data and
the offline copy.

**Reset All** (click twice — the first click arms it) starts a new match:
clocks back to full time, scores, end number and throw dots cleared. The
individual **Reset Times / Scores / Ends** buttons reset just their own piece.

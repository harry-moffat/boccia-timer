# Boccia Match Timer

Match timer and scoreboard for boccia, designed to be mirrored to a TV during
live matches. Single self-contained HTML file — no build step, no dependencies.

## Running it

Open `bocciatimer.html` in a browser, or serve the folder:

```bash
python3 -m http.server 8777
```

then visit http://localhost:8777/bocciatimer.html. The three `.wav` files must
sit alongside the HTML for the audio cues to play.

Press **F** for fullscreen, which also switches to presentation mode (setup
controls hidden). **H** toggles the controls on their own; the gear in the top
right brings them back.

### From the Dock (macOS)

`BocciaTimer.app` in this folder is a small launcher bundle. Its
`Contents/MacOS/launcher` script opens `bocciatimer.html` in a dedicated
chromeless Chrome window (`--app=file://…`, with its own Chrome profile under
`~/Library/Application Support/BocciaTimer/`, so it never disturbs your normal
browsing session). If Chrome isn't installed it falls back to the default
browser.

It finds the HTML **relative to itself** rather than by absolute path, so the
folder can be moved, renamed or cloned onto another Mac and the app still opens
the right file — as long as `BocciaTimer.app` stays next to
`bocciatimer.html`. Move the app out on its own and it shows an alert instead.

To pin it: drag `BocciaTimer.app` onto the Dock. If you later move the folder,
the existing Dock tile still points at the old location — drag it in again from
the new one.

Note for other machines: `git clone` leaves the bundle runnable, but a ZIP
downloaded from GitHub gets quarantined and Gatekeeper will refuse to open an
unsigned app. Clone the repo rather than downloading it, or clear the flag with
`xattr -dr com.apple.quarantine BocciaTimer.app`.

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

Starting a player's clock pauses the other side, and stopping a clock counts
that side's ball automatically. The first throw of each end is the jack and is
not counted.

## Tiebreak ends

The **Tiebreak** checkbox ticks itself on ends 5 and 7 and can be overridden by
hand. In a tiebreak end the jack starts on the cross, so no jack throw is
skipped, and the end's points do not count toward the match score — it only
decides the winner, shown as a bullet on the final card.

## State

Player names, countries, game time and the current match (scores, end number,
per-end history) persist in `localStorage`, so a refresh mid-match is safe.
**Reset Scores** clears the match and starts a new one.

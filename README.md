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

`/Applications/BocciaTimer.app` is a small launcher bundle — it isn't part of
this repo. Its `Contents/MacOS/launcher` script opens this folder's
`bocciatimer.html` in a dedicated chromeless Chrome window
(`--app=file://…`, with its own Chrome profile under
`~/Library/Application Support/BocciaTimer/`). Edit the `TIMER` path in that
script if this folder ever moves; the launcher shows an alert if the file has
gone missing, and falls back to the default browser if Chrome isn't installed.

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

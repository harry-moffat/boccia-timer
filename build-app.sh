#!/bin/bash
# Rebuild BocciaTimer.app's binary from launcher.swift.
#
# Only needed after editing launcher.swift — the HTML, audio and icons are all
# read at runtime, so changing those needs nothing but a reload. Keeps the
# binary universal (Apple Silicon + Intel) so the committed bundle stays
# runnable on any Mac, then re-signs the bundle and checks the result.
#
# Usage:  ./build-app.sh
# Requires the Xcode command line tools (xcode-select --install).

set -euo pipefail
cd "$(dirname "$0")"

BIN="BocciaTimer.app/Contents/MacOS/launcher"
DEPLOY="12.3"

if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "error: Swift compiler not found. Install the Xcode command line tools:" >&2
  echo "       xcode-select --install" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for arch in arm64 x86_64; do
  echo "building $arch..."
  xcrun swiftc -O -parse-as-library launcher.swift \
    -o "$tmp/launcher-$arch" \
    -target "$arch-apple-macos$DEPLOY" \
    -framework Cocoa -framework WebKit
done

echo "combining into a universal binary..."
lipo -create "$tmp/launcher-arm64" "$tmp/launcher-x86_64" -output "$BIN"
chmod 755 "$BIN"          # losing this makes the app fail to launch with no error
codesign --force -s - BocciaTimer.app

echo
lipo -info "$BIN"

# Two runs: the second proves localStorage survived the first, which is what
# keeps a match alive across a relaunch at a venue.
echo
echo "probe 1 of 2 (expect persistPrev:null on a clean profile)..."
"$BIN" --probe
echo "probe 2 of 2 (expect persistPrev:\"yes\")..."
"$BIN" --probe

echo
echo 'Built. Open BocciaTimer.app and click "Open TV display" to check the second window.'

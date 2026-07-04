#!/usr/bin/env bash
# Verify a web-deck build: renderers run, external images resolve, and the
# real print pipeline paginates one section per page.
# Usage: verify.sh <deck.html> [raster-dir]
#   raster-dir: also rasterize the PDF pages there (needs pdftoppm) for eyeballing
set -euo pipefail

deck="${1:?usage: verify.sh <deck.html> [raster-dir]}"
raster="${2:-}"
deck="$(cd "$(dirname "$deck")" && pwd)/$(basename "$deck")"

chrome=""
for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
         "$(command -v google-chrome || true)" \
         "$(command -v chromium || true)"; do
  [ -n "$c" ] && [ -x "$c" ] && chrome="$c" && break
done
[ -n "$chrome" ] || { echo "FAIL: no Chrome/Chromium binary found"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# 1. renderers + engine produce sections (count them outside <script> blocks,
#    where renderer template literals would inflate a naive grep)
"$chrome" --headless --disable-gpu --virtual-time-budget=5000 \
  --dump-dom "file://$deck" > "$tmp/dom.html" 2>/dev/null
sections=$(python3 - "$tmp/dom.html" <<'PY'
import re, sys
d = open(sys.argv[1]).read()
d = re.sub(r'<script.*?</script>', '', d, flags=re.S)
print(len(re.findall(r'<section\b', d)))
PY
)
[ "$sections" -gt 0 ] || { echo "FAIL: no <section> rendered — engine error? Check the browser console."; exit 1; }
echo "ok: $sections sections rendered"

# 2. external images resolve (warn-only: may be offline)
grep -oE 'https://[^ )"'\''<]+' "$deck" | sort -u | while read -r url; do
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$url" || echo 000)
  [ "$code" = 200 ] || echo "warn: $url -> HTTP $code"
done

# 3. real print pipeline: one page per section, or a section overflows
"$chrome" --headless --disable-gpu --virtual-time-budget=5000 \
  --print-to-pdf="$tmp/deck.pdf" --no-pdf-header-footer "file://$deck" 2>/dev/null
pages=$(python3 - "$tmp/deck.pdf" <<'PY'
import re, sys
d = open(sys.argv[1], 'rb').read()
print(len(re.findall(rb'/Type\s*/Page\b(?!s)', d)))
PY
)
if [ "$pages" -ne "$sections" ]; then
  echo "FAIL: $pages PDF pages != $sections sections — a section overflows its page"
  exit 1
fi
echo "ok: print paginates 1:1 ($pages pages)"

# 4. rasterize for eyeballing (optional)
if [ -n "$raster" ]; then
  if command -v pdftoppm >/dev/null; then
    mkdir -p "$raster"
    pdftoppm -png -r 40 "$tmp/deck.pdf" "$raster/page"
    echo "ok: rasterized pages -> $raster/"
  else
    echo "warn: pdftoppm not found, skipping rasterization"
  fi
fi
echo "PASS"

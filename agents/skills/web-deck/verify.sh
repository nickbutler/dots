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

# 4. content actually FITS its page. Page count alone cannot catch this: the
#    print rules give each section a fixed height with overflow hidden, so an
#    overlong section still paginates 1:1 while silently clipping whatever
#    ran past the bottom. Rewrite @media print as @media screen so the real
#    print rules apply on screen at the page size, then compare each
#    section's content height against its box.
python3 - "$deck" "$tmp/fit.html" <<'PY'
import sys
src = open(sys.argv[1]).read()
src = src.replace('@media print', '@media screen')
# the LAST </body> only: the presenter window builds its own document with
# document.write, so an earlier </body> lives inside a template literal — and
# a </script> injected in there closes the engine's own script element
cut = src.rfind('</body>')
src = src[:cut] + '''<script>
/* static mode is what print renders: scrubs flattened, reveals shown */
if (window.staticMode) staticMode(); else document.documentElement.classList.add("static");
/* decorative pseudo-element bleed is not content — it is allowed past the edge */
var s = document.createElement("style");
s.textContent = "section::before,section::after{display:none!important}";
document.head.appendChild(s);
addEventListener("load", function () {
  var rows = [].map.call(document.querySelectorAll("section"), function (n, i) {
    return [i + 1, n.id || "?", n.scrollHeight, n.clientHeight];
  });
  var d = document.createElement("div");
  d.id = "__fit";
  d.textContent = JSON.stringify(rows);
  document.body.appendChild(d);
});
</script>''' + src[cut:]
open(sys.argv[2], 'w').write(src)
PY
"$chrome" --headless --disable-gpu --virtual-time-budget=5000 --window-size=1920,1080 \
  --dump-dom "file://$tmp/fit.html" > "$tmp/fit-dom.html" 2>/dev/null
python3 - "$tmp/fit-dom.html" <<'PY' || exit 1
import json, re, sys
d = open(sys.argv[1]).read()
m = re.search(r'<div id="__fit">(.*?)</div>', d, re.S)
if not m:
    print("FAIL: fit harness did not run — the measurement build is broken")
    sys.exit(1)
rows = json.loads(m.group(1))
# an empty list is a broken harness, not a clean deck — never pass on it
if not rows:
    print("FAIL: fit harness measured 0 sections — the engine did not render")
    sys.exit(1)
bad = [r for r in rows if r[2] - r[3] > 4]
for n, sid, sh, ch in bad:
    print("FAIL: section %d (#%s) overflows its page by %dpx — it will be clipped in the PDF"
          % (n, sid, sh - ch))
if bad:
    sys.exit(1)
print("ok: every section fits its page")
PY

# 5. rasterize for eyeballing (optional)
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

#!/usr/bin/env bash
# Reports everything standing between this package and a real-domain launch.
# Run from inside the site folder:  ./prelaunch-check.sh
# Exit 0 = clear to launch. Exit 1 = something below still needs doing.

cd "$(dirname "$0")" || exit 2
fail=0
say() { printf '%s\n' "$*"; }
bad() { printf '  [BLOCKS LAUNCH] %s\n' "$*"; fail=1; }
ok()  { printf '  [ok] %s\n' "$*"; }

say ""
say "Pre-launch check: $(basename "$PWD")"
say "============================================================"

say ""
say "1. Search engine visibility"
n=$(grep -rl 'name="robots"[^>]*noindex' --include='*.html' . 2>/dev/null \
    | grep -v '404.html' | grep -v 'review.html' | wc -l)
if [ "$n" -gt 0 ]; then
  bad "noindex is still on $n page(s) — the site will be invisible to Google:"
  grep -rl 'name="robots"[^>]*noindex' --include='*.html' . 2>/dev/null \
    | grep -v '404.html' | grep -v 'review.html' | sed 's/^/      /'
else
  ok "no stray noindex on indexable pages"
fi

if grep -q '^[[:space:]]*Disallow:[[:space:]]*/[[:space:]]*$' robots.txt 2>/dev/null; then
  bad "robots.txt still blocks the whole site (Disallow: /)"
else
  ok "robots.txt allows crawling"
fi

say ""
say "2. Unverified claims"
n=$(grep -ro '\[CONFIRM\]' --include='*.html' . 2>/dev/null | wc -l)
if [ "$n" -gt 0 ]; then
  bad "$n [CONFIRM] marker(s) left — each is a fact nobody has verified:"
  grep -rn '\[CONFIRM\]' --include='*.html' . 2>/dev/null \
    | cut -c1-110 | sed 's/^/      /'
else
  ok "no [CONFIRM] markers left"
fi

say ""
say "3. Placeholder contact details"
if grep -rqo '555-01[0-9][0-9]' --include='*.html' . 2>/dev/null; then
  bad "fictional 555-01xx phone number still in the markup:"
  grep -rno '555-01[0-9][0-9]' --include='*.html' . 2>/dev/null \
    | sort -u | sed 's/^/      /'
else
  ok "no fictional phone numbers"
# "you@example.com" in a form placeholder is RFC-2606 correct, not a leftover.
dom=$(grep -rni 'YOURDOMAIN\|example\.com' --include='*.html' --include='*.xml' --include='*.txt' . 2>/dev/null \
      | grep -vi 'placeholder="you@example\.com"')
if [ -n "$dom" ]; then
  bad "placeholder domain still referenced:"
  printf '%s\n' "$dom" | cut -c1-110 | sed 's/^/      /'
else
  ok "no placeholder domains"
fi
fi

say ""
say "4. Page weight"
big=$(find . -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) -size +400k 2>/dev/null)
if [ -n "$big" ]; then
  say "  [warn] images over 400 KB — convert to WebP before launch (not blocking):"
  printf '%s\n' "$big" | while read -r f; do
    printf '      %s  %s\n' "$(du -h "$f" | cut -f1)" "$f"
  done
else
  ok "no oversized images"
fi

say ""
say "============================================================"
if [ "$fail" -eq 0 ]; then
  say "CLEAR TO LAUNCH."
else
  say "NOT READY — fix the [BLOCKS LAUNCH] items above."
fi
say ""
exit "$fail"

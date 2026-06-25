#!/usr/bin/env bash
# Hermetic regression test for scripts/is-superseded.sh — the version-comparison predicate behind
# close-superseded-cask-bumps.yaml's destructive close/keep decision. No network, no gh, no Homebrew:
# pure version math. A bug here would either orphan superseded bumps (the problem the workflow solves)
# or, worse, CLOSE a genuinely-newer pending bump (losing a release), so the behavior is pinned here.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/../scripts/is-superseded.sh"

fail=0

# assert_superseded <candidate> <current> — expect exit 0 (close the bump PR).
assert_superseded() {
  if bash "$script" "$1" "$2"; then
    echo "ok: v$1 superseded by v$2 → close"
  else
    echo "FAIL: expected v$1 to be superseded by v$2 (close), but the script kept it"
    fail=1
  fi
}

# assert_kept <candidate> <current> — expect exit 1 (keep the bump PR).
assert_kept() {
  if bash "$script" "$1" "$2"; then
    echo "FAIL: expected v$1 to be kept over v$2 (newer), but the script closed it"
    fail=1
  else
    echo "ok: v$1 kept over v$2 → keep"
  fi
}

# An older bump is superseded by the version on main.
assert_superseded 7.39.0 7.53.2
# The same version as main is redundant → superseded.
assert_superseded 7.53.2 7.53.2
# A genuinely-newer pending bump is kept (the case the workflow must never close).
assert_kept 7.54.0 7.53.2
# Version-aware ordering, NOT lexical: 7.9.0 < 7.53.2 (a lexical sort would rank "9" above "53").
assert_superseded 7.9.0 7.53.2
# Version-aware ordering, NOT lexical: 7.100.0 > 7.99.0 (a lexical sort would rank "100" below "99").
assert_kept 7.100.0 7.99.0
# Patch-level boundaries either side of main.
assert_superseded 7.53.1 7.53.2
assert_kept 7.53.3 7.53.2

# Wrong argument count is a usage error (exit 2) — neither close nor keep.
if bash "$script" 7.0.0 >/dev/null 2>&1; then
  echo "FAIL: expected a usage error when called with a missing argument"
  fail=1
else
  echo "ok: missing argument rejected with a usage error"
fi

if [ "$fail" -ne 0 ]; then
  echo "is-superseded.test.sh: FAILURES"
  exit 1
fi
echo "is-superseded.test.sh: all cases passed"

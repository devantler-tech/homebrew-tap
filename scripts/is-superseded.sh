#!/usr/bin/env bash
# Decide whether a candidate Cask-bump version is superseded by the version already on `main`.
#
#   is-superseded.sh <candidate-version> <current-version>
#     exit 0  → candidate <= current  (superseded/redundant — close its bump PR)
#     exit 1  → candidate >  current  (genuinely newer — keep its bump PR)
#     exit 2  → usage error (wrong number of arguments)
#
# This is the version-comparison predicate behind `.github/workflows/close-superseded-cask-bumps.yaml`,
# extracted so the destructive close/keep decision has a single source of truth that
# `test/is-superseded.test.sh` can exercise hermetically. A bug here would either orphan superseded
# bumps (the problem the workflow solves) or — worse — CLOSE a genuinely-newer pending bump, losing a
# release, so the comparison is pinned by tests.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: is-superseded.sh <candidate-version> <current-version>" >&2
  exit 2
fi

candidate="$1"
current="$2"

# `sort -V` is version-aware — 7.9.0 < 7.53.2 and 7.100.0 > 7.99.0, where a lexical sort would be
# wrong. If the maximum of {candidate, current} is `current`, then candidate <= current → superseded
# (or, when equal, redundant). Otherwise candidate is the newer pending bump and is kept.
if [ "$(printf '%s\n%s\n' "$candidate" "$current" | sort -V | tail -1)" = "$current" ]; then
  exit 0
fi
exit 1

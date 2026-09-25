#!/usr/bin/env bash
# List the Casks one change adds or modifies, between two immutable commits, one path per line.
#
# The scope matches GitHub's three-dot pull-request diff: from the merge base of <base-sha> and
# <head-sha> to <head-sha>. Deleted Casks are left out because there is nothing left to check. The
# style gate checks only these Casks, so a change that touches no Cask cannot fail on another
# Cask's style. Drift in untouched Casks is reported by the scheduled full check on main.
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: changed-casks.sh <base-sha> <head-sha> <manifest>" >&2
  exit 2
fi

base_sha="$1"
head_sha="$2"
manifest="$3"

for named_sha in "base:$base_sha" "head:$head_sha"; do
  sha_name="${named_sha%%:*}"
  sha_value="${named_sha#*:}"
  if [[ ! "$sha_value" =~ ^[0-9a-f]{40}$ ]]; then
    echo "BLOCKED: invalid $sha_name commit SHA: $sha_value" >&2
    exit 2
  fi
done
if [ -z "$manifest" ]; then
  echo "BLOCKED: a manifest path is required" >&2
  exit 2
fi

if ! git cat-file -e "${base_sha}^{commit}" 2>/dev/null \
  || ! git cat-file -e "${head_sha}^{commit}" 2>/dev/null; then
  echo "BLOCKED: immutable base/head history is unavailable" >&2
  exit 1
fi
if ! merge_base="$(git merge-base "$base_sha" "$head_sha")" || [ -z "$merge_base" ]; then
  echo "BLOCKED: could not resolve the merge base" >&2
  exit 1
fi

changed_paths="$(mktemp)"
trap 'rm -f "$changed_paths"' EXIT
# -z keeps every filename boundary, including a newline inside a name.
if ! git diff --name-only -z --diff-filter=ACMRTUXB "$merge_base" "$head_sha" -- >"$changed_paths"; then
  echo "BLOCKED: could not enumerate changed paths" >&2
  exit 1
fi

: >"$manifest"
while IFS= read -r -d '' changed_file; do
  case "$changed_file" in
    Casks/*)
      # A Cask is a single file directly beneath Casks/. A nested path, whitespace, a newline, a
      # shell metacharacter or a missing file stops the run instead of being interpreted.
      if [[ ! "$changed_file" =~ ^Casks/[A-Za-z0-9][A-Za-z0-9._+-]*\.rb$ ]] \
        || [ ! -f "$changed_file" ]; then
        : >"$manifest"
        echo "BLOCKED: unsafe or missing changed Cask path: $changed_file" >&2
        exit 1
      fi
      if ! grep -Fqx -- "$changed_file" "$manifest"; then
        printf '%s\n' "$changed_file" >>"$manifest"
      fi
      ;;
  esac
done <"$changed_paths"

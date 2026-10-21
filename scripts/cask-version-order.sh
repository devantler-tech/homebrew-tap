#!/usr/bin/env bash
# Refuse a change that moves a Cask to an older version than the base branch already ships.
#
# usage: cask-version-order.sh <base-sha> <head-sha>
#
# Every Cask the change adds or modifies (the same scope as scripts/changed-casks.sh) is compared
# with the same Cask at <base-sha>, the tip of the branch the change merges into. A Cask that does
# not exist at <base-sha> is new and passes. Otherwise the head version must be at least the base
# version:
#   - a higher or identical version passes;
#   - a lower version fails;
#   - a prerelease (a version with a `-suffix`) never replaces the stable version it precedes.
# The release pipeline normally skips older tags itself; this is the boundary every release run
# crosses, including a retry of a run that started before that pipeline check existed.
#
# Exit status: 0 every changed Cask moves forward or stays put; 1 a Cask would move backward;
# 2 a version could not be read or ordered, which is never treated as a pass.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: cask-version-order.sh <base-sha> <head-sha>" >&2
  exit 2
fi

base_sha="$1"
head_sha="$2"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

scope="$(mktemp)"
trap 'rm -f "$scope"' EXIT
if ! bash "$here/changed-casks.sh" "$base_sha" "$head_sha" "$scope"; then
  echo "BLOCKED: could not list the changed Casks" >&2
  exit 2
fi

# Print the single `version "<value>"` stanza of a Cask blob, or fail.
read_version() {
  local blob="$1" lines count
  lines="$(printf '%s\n' "$blob" | sed -nE 's/^[[:space:]]*version[[:space:]]+"([^"]*)"[[:space:]]*$/\1/p')"
  count="$(printf '%s' "$lines" | grep -c '' || true)"
  if [ "$count" -ne 1 ]; then
    return 1
  fi
  if [[ ! "$lines" =~ ^[0-9]{1,15}(\.[0-9]{1,15})*(-[0-9A-Za-z.]+)?$ ]]; then
    return 1
  fi
  printf '%s\n' "$lines"
}

# Compare two dotted numeric cores. Prints -1, 0 or 1.
compare_core() {
  local -a left right
  local i width a b
  IFS=. read -r -a left <<<"$1"
  IFS=. read -r -a right <<<"$2"
  width=${#left[@]}
  if [ "${#right[@]}" -gt "$width" ]; then
    width=${#right[@]}
  fi
  for ((i = 0; i < width; i++)); do
    a=$((10#${left[i]:-0}))
    b=$((10#${right[i]:-0}))
    if [ "$a" -lt "$b" ]; then
      echo -1
      return
    fi
    if [ "$a" -gt "$b" ]; then
      echo 1
      return
    fi
  done
  echo 0
}

status=0
checked=0
while IFS= read -r cask; do
  checked=$((checked + 1))
  if ! git cat-file -e "${base_sha}:${cask}" 2>/dev/null; then
    echo "ok    ${cask}: new Cask"
    continue
  fi
  if ! base_blob="$(git show "${base_sha}:${cask}")" || ! base_version="$(read_version "$base_blob")"; then
    echo "BLOCKED: ${cask}: cannot read one plain version at the base" >&2
    status=2
    continue
  fi
  if ! head_blob="$(git show "${head_sha}:${cask}")" || ! head_version="$(read_version "$head_blob")"; then
    echo "BLOCKED: ${cask}: cannot read one plain version at the head" >&2
    status=2
    continue
  fi
  if [ "$head_version" = "$base_version" ]; then
    echo "ok    ${cask}: stays at ${base_version}"
    continue
  fi

  base_core="${base_version%%-*}"
  head_core="${head_version%%-*}"
  order="$(compare_core "$head_core" "$base_core")"
  head_pre=false
  base_pre=false
  [ "$head_core" != "$head_version" ] && head_pre=true
  [ "$base_core" != "$base_version" ] && base_pre=true

  if [ "$order" = -1 ]; then
    echo "FAIL: ${cask}: ${head_version} is older than ${base_version} on the base branch" >&2
    [ "$status" -eq 0 ] && status=1
  elif [ "$order" = 0 ] && [ "$head_pre" = true ] && [ "$base_pre" = false ]; then
    echo "FAIL: ${cask}: prerelease ${head_version} would replace stable ${base_version}" >&2
    [ "$status" -eq 0 ] && status=1
  elif [ "$order" = 0 ] && [ "$head_pre" = true ]; then
    echo "BLOCKED: ${cask}: cannot order prereleases ${head_version} and ${base_version}" >&2
    status=2
  else
    echo "ok    ${cask}: ${base_version} -> ${head_version}"
  fi
done <"$scope"

echo "CHECKED ${checked} changed Cask(s)"
exit "$status"

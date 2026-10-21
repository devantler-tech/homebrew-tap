#!/usr/bin/env bash
# Hermetic regression tests for the Cask version-order gate: a change may move a Cask forward or
# leave it alone, never back, and an unreadable version is never a pass.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/../scripts/cask-version-order.sh"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
fail=0

cask_body() {
  printf 'cask "target" do\n  version "%s"\n  sha256 "0"\nend\n' "$1"
}

# A repository whose base commit ships Casks/target.rb at <base-version> (or no Cask when empty),
# and whose head commit sets it to <head-version>. Prints "<root> <base-sha> <head-sha>".
fixture() {
  local name="$1" base_version="$2" head_body="$3" root="$scratch/$1"
  mkdir -p "$root/Casks"
  printf 'fixture\n' >"$root/README.md"
  if [ -n "$base_version" ]; then
    cask_body "$base_version" >"$root/Casks/target.rb"
  fi
  (
    cd "$root"
    git init -q
    git config user.name fixture
    git config user.email fixture@example.invalid
    git add -A
    git commit -qm base
    printf '%s' "$head_body" >Casks/target.rb
    git add -A
    git commit -qm head
    printf '%s %s %s\n' "$root" "$(git rev-parse HEAD~1)" "$(git rev-parse HEAD)"
  ) || {
    echo "FAIL: could not build fixture $name" >&2
    exit 1
  }
}

expect() {
  local name="$1" want="$2" base_version="$3" head_body="$4" root base head got
  read -r root base head < <(fixture "$name" "$base_version" "$head_body")
  set +e
  (cd "$root" && bash "$script" "$base" "$head") >"$scratch/$name.out" 2>&1
  got=$?
  set -e
  if [ "$got" -ne "$want" ]; then
    echo "FAIL: $name: expected exit $want, got $got"
    sed 's/^/    /' "$scratch/$name.out"
    fail=1
  else
    echo "ok    $name (exit $got)"
  fi
}

expect newer-version 0 7.204.4 "$(cask_body 7.205.0)"
expect equal-version 0 7.204.4 "$(cask_body 7.204.4)"
expect wider-newer-version 0 7.204 "$(cask_body 7.204.1)"
expect numeric-not-lexical 0 7.9.0 "$(cask_body 7.10.0)"
expect new-cask 0 "" "$(cask_body 1.0.0)"
expect new-cask-latest-version 2 "" $'cask "target" do\n  version :latest\nend\n'
expect new-cask-missing-version 2 "" $'cask "target" do\n  sha256 "0"\nend\n'
expect stable-after-its-prerelease 0 7.205.0-rc.1 "$(cask_body 7.205.0)"
expect older-retry 1 7.204.4 "$(cask_body 7.204.1)"
expect older-major 1 8.0.0 "$(cask_body 7.999.999)"
expect prerelease-over-stable 1 7.205.0 "$(cask_body 7.205.0-rc.1)"
expect older-prerelease 1 7.205.0 "$(cask_body 7.204.0-rc.1)"
expect unordered-prereleases 2 7.205.0-rc.1 "$(cask_body 7.205.0-rc.2)"
expect missing-head-version 2 7.204.4 $'cask "target" do\n  sha256 "0"\nend\n'
expect duplicate-head-version 2 7.204.4 "$(cask_body 7.205.0)"$'\n  version "7.206.0"\n'
expect latest-head-version 2 7.204.4 $'cask "target" do\n  version :latest\nend\n'
expect unparsable-head-version 2 7.204.4 "$(cask_body 'v7.205.0')"

# The usage contract: anything other than two arguments is refused, never a pass.
set +e
bash "$script" >/dev/null 2>&1
got=$?
set -e
if [ "$got" -ne 2 ]; then
  echo "FAIL: bad usage: expected exit 2, got $got"
  fail=1
else
  echo "ok    bad-usage (exit 2)"
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "Cask version-order tests passed."

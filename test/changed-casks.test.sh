#!/usr/bin/env bash
# Hermetic regression tests for the Cask style scope: the gate checks only the Casks a change adds or
# modifies, and a scheduled full check on main reports drift in the rest.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/../scripts/changed-casks.sh"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
fail=0

new_fixture() {
  local root="$scratch/$1"
  mkdir -p "$root/Casks"
  printf 'target\n' >"$root/Casks/target.rb"
  printf 'sibling\n' >"$root/Casks/sibling.rb"
  printf 'fixture\n' >"$root/README.md"
  (
    cd "$root"
    git init -q
    git config user.name fixture
    git config user.email fixture@example.invalid
    git add Casks README.md
    git commit -qm fixture
  )
  printf '%s\n' "$root"
}

commit_in() {
  local root="$1" message="$2"
  shift 2
  (
    cd "$root"
    "$@"
    git add -A
    git commit -qm "$message"
  )
}

run_scope() {
  local root="$1" base="$2" head="$3"
  (cd "$root" && bash "$script" "$base" "$head" "$root/scope")
}

head_of() {
  (cd "$1" && git rev-parse HEAD)
}

assert_lists_only_changed_casks() {
  local root base head
  root="$(new_fixture changed)"
  base="$(head_of "$root")"
  commit_in "$root" target sh -c 'printf "update\n" >>Casks/target.rb; printf "docs\n" >>README.md'
  head="$(head_of "$root")"
  if ! run_scope "$root" "$base" "$head"; then
    echo "FAIL: a valid Cask change was rejected"
    fail=1
  elif [ "$(cat "$root/scope")" != 'Casks/target.rb' ]; then
    echo "FAIL: expected only Casks/target.rb in scope, got: $(tr '\n' ' ' <"$root/scope")"
    fail=1
  else
    echo "ok: only the changed Cask is in scope"
  fi
}

assert_no_cask_change_is_empty() {
  local root base head
  root="$(new_fixture no-cask)"
  base="$(head_of "$root")"
  commit_in "$root" docs sh -c 'printf "docs\n" >>README.md'
  head="$(head_of "$root")"
  if ! run_scope "$root" "$base" "$head"; then
    echo "FAIL: a change without Casks was rejected"
    fail=1
  elif [ -s "$root/scope" ]; then
    echo "FAIL: a change without Casks produced a non-empty scope"
    fail=1
  else
    echo "ok: a change without Casks has an empty scope"
  fi
}

assert_deleted_and_renamed_casks() {
  local root base head
  root="$(new_fixture rename-delete)"
  base="$(head_of "$root")"
  commit_in "$root" rename-delete sh -c 'git rm -q Casks/sibling.rb; git mv Casks/target.rb Casks/renamed.rb'
  head="$(head_of "$root")"
  if ! run_scope "$root" "$base" "$head"; then
    echo "FAIL: a rename and a deletion were rejected"
    fail=1
  elif [ "$(cat "$root/scope")" != 'Casks/renamed.rb' ]; then
    echo "FAIL: expected only the renamed Cask in scope, got: $(tr '\n' ' ' <"$root/scope")"
    fail=1
  else
    echo "ok: a renamed Cask is in scope and a deleted one is not"
  fi
}

assert_scope_follows_the_merge_base() {
  local root base head
  root="$(new_fixture merge-base)"
  base="$(head_of "$root")"
  commit_in "$root" change-target sh -c 'printf "update\n" >>Casks/target.rb'
  head="$(head_of "$root")"
  # The base branch moves on after the change was cut; its Cask edit is not the change's.
  (
    cd "$root"
    git checkout -q -b base-moved "$base"
    printf 'base-only\n' >>Casks/sibling.rb
    git add Casks/sibling.rb
    git commit -qm base-only
    git checkout -q "$head"
  )
  base="$(cd "$root" && git rev-parse base-moved)"
  if ! run_scope "$root" "$base" "$head"; then
    echo "FAIL: a change behind its base was rejected"
    fail=1
  elif [ "$(cat "$root/scope")" != 'Casks/target.rb' ]; then
    echo "FAIL: a base-branch Cask edit leaked into scope: $(tr '\n' ' ' <"$root/scope")"
    fail=1
  else
    echo "ok: scope is measured from the merge base, as a pull request diff is"
  fi
}

assert_unsafe_paths_are_fatal() {
  local root base head name
  for name in nested newline; do
    root="$(new_fixture "unsafe-$name")"
    base="$(head_of "$root")"
    case "$name" in
      nested) commit_in "$root" nested sh -c 'mkdir -p Casks/sub; printf "x\n" >Casks/sub/nested.rb' ;;
      newline) commit_in "$root" newline sh -c 'mkdir -p "Casks/target.rb
Casks"; printf "x\n" >"Casks/target.rb
Casks/sibling.rb"' ;;
    esac
    head="$(head_of "$root")"
    if run_scope "$root" "$base" "$head" >/dev/null 2>&1; then
      echo "FAIL: an unsafe $name Cask path was accepted"
      fail=1
    elif [ -s "$root/scope" ]; then
      echo "FAIL: an unsafe $name Cask path left a partial scope behind"
      fail=1
    else
      echo "ok: an unsafe $name Cask path stops the run with an empty scope"
    fi
  done
}

assert_missing_history_is_fatal() {
  local root head
  root="$(new_fixture missing-history)"
  commit_in "$root" target sh -c 'printf "update\n" >>Casks/target.rb'
  head="$(head_of "$root")"
  if run_scope "$root" ffffffffffffffffffffffffffffffffffffffff "$head" >/dev/null 2>&1; then
    echo "FAIL: a missing base commit was accepted"
    fail=1
  else
    echo "ok: missing history stops the run"
  fi
  if run_scope "$root" "$head" not-a-sha >/dev/null 2>&1; then
    echo "FAIL: a malformed head SHA was accepted"
    fail=1
  else
    echo "ok: a malformed SHA is refused"
  fi
}

assert_workflow_contract() {
  local ci drift style_block
  ci="$here/../.github/workflows/ci.yaml"
  drift="$here/../.github/workflows/style-drift.yaml"
  style_block="$(sed -n '/- name: 📥 Checkout (fork PR/,/^  test-scripts:/p' "$ci")"

  # Literal GitHub/shell expressions are the workflow contract, not values for this test to expand.
  # shellcheck disable=SC2016
  if ! grep -Fq 'fetch-depth: 0' <<<"$style_block"; then
    echo "FAIL: the read-only checkout does not fetch the history the scope needs"
    fail=1
  elif ! grep -Fq 'SCOPE_BASE: ${{ github.event.pull_request.base.sha || github.event.merge_group.base_sha }}' <<<"$style_block" \
    || ! grep -Fq 'SCOPE_HEAD: ${{ github.event.pull_request.head.sha || github.event.merge_group.head_sha }}' <<<"$style_block"; then
    echo "FAIL: the style scope is not bound to the event's base and head"
    fail=1
  elif [ "$(grep -Fc 'bash scripts/changed-casks.sh "$SCOPE_BASE" "$SCOPE_HEAD" "$SCOPE_MANIFEST"' <<<"$style_block")" -ne 2 ]; then
    echo "FAIL: the check-only fix and the gate do not both use the change's scope"
    fail=1
  elif grep -Fq 'brew style --fix ./Casks/' <<<"$style_block" \
    || grep -Eq 'brew style \./Casks/?$' <<<"$style_block"; then
    echo "FAIL: a pull request or merge group still style-checks Casks it did not change"
    fail=1
  elif ! [ -f "$drift" ]; then
    echo "FAIL: nothing checks the whole Cask tree on main"
    fail=1
  elif ! grep -Eq '^\s+branches: \[main\]$' "$drift" \
    || ! grep -Eq '^\s+- cron: ' "$drift" \
    || ! grep -Fq 'run: brew style ./Casks/' "$drift"; then
    echo "FAIL: the drift check does not run the full brew style on main pushes and on a schedule"
    fail=1
  elif ! grep -Fq 'devantler-tech/actions/upsert-issue@' "$drift" \
    || ! grep -Fq 'issues: write' "$drift"; then
    echo "FAIL: drift on main is not reported as an issue"
    fail=1
  else
    echo "ok: the gate is scoped to the change and main is checked in full"
  fi
}

assert_lists_only_changed_casks
assert_no_cask_change_is_empty
assert_deleted_and_renamed_casks
assert_scope_follows_the_merge_base
assert_unsafe_paths_are_fatal
assert_missing_history_is_fatal
assert_workflow_contract

if [ "$fail" -ne 0 ]; then
  echo "changed-casks.test.sh: FAILURES"
  exit 1
fi
echo "changed-casks.test.sh: all cases passed"

#!/usr/bin/env bash
# Hermetic regression tests for the PR-scoped Cask autocorrector. Pushable style commits must be
# bound to one immutable event head and must never widen a generated Cask PR.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/../scripts/autocorrect-pr-casks.sh"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
fail=0

new_fixture() {
  local root="$scratch/$1"
  mkdir -p "$root/Casks" "$root/bin"
  printf 'needs-style-fix\n' >"$root/Casks/target.rb"
  printf 'needs-style-fix\n' >"$root/Casks/sibling.rb"
  printf 'fixture\n' >"$root/README.md"

  cat >"$root/bin/brew" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$BREW_ARGS_FILE"
if [ "$1" != style ] || [ "$2" != --fix ]; then
  echo "unexpected brew invocation: $*" >&2
  exit 2
fi
shift 2
for target in "$@"; do
  printf 'fixed\n' >>"$target"
done
if [ "${BREW_MUTATE_OUTSIDE:-0}" = 1 ]; then
  printf 'wrong-scope\n' >>Casks/sibling.rb
fi
if [ "${BREW_CREATE_UNTRACKED:-0}" = 1 ]; then
  printf 'untracked-scope-escape\n' >Casks/untracked.rb
fi
exit "${BREW_EXIT:-0}"
STUB
  chmod +x "$root/bin/brew"

  (
    cd "$root"
    git init -q
    git config user.name fixture
    git config user.email fixture@example.invalid
    git add Casks/target.rb Casks/sibling.rb README.md
    git commit -qm fixture
  )
  printf '%s\n' "$root"
}

commit_target_change() {
  local root="$1"
  (
    cd "$root"
    printf 'generated-update\n' >>Casks/target.rb
    git add Casks/target.rb
    git commit -qm generated-target
  )
}

run_helper() {
  local root="$1" base="$2" head="$3"
  (
    cd "$root"
    PATH="$root/bin:$PATH" \
      BREW_ARGS_FILE="$root/brew.args" \
      bash "$script" "$base" "$head" "$root/output" "$root/targets"
  )
}

assert_pr_scoped_fix() {
  local root base head dirty
  root="$(new_fixture scoped)"
  base="$(cd "$root" && git rev-parse HEAD)"
  commit_target_change "$root"
  head="$(cd "$root" && git rev-parse HEAD)"

  if ! run_helper "$root" "$base" "$head"; then
    echo "FAIL: immutable target discovery rejected a valid Cask change"
    fail=1
    return
  fi
  dirty="$(sed -n 's/^dirty=//p' "$root/output")"
  if [ "$dirty" != true ]; then
    echo "FAIL: expected a changed target to emit dirty=true"
    fail=1
  elif ! grep -Fqx 'style --fix Casks/target.rb' "$root/brew.args"; then
    echo "FAIL: brew did not receive only the changed Cask"
    fail=1
  elif ! grep -Fqx 'Casks/target.rb' "$root/targets"; then
    echo "FAIL: the exact dirty target was not written to the commit manifest"
    fail=1
  elif ! grep -Fqx 'needs-style-fix' "$root/Casks/sibling.rb"; then
    echo "FAIL: the unrelated style-dirty Cask was modified"
    fail=1
  else
    echo "ok: immutable diff autocorrects and manifests only the changed Cask"
  fi
}

assert_missing_history_is_fatal() {
  local root head missing
  root="$(new_fixture missing-history)"
  commit_target_change "$root"
  head="$(cd "$root" && git rev-parse HEAD)"
  missing='ffffffffffffffffffffffffffffffffffffffff'
  if run_helper "$root" "$missing" "$head" >/dev/null 2>&1; then
    echo "FAIL: missing base history was accepted"
    fail=1
  elif [ -e "$root/brew.args" ]; then
    echo "FAIL: brew ran after immutable history discovery failed"
    fail=1
  else
    echo "ok: missing immutable history stops before autocorrection"
  fi
}

assert_checked_out_head_mismatch_is_fatal() {
  local root base head
  root="$(new_fixture head-mismatch)"
  base="$(cd "$root" && git rev-parse HEAD)"
  commit_target_change "$root"
  head="$(cd "$root" && git rev-parse HEAD)"
  if run_helper "$root" "$base" "$base" >/dev/null 2>&1; then
    echo "FAIL: a checkout that differs from the event head was accepted"
    fail=1
  elif [ -e "$root/brew.args" ]; then
    echo "FAIL: brew ran after the checked-out head mismatched the event head $head"
    fail=1
  else
    echo "ok: mutable-head checkout mismatch fails before autocorrection"
  fi
}

assert_newline_path_is_fatal() {
  local root base head unsafe_dir
  root="$(new_fixture newline-path)"
  base="$(cd "$root" && git rev-parse HEAD)"
  unsafe_dir="$root/"$'Casks/target.rb\nCasks'
  mkdir -p "$unsafe_dir"
  printf 'one-filename-not-two\n' >"$unsafe_dir/sibling.rb"
  (
    cd "$root"
    git add "$unsafe_dir/sibling.rb"
    git commit -qm newline-path
  )
  head="$(cd "$root" && git rev-parse HEAD)"
  if run_helper "$root" "$base" "$head" >/dev/null 2>&1; then
    echo "FAIL: a newline-bearing Git filename split into authorized targets"
    fail=1
  elif [ -e "$root/brew.args" ]; then
    echo "FAIL: brew ran after an unsafe newline-bearing path was discovered"
    fail=1
  else
    echo "ok: NUL-delimited discovery preserves and rejects newline-bearing filenames"
  fi
}

assert_out_of_scope_mutation_is_fatal() {
  local root base head
  root="$(new_fixture scope-escape)"
  base="$(cd "$root" && git rev-parse HEAD)"
  commit_target_change "$root"
  head="$(cd "$root" && git rev-parse HEAD)"
  if BREW_MUTATE_OUTSIDE=1 run_helper "$root" "$base" "$head" >/dev/null 2>&1; then
    echo "FAIL: autocorrection was allowed to dirty an unrelated Cask"
    fail=1
  else
    echo "ok: scope guard rejects an autocorrector that dirties another Cask"
  fi
}

assert_untracked_scope_escape_is_fatal() {
  local root base head
  root="$(new_fixture untracked-escape)"
  base="$(cd "$root" && git rev-parse HEAD)"
  commit_target_change "$root"
  head="$(cd "$root" && git rev-parse HEAD)"
  if BREW_CREATE_UNTRACKED=1 run_helper "$root" "$base" "$head" >/dev/null 2>&1; then
    echo "FAIL: an untracked sibling Cask bypassed the post-fix allowlist"
    fail=1
  else
    echo "ok: scope guard rejects an untracked sibling created by autocorrection"
  fi
}

assert_staged_start_is_fatal() {
  local root base head
  root="$(new_fixture staged-start)"
  base="$(cd "$root" && git rev-parse HEAD)"
  commit_target_change "$root"
  head="$(cd "$root" && git rev-parse HEAD)"
  (
    cd "$root"
    printf 'staged-scope-escape\n' >>Casks/sibling.rb
    git add Casks/sibling.rb
  )
  if run_helper "$root" "$base" "$head" >/dev/null 2>&1; then
    echo "FAIL: a staged sibling Cask bypassed the clean-start guard"
    fail=1
  elif [ -e "$root/brew.args" ]; then
    echo "FAIL: brew ran despite a staged sibling Cask at startup"
    fail=1
  else
    echo "ok: staged Cask state fails closed before autocorrection"
  fi
}

assert_no_cask_is_noop() {
  local root base head dirty
  root="$(new_fixture no-cask)"
  base="$(cd "$root" && git rev-parse HEAD)"
  (
    cd "$root"
    printf 'docs-only\n' >>README.md
    git add README.md
    git commit -qm docs-only
  )
  head="$(cd "$root" && git rev-parse HEAD)"
  if ! run_helper "$root" "$base" "$head"; then
    echo "FAIL: a PR without Cask changes was rejected"
    fail=1
    return
  fi
  dirty="$(sed -n 's/^dirty=//p' "$root/output")"
  if [ "$dirty" != false ] || [ -e "$root/brew.args" ] || [ -s "$root/targets" ]; then
    echo "FAIL: a PR without Cask changes was not a clean no-op"
    fail=1
  else
    echo "ok: a PR without changed Casks is a clean no-op"
  fi
}

assert_workflow_contract() {
  local workflow style_block
  workflow="$here/../.github/workflows/ci.yaml"
  style_block="$(sed -n '/- name: 📥 Checkout (same-repo PR/,/- name: 🎨 brew style (gate)/p' "$workflow")"

  # Literal GitHub/shell expressions are the workflow contract, not values for this test to expand.
  # shellcheck disable=SC2016
  if ! grep -Fq 'fetch-depth: 0' <<<"$style_block"; then
    echo "FAIL: pushable PR checkout does not fetch immutable base/head history"
    fail=1
  elif ! grep -Fq 'ref: ${{ github.event.pull_request.head.sha }}' <<<"$style_block"; then
    echo "FAIL: pushable PR checkout still follows a mutable branch name"
    fail=1
  elif ! grep -Fq 'BASE_SHA: ${{ github.event.pull_request.base.sha }}' <<<"$style_block" \
    || ! grep -Fq 'EXPECTED_HEAD: ${{ github.event.pull_request.head.sha }}' <<<"$style_block"; then
    echo "FAIL: workflow does not bind discovery and push to the event base/head"
    fail=1
  elif ! grep -Fq 'bash scripts/autocorrect-pr-casks.sh "$BASE_SHA" "$EXPECTED_HEAD" "$GITHUB_OUTPUT" "$TARGET_MANIFEST"' <<<"$style_block"; then
    echo "FAIL: workflow does not delegate immutable discovery to the scoped helper"
    fail=1
  elif grep -Fq 'git-auto-commit-action' <<<"$style_block" \
    || grep -Fq 'file_pattern: "Casks/*.rb"' <<<"$style_block"; then
    echo "FAIL: broad third-party Cask staging remains in the pushable path"
    fail=1
  elif ! grep -Fq 'git add -- "$target"' <<<"$style_block"; then
    echo "FAIL: commit step does not stage exact manifest targets"
    fail=1
  elif ! grep -Fq 'git push --force-with-lease="refs/heads/$HEAD_REF:$EXPECTED_HEAD" origin "HEAD:refs/heads/$HEAD_REF"' <<<"$style_block"; then
    echo "FAIL: autocorrect push is not an exact-event-head compare-and-swap"
    fail=1
  elif ! grep -Fq 'brew style --fix ./Casks/ || true' <<<"$style_block"; then
    echo "FAIL: the check-only fallback no longer evaluates the complete Cask tree"
    fail=1
  elif ! grep -Fq 'for test_script in test/*.test.sh; do' "$workflow"; then
    echo "FAIL: CI does not execute every hermetic script regression test"
    fail=1
  else
    echo "ok: workflow binds immutable discovery, exact staging, and leased push"
  fi
}

assert_pr_scoped_fix
assert_missing_history_is_fatal
assert_checked_out_head_mismatch_is_fatal
assert_newline_path_is_fatal
assert_out_of_scope_mutation_is_fatal
assert_untracked_scope_escape_is_fatal
assert_staged_start_is_fatal
assert_no_cask_is_noop
assert_workflow_contract

if [ "$fail" -ne 0 ]; then
  echo "autocorrect-pr-casks.test.sh: FAILURES"
  exit 1
fi
echo "autocorrect-pr-casks.test.sh: all cases passed"

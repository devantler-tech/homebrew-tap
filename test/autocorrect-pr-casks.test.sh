#!/usr/bin/env bash
# Hermetic regression tests for the PR-scoped Cask autocorrector. The workflow may push generated
# style fixes to a trusted same-repository PR, so widening one Cask PR into another Cask is a release
# safety failure, not cosmetic drift.
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

  cat >"$root/bin/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$GH_ARGS_FILE"
if [ "${GH_FAIL:-0}" = 1 ]; then
  exit 1
fi
printf '%s' "${GH_FILES:-}"
STUB
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
  chmod +x "$root/bin/gh" "$root/bin/brew"

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

assert_pr_scoped_fix() {
  local root output dirty
  root="$(new_fixture scoped)"
  output="$root/output"
  (
    cd "$root"
    PATH="$root/bin:$PATH" \
      GH_ARGS_FILE="$root/gh.args" \
      BREW_ARGS_FILE="$root/brew.args" \
      GH_FILES=$'Casks/target.rb\nREADME.md\n' \
      bash "$script" devantler-tech/homebrew-tap 42 "$output"
  )

  dirty="$(sed -n 's/^dirty=//p' "$output")"
  if [ "$dirty" != true ]; then
    echo "FAIL: expected a changed target to emit dirty=true"
    fail=1
  elif ! grep -Fqx 'style --fix Casks/target.rb' "$root/brew.args"; then
    echo "FAIL: brew did not receive only the PR-changed Cask"
    fail=1
  elif ! grep -Fqx 'needs-style-fix' "$root/Casks/sibling.rb"; then
    echo "FAIL: the unrelated style-dirty Cask was modified"
    fail=1
  elif [ "$(cd "$root" && git diff --name-only -- Casks/)" != 'Casks/target.rb' ]; then
    echo "FAIL: autocorrection dirtied a file outside the PR Cask"
    fail=1
  elif ! grep -Fq -- '--paginate repos/devantler-tech/homebrew-tap/pulls/42/files?per_page=100' "$root/gh.args" \
    || ! grep -Fq 'select(.status != "removed")' "$root/gh.args"; then
    echo "FAIL: changed-file discovery is not paginated or does not exclude removed Casks"
    fail=1
  else
    echo "ok: same-repository autocorrection touches only the PR-changed Cask"
  fi
}

assert_api_failure_is_fatal() {
  local root
  root="$(new_fixture api-failure)"
  if (
    cd "$root"
    PATH="$root/bin:$PATH" \
      GH_ARGS_FILE="$root/gh.args" \
      BREW_ARGS_FILE="$root/brew.args" \
      GH_FAIL=1 \
      bash "$script" devantler-tech/homebrew-tap 42 "$root/output"
  ) >/dev/null 2>&1; then
    echo "FAIL: changed-file API failure was accepted"
    fail=1
  elif [ -e "$root/brew.args" ]; then
    echo "FAIL: brew ran after changed-file discovery failed"
    fail=1
  else
    echo "ok: changed-file discovery failure stops before autocorrection"
  fi
}

assert_unsafe_path_is_fatal() {
  local root
  root="$(new_fixture unsafe-path)"
  if (
    cd "$root"
    PATH="$root/bin:$PATH" \
      GH_ARGS_FILE="$root/gh.args" \
      BREW_ARGS_FILE="$root/brew.args" \
      GH_FILES=$'Casks/nested/escape.rb\n' \
      bash "$script" devantler-tech/homebrew-tap 42 "$root/output"
  ) >/dev/null 2>&1; then
    echo "FAIL: an unsafe nested Cask path was accepted"
    fail=1
  elif [ -e "$root/brew.args" ]; then
    echo "FAIL: brew ran after an unsafe Cask path was discovered"
    fail=1
  else
    echo "ok: unsafe Cask paths fail closed before autocorrection"
  fi
}

assert_out_of_scope_mutation_is_fatal() {
  local root
  root="$(new_fixture scope-escape)"
  if (
    cd "$root"
    PATH="$root/bin:$PATH" \
      GH_ARGS_FILE="$root/gh.args" \
      BREW_ARGS_FILE="$root/brew.args" \
      GH_FILES=$'Casks/target.rb\n' \
      BREW_MUTATE_OUTSIDE=1 \
      bash "$script" devantler-tech/homebrew-tap 42 "$root/output"
  ) >/dev/null 2>&1; then
    echo "FAIL: autocorrection was allowed to dirty an unrelated Cask"
    fail=1
  else
    echo "ok: scope guard rejects an autocorrector that dirties another Cask"
  fi
}

assert_untracked_scope_escape_is_fatal() {
  local root
  root="$(new_fixture untracked-escape)"
  if (
    cd "$root"
    PATH="$root/bin:$PATH" \
      GH_ARGS_FILE="$root/gh.args" \
      BREW_ARGS_FILE="$root/brew.args" \
      GH_FILES=$'Casks/target.rb\n' \
      BREW_CREATE_UNTRACKED=1 \
      bash "$script" devantler-tech/homebrew-tap 42 "$root/output"
  ) >/dev/null 2>&1; then
    echo "FAIL: an untracked sibling Cask bypassed the post-fix allowlist"
    fail=1
  else
    echo "ok: scope guard rejects an untracked sibling created by autocorrection"
  fi
}

assert_staged_start_is_fatal() {
  local root
  root="$(new_fixture staged-start)"
  (
    cd "$root"
    printf 'staged-scope-escape\n' >>Casks/sibling.rb
    git add Casks/sibling.rb
  )
  if (
    cd "$root"
    PATH="$root/bin:$PATH" \
      GH_ARGS_FILE="$root/gh.args" \
      BREW_ARGS_FILE="$root/brew.args" \
      GH_FILES=$'Casks/target.rb\n' \
      bash "$script" devantler-tech/homebrew-tap 42 "$root/output"
  ) >/dev/null 2>&1; then
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
  local root dirty
  root="$(new_fixture no-cask)"
  (
    cd "$root"
    PATH="$root/bin:$PATH" \
      GH_ARGS_FILE="$root/gh.args" \
      BREW_ARGS_FILE="$root/brew.args" \
      GH_FILES=$'README.md\n' \
      bash "$script" devantler-tech/homebrew-tap 42 "$root/output"
  )
  dirty="$(sed -n 's/^dirty=//p' "$root/output")"
  if [ "$dirty" != false ] || [ -e "$root/brew.args" ]; then
    echo "FAIL: a PR without Cask changes was not a clean no-op"
    fail=1
  else
    echo "ok: a PR without changed Casks is a clean no-op"
  fi
}

assert_workflow_contract() {
  local workflow fix_block
  workflow="$here/../.github/workflows/ci.yaml"
  fix_block="$(sed -n '/- name: 🎨 brew style --fix/,/- name: 📤 Commit/p' "$workflow")"

  # Literal GitHub/shell expressions are the workflow contract, not values for this test to expand.
  # shellcheck disable=SC2016
  if ! grep -Fq 'pull-requests: read' "$workflow"; then
    echo "FAIL: style job cannot read the authoritative PR file list"
    fail=1
  elif ! grep -Fq 'GH_TOKEN: ${{ github.token }}' <<<"$fix_block"; then
    echo "FAIL: PR-scoped autocorrection does not use the read-only workflow token"
    fail=1
  elif ! grep -Fq 'if [ "$EVENT_NAME" = "pull_request" ] && [ "$HEAD_REPO" = "$GITHUB_REPOSITORY" ]; then' <<<"$fix_block"; then
    echo "FAIL: same-repository PR autocorrection is not explicitly gated"
    fail=1
  elif ! grep -Fq 'bash scripts/autocorrect-pr-casks.sh "$GITHUB_REPOSITORY" "$PR_NUMBER" "$GITHUB_OUTPUT"' <<<"$fix_block"; then
    echo "FAIL: the workflow does not delegate same-repository fixes to the scoped helper"
    fail=1
  elif ! grep -Fq 'brew style --fix ./Casks/ || true' <<<"$fix_block"; then
    echo "FAIL: the check-only fallback no longer evaluates the complete Cask tree"
    fail=1
  elif ! grep -Fq 'for test_script in test/*.test.sh; do' "$workflow"; then
    echo "FAIL: CI does not execute every hermetic script regression test"
    fail=1
  else
    echo "ok: workflow scopes pushable PR fixes and retains the full-tree check-only gate"
  fi
}

assert_pr_scoped_fix
assert_api_failure_is_fatal
assert_unsafe_path_is_fatal
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

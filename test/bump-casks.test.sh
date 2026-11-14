#!/usr/bin/env bash
# Hermetic regression tests for scripts/bump-casks.sh. `brew` and `gh` are stubs on PATH, so
# nothing reaches the network, Homebrew or GitHub.
# Checks are eval'd strings, so their variables expand at check time, not here.
# shellcheck disable=SC2016,SC2034
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/../scripts/bump-casks.sh"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
fail=0

# new_fixture <name> <livecheck-json>: a git tap checkout plus brew/gh stubs that log their calls.
new_fixture() {
  local root="$scratch/$1"
  mkdir -p "$root/tap/Casks" "$root/bin"
  printf 'cask "ksail" do\n  version "1.0.0"\nend\n' >"$root/tap/Casks/ksail.rb"
  git -C "$root/tap" init -q
  git -C "$root/tap" add Casks/ksail.rb
  git -C "$root/tap" -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false commit -q -m fixture
  printf '%s' "$2" >"$root/livecheck.json"
  : >"$root/calls"

  cat >"$root/bin/brew" <<STUB
#!/usr/bin/env bash
printf 'brew %s\n' "\$*" >>"$root/calls"
case "\$1" in
  --repository) printf '%s\n' "$root/tap" ;;
  livecheck) cat "$root/livecheck.json" ;;
  bump-cask-pr)
    [ "\${BREW_BUMP_EXIT:-0}" = 0 ] || exit "\$BREW_BUMP_EXIT"
    sed -i.bak 's/1.0.0/2.0.0/' "$root/tap/Casks/ksail.rb" && rm -f "$root/tap/Casks/ksail.rb.bak" ;;
  *) echo "unexpected brew call: \$*" >&2; exit 9 ;;
esac
STUB
  cat >"$root/bin/gh" <<STUB
#!/usr/bin/env bash
printf 'gh %s\n' "\$*" >>"$root/calls"
case "\$*" in
  "api repos/o/r/branches/"*) [ "\${GH_BRANCH_EXISTS:-0}" = 1 ] ;;
  "api repos/o/r/git/ref/heads/main --jq .object.sha") echo 1111111111111111111111111111111111111111 ;;
  "api repos/o/r/contents/"*"--jq .sha") echo 2222222222222222222222222222222222222222 ;;
  *) exit 0 ;;
esac
STUB
  chmod +x "$root/bin/brew" "$root/bin/gh"
  printf '%s' "$root"
}

run() {
  local root=$1
  shift
  (cd "$root" && env "$@" PATH="$root/bin:$PATH" bash "$script" o/r devantler-tech/tap) >"$root/out" 2>&1
}

check() {
  if eval "$2"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"
    fail=1
  fi
}

outdated='[{"cask":"ksail","version":{"current":"1.0.0","latest":"2.0.0","outdated":true}}]'

root="$(new_fixture bump "$outdated")"
status=0; run "$root" || status=$?
expected="$(printf 'cask "ksail" do\n  version "2.0.0"\nend\n' | base64 | tr -d '\n')"
check "an outdated cask exits 0" '[ "$status" = 0 ]'
check "it bumps through bump-cask-pr" 'grep -qx "brew bump-cask-pr --write-only --version 2.0.0 devantler-tech/tap/ksail" "$root/calls"'
check "it branches from main" 'grep -q "^gh api -X POST repos/o/r/git/refs -f ref=refs/heads/bump-ksail-2.0.0 -f sha=1111111111111111111111111111111111111111" "$root/calls"'
check "it commits the bumped cask with a conventional subject" \
  'grep -qF "gh api -X PUT repos/o/r/contents/Casks/ksail.rb -f branch=bump-ksail-2.0.0 -f message=chore(cask): update ksail to v2.0.0 -f content=$expected -f sha=2222222222222222222222222222222222222222" "$root/calls"'
check "it opens the pull request" 'grep -q "^gh pr create --repo o/r --base main --head bump-ksail-2.0.0 --title chore(cask): update ksail to v2.0.0" "$root/calls"'
check "it leaves the tap checkout clean" 'git -C "$root/tap" diff --quiet'

root="$(new_fixture existing "$outdated")"
status=0; run "$root" GH_BRANCH_EXISTS=1 || status=$?
check "an existing bump branch is skipped" '[ "$status" = 0 ] && ! grep -q "bump-cask-pr\|pr create" "$root/calls"'

root="$(new_fixture current '[]')"
status=0; run "$root" || status=$?
check "nothing outdated does nothing" '[ "$status" = 0 ] && ! grep -q "bump-cask-pr\|gh " "$root/calls"'

root="$(new_fixture error '[{"cask":"ksail","status":"error","messages":["Unable to get versions"]}]')"
status=0; run "$root" || status=$?
check "a livecheck error fails" '[ "$status" = 1 ] && grep -q "livecheck failed for ksail" "$root/out"'

root="$(new_fixture garbage 'not json')"
status=0; run "$root" || status=$?
check "unreadable livecheck output fails" '[ "$status" != 0 ] && ! grep -q "bump-cask-pr" "$root/calls"'

root="$(new_fixture badversion '[{"cask":"ksail","version":{"current":"1.0.0","latest":"2.0.0;rm","outdated":true}}]')"
status=0; run "$root" || status=$?
check "an unexpected version is refused" '[ "$status" = 1 ] && ! grep -q "bump-cask-pr\|gh " "$root/calls"'

root="$(new_fixture bumpfail "$outdated")"
status=0; run "$root" BREW_BUMP_EXIT=1 || status=$?
check "a failed bump fails without touching GitHub" '[ "$status" = 1 ] && ! grep -q "^gh api -X\|pr create" "$root/calls"'

exit "$fail"

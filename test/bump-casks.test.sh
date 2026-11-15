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
  livecheck) cat "$root/livecheck.json"; exit "\${BREW_LIVECHECK_EXIT:-0}" ;;
  bump-cask-pr)
    [ "\${BREW_BUMP_EXIT:-0}" = 0 ] || exit "\$BREW_BUMP_EXIT"
    cask="\${@: -1}"; cask="\${cask##*/}"
    [ "\${BREW_FAIL_CASK:-}" != "\$cask" ] || exit 1
    sed -i.bak 's/1.0.0/2.0.0/' "$root/tap/Casks/\$cask.rb" && rm -f "$root/tap/Casks/\$cask.rb.bak" ;;
  *) echo "unexpected brew call: \$*" >&2; exit 9 ;;
esac
STUB
  cat >"$root/bin/gh" <<STUB
#!/usr/bin/env bash
printf 'gh %s\n' "\$*" >>"$root/calls"
case "\$*" in
  "api repos/o/r/branches/"*) [ "\${GH_BRANCH_EXISTS:-0}" = 1 ] ;;
  "api repos/o/r/contents/"*"--jq .sha")
    path="\${2#repos/o/r/contents/}"; path="\${path%%\?*}"
    if [ -f "$root/commit.json" ]; then
      jq -jr --arg path "\$path" '.variables.input.fileChanges.additions[] | select(.path == \$path) | .contents | @base64d' "$root/commit.json" | git hash-object --stdin
    elif [ -f "$root/tap/Casks/ksail-desktop.rb" ]; then
      if [ "\${GH_ADAPTED:-0}" = 1 ]; then
        echo 4444444444444444444444444444444444444444
      else
        git -C "$root/tap" rev-parse "HEAD:\$path"
      fi
    else
      echo "\${GH_BLOB:-2222222222222222222222222222222222222222}"
    fi ;;
  "api repos/o/r/git/ref/heads/"*) echo 3333333333333333333333333333333333333333 ;;
  "api repos/o/r/pulls?head=o:bump-ksail-desktop-"*"&state=all "*) echo "\${GH_DESKTOP_PRS:-[]}" ;;
  "api repos/o/r/pulls?head=o:"*"&state=all "*) [ "\${GH_PRS_EXIT:-0}" = 0 ] || exit 1; echo "\${GH_PRS:-[]}" ;;
  "api repos/o/r/pulls?head=o:"*"&state=open "*) echo PR_kwNODE ;;
  "api graphql --input -"*)
    cat >"$root/commit.json"
    [ "\${GH_COMMIT_EXIT:-0}" = 0 ] ;;
  "api graphql "*) [ "\${GH_MERGE_EXIT:-0}" = 0 ] ;;
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
generated="$(git -C "$root/tap" rev-parse HEAD)"
check "it branches from the revision it bumped, not a later main" 'grep -q "^gh api -X POST repos/o/r/git/refs -f ref=refs/heads/bump-ksail-2.0.0 -f sha=$generated" "$root/calls" && ! grep -q "git/ref/heads/main" "$root/calls"'
check "it reads the branch copy of the cask" 'grep -qx "gh api repos/o/r/contents/Casks/ksail.rb?ref=refs/heads/bump-ksail-2.0.0 --jq .sha" "$root/calls"'
check "it commits the bumped cask with a conventional subject" \
  'grep -qF "gh api -X PUT repos/o/r/contents/Casks/ksail.rb -f branch=bump-ksail-2.0.0 -f message=chore(cask): update ksail to v2.0.0 -f content=$expected -f sha=2222222222222222222222222222222222222222" "$root/calls"'
check "it opens the pull request" 'grep -q "^gh pr create --repo o/r --base main --head bump-ksail-2.0.0 --title chore(cask): update ksail to v2.0.0" "$root/calls"'
check "it arms auto-merge on the opened pull request" 'grep -q "^gh api repos/o/r/pulls?head=o:bump-ksail-2.0.0&state=open" "$root/calls" && grep -q "^gh api graphql --silent -f id=PR_kwNODE -f query=mutation.*enablePullRequestAutoMerge.*SQUASH" "$root/calls"'
check "it leaves the tap checkout clean" 'git -C "$root/tap" diff --quiet'

want="$(printf 'cask "ksail" do\n  version "2.0.0"\nend\n' | git hash-object --stdin)"

root="$(new_fixture resume "$outdated")"
status=0; run "$root" GH_BRANCH_EXISTS=1 GH_BLOB="$want" || status=$?
check "a branch left without a pull request is resumed" '[ "$status" = 0 ] && ! grep -q "^gh api -X" "$root/calls" && grep -q "^gh pr create .*--head bump-ksail-2.0.0" "$root/calls" && grep -q "^gh api graphql" "$root/calls"'

root="$(new_fixture stale "$outdated")"
status=0; run "$root" GH_BRANCH_EXISTS=1 || status=$?
check "a branch without the bump gets the commit, not a second branch" '[ "$status" = 0 ] && ! grep -q "git/refs" "$root/calls" && grep -q "^gh api -X PUT repos/o/r/contents/Casks/ksail.rb -f branch=bump-ksail-2.0.0" "$root/calls"'

root="$(new_fixture open "$outdated")"
status=0; run "$root" GH_BRANCH_EXISTS=1 GH_BLOB="$want" GH_PRS='[{"state":"open","merged_at":null}]' || status=$?
check "an open pull request is re-armed, not reopened" '[ "$status" = 0 ] && ! grep -q "pr create\|^gh api -X" "$root/calls" && grep -q "^gh api graphql" "$root/calls"'

root="$(new_fixture closed "$outdated")"
status=0; run "$root" GH_PRS='[{"state":"closed","merged_at":null}]' || status=$?
check "a version whose pull request was closed is skipped" '[ "$status" = 0 ] && ! grep -q "bump-cask-pr\|pr create\|^gh api -X\|graphql" "$root/calls"'

root="$(new_fixture prsfail "$outdated")"
status=0; run "$root" GH_PRS_EXIT=1 || status=$?
check "an unreadable pull request list fails without bumping" '[ "$status" = 1 ] && ! grep -q "bump-cask-pr" "$root/calls"'

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

root="$(new_fixture armfail "$outdated")"
status=0; run "$root" GH_MERGE_EXIT=1 || status=$?
check "an unarmed pull request fails the run" '[ "$status" = 1 ] && grep -q "could not arm auto-merge" "$root/out"'

root="$(new_fixture partial '[{"cask":"other","status":"error","messages":["Unable to get versions"]},{"cask":"ksail","version":{"current":"1.0.0","latest":"2.0.0","outdated":true}}]')"
status=0; run "$root" BREW_LIVECHECK_EXIT=1 || status=$?
check "a failing livecheck still bumps the other Casks and fails the run" '[ "$status" = 1 ] && grep -q "livecheck failed for other" "$root/out" && grep -q "^gh pr create" "$root/calls"'

pair='[{"cask":"ksail","version":{"current":"1.0.0","latest":"2.0.0","outdated":true}},{"cask":"ksail-desktop","version":{"current":"1.0.0","latest":"2.0.0","outdated":true}},{"cask":"world-at-ruin","version":{"current":"1.0.0","latest":"1.0.0","outdated":false}}]'

pair_fixture() {
  local root
  root="$(new_fixture "$1" "$2")"
  printf 'cask "ksail-desktop" do\n  version "1.0.0"\nend\n' >"$root/tap/Casks/ksail-desktop.rb"
  printf 'cask "world-at-ruin" do\n  version "1.0.0"\nend\n' >"$root/tap/Casks/world-at-ruin.rb"
  git -C "$root/tap" add Casks/ksail-desktop.rb Casks/world-at-ruin.rb
  git -C "$root/tap" -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false commit -q -m siblings
  printf '%s' "$root"
}

root="$(pair_fixture pair "$pair")"
status=0; run "$root" || status=$?
check "one shared release opens one PR with an atomic pair commit" \
  '[ "$status" = 0 ] && [ "$(grep -c "^gh pr create " "$root/calls")" = 1 ] && jq -e '\''[.variables.input.fileChanges.additions[].path] | sort == ["Casks/ksail-desktop.rb", "Casks/ksail.rb"]'\'' "$root/commit.json" >/dev/null'
check "the pair retains Homebrew output and leaves the unrelated cask unchanged" \
  'jq -e '\''all(.variables.input.fileChanges.additions[]; (.contents | @base64d | contains("version \"2.0.0\"")))'\'' "$root/commit.json" >/dev/null && ! grep -q "bump-cask-pr.*world-at-ruin" "$root/calls" && git -C "$root/tap" diff --quiet'
check "the pair commit fences the branch head" \
  'jq -e '\''.variables.input.expectedHeadOid == "3333333333333333333333333333333333333333" and .variables.input.branch.branchName == "bump-ksail-2.0.0"'\'' "$root/commit.json" >/dev/null'

root="$(pair_fixture pair-resume "$pair")"
status=0; run "$root" GH_BRANCH_EXISTS=1 GH_PRS='[{"state":"open","merged_at":null,"auto_merge":{"merge_method":"squash"}}]' || status=$?
check "an existing single-cask branch is repaired with both files without a second PR" \
  '[ "$status" = 0 ] && [ -f "$root/commit.json" ] && ! grep -q "git/refs\|pr create" "$root/calls" && jq -e '\''.variables.input.fileChanges.additions | length == 2'\'' "$root/commit.json" >/dev/null'
check "a repaired pair disarms old auto-merge and requires normal review" \
  'grep -q "disablePullRequestAutoMerge" "$root/calls" && ! grep -q "enablePullRequestAutoMerge" "$root/calls"'

root="$(pair_fixture pair-failure "$pair")"
status=0; run "$root" BREW_FAIL_CASK=ksail-desktop || status=$?
check "a failed sibling generation publishes neither cask and preserves the checkout" \
  '[ "$status" = 1 ] && ! grep -q "^gh api -X\|graphql\|pr create" "$root/calls" && git -C "$root/tap" diff --quiet'

root="$(pair_fixture pair-cas "$pair")"
status=0; run "$root" GH_COMMIT_EXIT=1 || status=$?
check "a rejected atomic commit opens and arms no PR" \
  '[ "$status" != 0 ] && ! grep -q "pr create\|enablePullRequestAutoMerge" "$root/calls"'

root="$(pair_fixture pair-closed "$pair")"
status=0; run "$root" GH_DESKTOP_PRS='[{"state":"closed","merged_at":null}]' || status=$?
check "a deliberately closed sibling update is not republished through the pair" \
  '[ "$status" = 0 ] && ! grep -q "bump-cask-pr\|pr create\|graphql" "$root/calls"'

root="$(pair_fixture pair-unknown "$outdated")"
status=0; run "$root" || status=$?
check "unknown sibling release metadata cannot publish half a release" \
  '[ "$status" = 1 ] && ! grep -q "bump-cask-pr\|pr create\|graphql" "$root/calls"'

partial_pair='[{"cask":"ksail","version":{"current":"2.0.0","latest":"2.0.0","outdated":false}},{"cask":"ksail-desktop","version":{"current":"1.0.0","latest":"2.0.0","outdated":true}}]'
root="$(pair_fixture pair-current-sibling "$partial_pair")"
sed -i.bak 's/1.0.0/2.0.0/' "$root/tap/Casks/ksail.rb"
rm -f "$root/tap/Casks/ksail.rb.bak"
git -C "$root/tap" add Casks/ksail.rb
git -C "$root/tap" -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false commit -q -m already-current
status=0; run "$root" || status=$?
check "an already current sibling is included without asking Homebrew to bump it again" \
  '[ "$status" = 0 ] && ! grep -q "bump-cask-pr.*tap/ksail$" "$root/calls" && jq -e '\''all(.variables.input.fileChanges.additions[]; (.contents | @base64d | contains("version \"2.0.0\"")))'\'' "$root/commit.json" >/dev/null'

root="$(pair_fixture pair-dirty "$pair")"
printf '# local work\n' >>"$root/tap/Casks/ksail.rb"
status=0; run "$root" || status=$?
check "local cask edits are preserved rather than reset by generation" \
  '[ "$status" = 1 ] && grep -q "# local work" "$root/tap/Casks/ksail.rb" && ! grep -q "bump-cask-pr\|gh " "$root/calls"'

root="$(pair_fixture pair-adapted "$pair")"
status=0; run "$root" GH_BRANCH_EXISTS=1 GH_ADAPTED=1 || status=$?
check "a remote cask adaptation is preserved rather than overwritten" \
  '[ "$status" = 1 ] && [ ! -f "$root/commit.json" ] && ! grep -q "pr create\|enablePullRequestAutoMerge" "$root/calls"'

exit "$fail"

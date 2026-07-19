#!/usr/bin/env bash
# Autocorrect only Casks changed between one immutable pull-request base/head pair.
#
# The workflow checks out the event head with full history, and the eventual push uses a lease pinned
# to that same head. This helper derives scope locally with NUL-delimited Git paths, so a mutable PR
# branch or a filename containing newlines cannot change or split the authorization boundary.
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: autocorrect-pr-casks.sh <base-sha> <head-sha> <github-output> <target-manifest>" >&2
  exit 2
fi

base_sha="$1"
expected_head="$2"
github_output="$3"
target_manifest="$4"

for named_sha in "base:$base_sha" "head:$expected_head"; do
  sha_name="${named_sha%%:*}"
  sha_value="${named_sha#*:}"
  if [[ ! "$sha_value" =~ ^[0-9a-f]{40}$ ]]; then
    echo "BLOCKED: invalid $sha_name commit SHA: $sha_value" >&2
    exit 2
  fi
done
if [ -z "$github_output" ] || [ -z "$target_manifest" ]; then
  echo "BLOCKED: output and target-manifest paths are required" >&2
  exit 2
fi

if ! local_head="$(git rev-parse HEAD)" || [ "$local_head" != "$expected_head" ]; then
  echo "BLOCKED: checkout HEAD ${local_head:-unavailable} does not equal event head $expected_head" >&2
  exit 1
fi
if ! git cat-file -e "${base_sha}^{commit}" 2>/dev/null \
  || ! git cat-file -e "${expected_head}^{commit}" 2>/dev/null; then
  echo "BLOCKED: immutable base/head history is unavailable" >&2
  exit 1
fi
if ! merge_base="$(git merge-base "$base_sha" "$expected_head")" || [ -z "$merge_base" ]; then
  echo "BLOCKED: could not resolve the pull-request merge base" >&2
  exit 1
fi

changed_paths="$(mktemp)"
trap 'rm -f "$changed_paths"' EXIT
# Match GitHub's three-dot PR scope from immutable commits. Exclude deletions because a deleted Cask
# has no working-tree path to style. `-z` preserves every filename boundary, including newlines.
if ! git diff --name-only -z --diff-filter=ACMRTUXB \
  "$merge_base" "$expected_head" -- >"$changed_paths"; then
  echo "BLOCKED: could not enumerate immutable changed paths" >&2
  exit 1
fi

# Bash 3.2 (the macOS runner default) treats an empty array expansion as unset under `set -u`.
# Keep an inert sentinel at index 0 and pass only the slice beginning at index 1.
targets=("")
target_count=0
while IFS= read -r -d '' changed_file; do
  case "$changed_file" in
    Casks/*)
      # Casks are single files directly beneath Casks/. Reject nested paths, shell metacharacters,
      # whitespace/newlines, and missing files rather than interpreting an ambiguous path.
      if [[ ! "$changed_file" =~ ^Casks/[A-Za-z0-9][A-Za-z0-9._+-]*\.rb$ ]] \
        || [ ! -f "$changed_file" ]; then
        echo "BLOCKED: unsafe or missing changed Cask path: $changed_file" >&2
        exit 1
      fi
      duplicate=0
      for target in "${targets[@]:1}"; do
        if [ "$target" = "$changed_file" ]; then
          duplicate=1
          break
        fi
      done
      if [ "$duplicate" -eq 0 ]; then
        targets+=("$changed_file")
        target_count=$((target_count + 1))
      fi
      ;;
  esac
done <"$changed_paths"

# The commit step stages only paths written here after the post-fix status guard succeeds.
: >"$target_manifest"
if [ "$target_count" -eq 0 ]; then
  echo "No changed Casks to autocorrect for $expected_head"
  printf 'dirty=false\n' >>"$github_output"
  exit 0
fi

# A dirty start would make the post-fix allowlist ambiguous. Porcelain status includes tracked,
# staged, and untracked paths; `git diff` alone omits the latter two.
if ! initial_status="$(git status --porcelain=v1 --untracked-files=all -- Casks/)"; then
  echo "BLOCKED: could not inspect initial Cask status" >&2
  exit 1
fi
if [ -n "$initial_status" ]; then
  echo "BLOCKED: Casks were already dirty before autocorrection" >&2
  exit 1
fi

echo "Autocorrecting immutable PR-scoped Casks: ${targets[*]:1}"
# Homebrew can apply partial fixes and still return non-zero for remaining offenses. Preserve those
# corrections; the later full-tree `brew style` gate decides whether any offense remains.
brew style --fix "${targets[@]:1}" || true

if ! cask_status="$(git status --porcelain=v1 --untracked-files=all -- Casks/)"; then
  echo "BLOCKED: could not enumerate autocorrection status" >&2
  exit 1
fi

dirty_count=0
while IFS= read -r status_line; do
  [ -z "$status_line" ] && continue
  if [ "${#status_line}" -lt 4 ]; then
    echo "BLOCKED: malformed Cask status: $status_line" >&2
    exit 1
  fi
  index_and_worktree="${status_line:0:2}"
  dirty_file="${status_line:3}"

  # Homebrew should only leave an unstaged modification to an existing target. Reject staged,
  # untracked, deleted, renamed, copied, conflicted, malformed, and out-of-scope state outright.
  if [ "$index_and_worktree" != " M" ]; then
    echo "BLOCKED: autocorrection produced unsafe Cask status '$index_and_worktree' for $dirty_file" >&2
    exit 1
  fi
  allowed=0
  for target in "${targets[@]:1}"; do
    if [ "$target" = "$dirty_file" ]; then
      allowed=1
      break
    fi
  done
  if [ "$allowed" -ne 1 ]; then
    echo "BLOCKED: autocorrection dirtied out-of-scope Cask: $dirty_file" >&2
    exit 1
  fi
  printf '%s\n' "$dirty_file" >>"$target_manifest"
  dirty_count=$((dirty_count + 1))
done <<EOF
$cask_status
EOF

if [ "$dirty_count" -eq 0 ]; then
  printf 'dirty=false\n' >>"$github_output"
else
  printf 'dirty=true\n' >>"$github_output"
fi

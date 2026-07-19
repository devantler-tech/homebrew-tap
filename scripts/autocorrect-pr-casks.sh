#!/usr/bin/env bash
# Autocorrect only the non-deleted Casks already changed by one pull request.
#
# A same-repository PR may receive a generated style commit, but that privilege must never widen the
# PR into another Cask. The caller may safely use a broad Casks/*.rb commit pattern only after this
# script's post-fix scope guard succeeds.
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: autocorrect-pr-casks.sh <owner/repo> <pr-number> <github-output>" >&2
  exit 2
fi

repository="$1"
pr_number="$2"
github_output="$3"

if [[ ! "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "BLOCKED: invalid repository name: $repository" >&2
  exit 2
fi
if [[ ! "$pr_number" =~ ^[1-9][0-9]*$ ]]; then
  echo "BLOCKED: invalid pull request number: $pr_number" >&2
  exit 2
fi
if [ -z "$github_output" ]; then
  echo "BLOCKED: the GitHub output path is empty" >&2
  exit 2
fi

# The PR-files endpoint is the authoritative scope. It is paginated, excludes deleted Casks that no
# longer exist in the checkout, and fails closed before Homebrew can mutate anything.
if ! changed_files="$(gh api --paginate \
  "repos/${repository}/pulls/${pr_number}/files?per_page=100" \
  --jq '.[] | select(.status != "removed") | .filename')"; then
  echo "BLOCKED: could not enumerate changed files for ${repository}#${pr_number}" >&2
  exit 1
fi

# Bash 3.2 (the macOS runner default) treats an empty array expansion as unset under `set -u`.
# Keep an inert sentinel at index 0 and pass only the slice beginning at index 1.
targets=("")
target_count=0
while IFS= read -r changed_file; do
  [ -z "$changed_file" ] && continue
  case "$changed_file" in
    Casks/*.rb)
      # Casks are single files directly beneath Casks/. Reject nested paths, shell metacharacters,
      # whitespace, and missing files rather than passing an ambiguous argument to Homebrew.
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
done <<EOF
$changed_files
EOF

if [ "$target_count" -eq 0 ]; then
  echo "No changed Casks to autocorrect for ${repository}#${pr_number}"
  printf 'dirty=false\n' >>"$github_output"
  exit 0
fi

# A dirty start would make the post-fix allowlist ambiguous. Porcelain status includes tracked,
# staged, and untracked paths; `git diff` alone omits the latter two and would let the broad commit
# action pick up state this helper never authorized.
if ! initial_status="$(git status --porcelain=v1 --untracked-files=all -- Casks/)"; then
  echo "BLOCKED: could not inspect initial Cask status" >&2
  exit 1
fi
if [ -n "$initial_status" ]; then
  echo "BLOCKED: Casks were already dirty before autocorrection" >&2
  exit 1
fi

echo "Autocorrecting PR-scoped Casks: ${targets[*]:1}"
# Homebrew can apply partial fixes and still return non-zero for remaining offenses. Preserve those
# corrections; the later full-tree `brew style` gate decides whether any offense remains.
brew style --fix "${targets[@]:1}" || true

if ! cask_status="$(git status --porcelain=v1 --untracked-files=all -- Casks/)"; then
  echo "BLOCKED: could not enumerate autocorrection status" >&2
  exit 1
fi

dirty_files=""
while IFS= read -r status_line; do
  [ -z "$status_line" ] && continue
  if [ "${#status_line}" -lt 4 ]; then
    echo "BLOCKED: malformed Cask status: $status_line" >&2
    exit 1
  fi
  index_and_worktree="${status_line:0:2}"
  dirty_file="${status_line:3}"

  # Homebrew should only leave an unstaged modification to an existing target. Reject staged,
  # untracked, deleted, renamed, copied, or conflicted state outright; the pinned commit action
  # would otherwise stage those paths through its broad Casks/*.rb file pattern.
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
  if [ -z "$dirty_files" ]; then
    dirty_files="$dirty_file"
  else
    dirty_files="$dirty_files
$dirty_file"
  fi
done <<EOF
$cask_status
EOF

if [ -z "$dirty_files" ]; then
  printf 'dirty=false\n' >>"$github_output"
else
  printf 'dirty=true\n' >>"$github_output"
fi

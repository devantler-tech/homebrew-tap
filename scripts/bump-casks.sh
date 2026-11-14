#!/usr/bin/env bash
# Open one pull request per outdated Cask with Homebrew's own tools (devantler-tech/homebrew-tap#2568).
#
# `brew livecheck` finds each Cask's latest version from its `livecheck` block (GitHub's latest
# release, which never points at a draft or a prerelease), and `brew bump-cask-pr --write-only`
# rewrites the version and every platform's sha256, then runs `brew style --fix` and `brew audit`.
# The commit is made through the contents API, so GitHub signs it, and it carries a
# Conventional-Commit subject, which `brew bump --open-pr` would not.
#
# usage: bump-casks.sh <owner/repo> <tap>     e.g. bump-casks.sh devantler-tech/homebrew-tap devantler-tech/tap
# Needs `brew` with the tap tapped and trusted, `gh` authenticated with contents and
# pull-requests write, and `jq`. Exits 1 when any Cask could not be checked or bumped.
set -euo pipefail

[ "$#" -eq 2 ] || {
  echo "usage: bump-casks.sh <owner/repo> <tap>" >&2
  exit 2
}
repo=$1 tap=$2
tap_dir="$(brew --repository "$tap")"
# shellcheck disable=SC2016 # $id is a GraphQL variable, not a shell one.
arm_auto_merge='mutation($id: ID!) { enablePullRequestAutoMerge(input: {pullRequestId: $id, mergeMethod: SQUASH}) { clientMutationId } }'

livecheck="$(brew livecheck --tap "$tap" --newer-only --json --quiet)"
jq -e 'type == "array"' <<<"$livecheck" >/dev/null || {
  echo "::error::brew livecheck did not return a JSON array" >&2
  exit 1
}

status=0
# A Cask livecheck could not resolve is a failure, never "up to date".
while IFS= read -r line; do
  [ -n "$line" ] || continue
  echo "::error::livecheck failed for $line" >&2
  status=1
done < <(jq -r '.[] | select(.status == "error" or (.version | not)) | "\(.cask // "unknown"): \(.messages // [] | join("; "))"' <<<"$livecheck")

while IFS=$'\t' read -r cask version; do
  [ -n "$cask" ] || continue
  if [[ ! "$cask" =~ ^[a-z0-9][a-z0-9-]*$ || ! "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "::error::refusing unexpected cask or version: $cask $version" >&2
    status=1
    continue
  fi
  branch="bump-$cask-$version"
  path="Casks/$cask.rb"
  title="chore(cask): update $cask to v$version"
  head="${repo%%/*}:$branch"

  # Every step below is idempotent, so a run that stopped part-way is resumed by the next one.
  # Only a pull request a person closed without merging stops the bump of that version.
  if ! prs="$(gh api "repos/$repo/pulls?head=$head&state=all" --jq '[.[] | {state, merged_at}]')"; then
    echo "::error::could not list pull requests for $branch" >&2
    status=1
    continue
  fi
  if jq -e 'length > 0 and all(.[]; .state != "open")' <<<"$prs" >/dev/null; then
    echo "$cask $version: $branch already has a closed pull request, skipping"
    continue
  fi

  if ! brew bump-cask-pr --write-only --version "$version" "$tap/$cask"; then
    echo "::error::brew bump-cask-pr failed for $cask $version" >&2
    git -C "$tap_dir" checkout -- "$path"
    status=1
    continue
  fi
  content="$(base64 <"$tap_dir/$path" | tr -d '\n')"
  want="$(git -C "$tap_dir" hash-object "$path")"
  git -C "$tap_dir" checkout -- "$path"

  if ! gh api "repos/$repo/branches/$branch" --silent >/dev/null 2>&1; then
    base="$(gh api "repos/$repo/git/ref/heads/main" --jq .object.sha)"
    gh api -X POST "repos/$repo/git/refs" -f ref="refs/heads/$branch" -f sha="$base" --silent
  fi
  blob="$(gh api "repos/$repo/contents/$path?ref=refs/heads/$branch" --jq .sha)"
  if [ "$blob" != "$want" ]; then
    gh api -X PUT "repos/$repo/contents/$path" -f branch="$branch" -f message="$title" \
      -f content="$content" -f sha="$blob" --silent
  fi
  if ! jq -e 'any(.[]; .state == "open")' <<<"$prs" >/dev/null; then
    gh pr create --repo "$repo" --base main --head "$branch" --title "$title" --body "$(
      printf '%s\n\n%s\n' \
        "Updates the \`$cask\` Cask to $version, its latest GitHub release, with \`brew bump-cask-pr\`." \
        "Opened by the scheduled [bump-casks](https://github.com/$repo/blob/main/.github/workflows/bump-casks.yaml) workflow."
    )"
  fi
  # Arm auto-merge so the tap's required checks alone gate the merge, as the product
  # pipelines did. Re-arming an armed PR is harmless, and a PR that is never armed silently
  # falls behind, so that is a failure. GraphQL off the node id, as the world-at-ruin cask job
  # did, so no `gh pr merge` scope is needed.
  node="$(gh api "repos/$repo/pulls?head=$head&state=open" --jq '.[0].node_id // empty')" || node=""
  if [ -z "$node" ] || ! gh api graphql --silent -f id="$node" \
    -f query="$arm_auto_merge"; then
    echo "::error::could not arm auto-merge for $branch" >&2
    status=1
  fi
done < <(jq -r '.[] | select(.version.outdated == true) | [.cask, .version.latest] | @tsv' <<<"$livecheck")

exit "$status"

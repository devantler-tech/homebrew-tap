#!/usr/bin/env bash
# Open release-consistent Cask updates with Homebrew's own tools (#2568, #2572).
#
# `brew livecheck` finds each Cask's latest version from its `livecheck` block (GitHub's latest
# release, which never points at a draft or a prerelease), and `brew bump-cask-pr --write-only`
# rewrites the version and every platform's sha256, then runs `brew style --fix` and `brew audit`.
# Commits use GitHub's signing APIs, with one atomic commit for the KSail pair, and carry a
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
git -C "$tap_dir" diff --quiet HEAD -- Casks/ || {
  echo "::error::refusing to overwrite local Cask changes" >&2
  exit 1
}
# shellcheck disable=SC2016 # $id is a GraphQL variable, not a shell one.
arm_auto_merge='mutation($id: ID!) { enablePullRequestAutoMerge(input: {pullRequestId: $id, mergeMethod: SQUASH}) { clientMutationId } }'

status=0
# No --quiet: with it, Homebrew drops a Cask whose check errors from the JSON instead of
# reporting it. Homebrew also exits non-zero then, which must not hide the other Casks.
# Include current siblings too: one KSail cask may already be on the shared release.
if ! livecheck="$(brew livecheck --tap "$tap" --json)"; then
  echo "::error::brew livecheck reported a failure" >&2
  status=1
fi
jq -e 'type == "array"' <<<"$livecheck" >/dev/null || {
  echo "::error::brew livecheck did not return a JSON array" >&2
  exit 1
}

# A Cask livecheck could not resolve is a failure, never "up to date".
while IFS= read -r line; do
  [ -n "$line" ] || continue
  echo "::error::livecheck failed for $line" >&2
  status=1
done < <(jq -r '.[] | select(.status == "error" or (.version | not)) | "\(.cask // "unknown"): \(.messages // [] | join("; "))"' <<<"$livecheck")

pair_done=0
while IFS=$'\t' read -r cask version; do
  [ -n "$cask" ] || continue
  if [[ ! "$cask" =~ ^[a-z0-9][a-z0-9-]*$ || ! "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "::error::refusing unexpected cask or version: $cask $version" >&2
    status=1
    continue
  fi
  members=("$cask")
  if [[ "$cask" == ksail || "$cask" == ksail-desktop ]] &&
    [ -f "$tap_dir/Casks/ksail.rb" ] && [ -f "$tap_dir/Casks/ksail-desktop.rb" ]; then
    [ "$pair_done" = 0 ] || continue
    pair_done=1
    # Both packages come from one release. Unknown or inconsistent sibling metadata must
    # never turn the pair back into two independently publishable updates.
    if ! jq -e --arg version "$version" '
      [.[] | select(.cask == "ksail" or .cask == "ksail-desktop")] |
      length == 2 and ([.[].cask] | unique | length == 2) and
      all(.[]; .version.latest == $version)
    ' <<<"$livecheck" >/dev/null; then
      echo "::error::KSail CLI and desktop must resolve the same release" >&2
      status=1
      continue
    fi
    members=(ksail ksail-desktop)
    cask=ksail
  fi
  branch="bump-$cask-$version"
  path="Casks/$cask.rb"
  title="chore(cask): update $cask to v$version"
  if [ "${#members[@]}" -gt 1 ]; then
    title="chore(cask): update KSail CLI and desktop to v$version"
  fi
  head="${repo%%/*}:$branch"

  # Every step below is idempotent, so a run that stopped part-way is resumed by the next one.
  # Only a pull request a person closed without merging stops the bump of that version.
  if ! prs="$(gh api "repos/$repo/pulls?head=$head&state=all" --jq '[.[] | {state, merged_at, auto_merge}]')"; then
    echo "::error::could not list pull requests for $branch" >&2
    status=1
    continue
  fi
  if [ "${#members[@]}" -gt 1 ] &&
    jq -e 'length > 0 and all(.[]; .state == "closed" and .merged_at != null)' <<<"$prs" >/dev/null; then
    # A merged legacy CLI-only PR is success, not a decision to reject the desktop.
    # Recover on a new paired branch rather than reusing that closed PR's identity.
    branch="bump-ksail-pair-$version"
    head="${repo%%/*}:$branch"
    if ! prs="$(gh api "repos/$repo/pulls?head=$head&state=all" --jq '[.[] | {state, merged_at, auto_merge}]')"; then
      echo "::error::could not read the paired recovery update's disposition" >&2
      status=1
      continue
    fi
  fi
  if jq -e 'length > 0 and all(.[]; .state != "open")' <<<"$prs" >/dev/null; then
    echo "$cask $version: $branch already has a closed pull request, skipping"
    continue
  fi
  if [ "${#members[@]}" -gt 1 ]; then
    if ! sibling_prs="$(gh api "repos/$repo/pulls?head=${repo%%/*}:bump-ksail-desktop-$version&state=all" \
      --jq '[.[] | {state, merged_at}]')"; then
      echo "::error::could not read the desktop update's disposition" >&2
      status=1
      continue
    fi
    if jq -e 'any(.[]; .state == "closed" and .merged_at == null)' <<<"$sibling_prs" >/dev/null; then
      echo "KSail $version: the desktop update was closed, skipping the pair"
      continue
    fi
  fi

  additions='[]'
  wanted='{}'
  generation_failed=0
  for member in "${members[@]}"; do
    path="Casks/$member.rb"
    if jq -e --arg cask "$member" 'any(.[]; .cask == $cask and .version.outdated == true)' \
      <<<"$livecheck" >/dev/null &&
      ! brew bump-cask-pr --write-only --version "$version" "$tap/$member"; then
      echo "::error::brew bump-cask-pr failed for $member $version" >&2
      git -C "$tap_dir" checkout -- "$path"
      generation_failed=1
      break
    fi
    content="$(base64 <"$tap_dir/$path" | tr -d '\n')"
    want="$(git -C "$tap_dir" hash-object "$path")"
    additions="$(jq --arg path "$path" --arg contents "$content" '. + [{path: $path, contents: $contents}]' <<<"$additions")"
    wanted="$(jq --arg path "$path" --arg sha "$want" '. + {($path): $sha}' <<<"$wanted")"
    git -C "$tap_dir" checkout -- "$path"
  done
  if [ "$generation_failed" != 0 ]; then
    status=1
    continue
  fi
  if [ "${#members[@]}" -gt 1 ] && jq -e 'any(.[]; .state == "open" and .auto_merge != null)' <<<"$prs" >/dev/null; then
    # The single-Cask programmed review exemption does not cover a pair. Remove the
    # old branch's auto-merge before changing its scope; the pair needs normal review.
    node="$(gh api "repos/$repo/pulls?head=$head&state=open" --jq '.[0].node_id // empty')"
    disable_merge="mutation(\$id: ID!) { disablePullRequestAutoMerge(input: {pullRequestId: \$id}) { clientMutationId } }"
    if [ -z "$node" ] || ! gh api graphql --silent -f id="$node" -f query="$disable_merge"; then
      echo "::error::could not disarm auto-merge before publishing the KSail pair" >&2
      status=1
      continue
    fi
  fi

  if ! gh api "repos/$repo/branches/$branch" --silent >/dev/null 2>&1; then
    # Branch from the revision the bump was generated from, not whatever main is now, so a
    # change that landed on main meanwhile is never overwritten by this commit.
    base="$(git -C "$tap_dir" rev-parse HEAD)"
    gh api -X POST "repos/$repo/git/refs" -f ref="refs/heads/$branch" -f sha="$base" --silent
  fi
  if [ "${#members[@]}" -gt 1 ]; then
    # Read immutable blobs at the head we fence. A concurrent push then rejects the entire
    # mutation instead of overwriting a sibling's work or publishing half the release.
    expected_head="$(gh api "repos/$repo/git/ref/heads/$branch" --jq .object.sha)"
    changed=0
    adapted=0
    for member in "${members[@]}"; do
      path="Casks/$member.rb"
      blob="$(gh api "repos/$repo/contents/$path?ref=$expected_head" --jq .sha)"
      want="$(jq -r --arg path "$path" '.[$path]' <<<"$wanted")"
      baseline="$(git -C "$tap_dir" rev-parse "HEAD:$path")"
      if [ "$blob" != "$want" ] && [ "$blob" != "$baseline" ]; then
        adapted=1
      fi
      [ "$blob" = "$want" ] || changed=1
    done
    if [ "$adapted" != 0 ]; then
      echo "::error::preserving remote KSail Cask edits that differ from the base and Homebrew output" >&2
      status=1
      continue
    fi
    if [ "$changed" != 0 ]; then
      # createCommitOnBranch signs like the contents API, but updates both files atomically.
      mutation="mutation(\$input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: \$input) { commit { oid } } }"
      if ! jq -n --arg query "$mutation" --arg repo "$repo" --arg branch "$branch" \
        --arg head "$expected_head" --arg title "$title" --argjson additions "$additions" '
        {query: $query, variables: {input: {branch: {repositoryNameWithOwner: $repo, branchName: $branch},
          expectedHeadOid: $head, message: {headline: $title}, fileChanges: {additions: $additions}}}}
      ' | gh api graphql --input - --silent; then
        echo "::error::could not atomically publish the KSail pair" >&2
        status=1
        continue
      fi
    fi
    verified=1
    for member in "${members[@]}"; do
      path="Casks/$member.rb"
      blob="$(gh api "repos/$repo/contents/$path?ref=refs/heads/$branch" --jq .sha)" || blob=""
      want="$(jq -r --arg path "$path" '.[$path]' <<<"$wanted")"
      [ "$blob" = "$want" ] || verified=0
    done
    if [ "$verified" != 1 ]; then
      echo "::error::the published KSail pair did not match Homebrew's output" >&2
      status=1
      continue
    fi
  else
    blob="$(gh api "repos/$repo/contents/$path?ref=refs/heads/$branch" --jq .sha)"
    if [ "$blob" != "$want" ]; then
      gh api -X PUT "repos/$repo/contents/$path" -f branch="$branch" -f message="$title" \
        -f content="$content" -f sha="$blob" --silent
    fi
  fi
  if ! jq -e 'any(.[]; .state == "open")' <<<"$prs" >/dev/null; then
    gh pr create --repo "$repo" --base main --head "$branch" --title "$title" --body "$(
      printf '%s\n\n%s\n' \
        "Updates ${members[*]} to $version, their latest GitHub release, with \`brew bump-cask-pr\`." \
        "Opened by the scheduled [bump-casks](https://github.com/$repo/blob/main/.github/workflows/bump-casks.yaml) workflow."
    )"
  elif [ "${#members[@]}" -gt 1 ]; then
    gh pr edit "$branch" --repo "$repo" --title "$title"
  fi
  if [ "${#members[@]}" -gt 1 ]; then
    echo "KSail $version: the paired update requires normal review and a protected merge"
    continue
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

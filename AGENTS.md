# AGENTS.md

## Project overview

`devantler-tech/homebrew-tap` is the **Homebrew tap** for devantler-tech tools — installable via `brew tap devantler-tech/tap`. Despite the repo name, it currently distributes **Casks** (not formulas): the `ksail` CLI, the `ksail-desktop` app, and the World at Ruin game. Users install with `brew install --cask devantler-tech/tap/<cask>`.

## Structure

- `Casks/ksail.rb` — Cask for the `ksail` CLI binary (macOS arm64, Linux amd64/arm64). Kept up to date by `bump-casks.yaml`.
- `Casks/ksail-desktop.rb` — Cask for the `KSail.app` desktop app (macOS arm64). Kept up to date by `bump-casks.yaml`.
- `Casks/world-at-ruin.rb` — Cask for World at Ruin (macOS universal, Apple Silicon and Intel). Kept up to date by `bump-casks.yaml`.
- `README.md` — tap landing page: a Cask/Description table and install instructions.
- `.github/workflows/ci.yaml` — runs `brew audit --strict --online` on every Cask (macOS), loads the whole tap on every OS and architecture with `brew readall --os=all --arch=all`, and aggregates the results into the required-checks gate (`devantler-tech/.github/actions/aggregate-job-checks`) on `pull_request` and `merge_group`.
- `.github/workflows/todos.yaml` — scans pushed-to-`main` commits for TODO comments and files issues.
- `.github/workflows/bump-casks.yaml` — hourly, runs `brew livecheck` on the tap and opens one PR per outdated Cask through `scripts/bump-casks.sh`, with the App token so tap CI runs.
- `.github/workflows/style-drift.yaml` — runs `brew style` on every Cask on `main` after each merge and daily, and keeps one issue open while any Cask fails.
- `.github/dependabot.yaml` — daily `github-actions` dependency updates.
- `scripts/bump-casks.sh` — bumps each outdated Cask with `brew bump-cask-pr --write-only`, commits it through the contents API (GitHub-signed, Conventional-Commit subject) on a `bump-<cask>-<version>` branch, opens the PR and arms its auto-merge, so the tap's required checks alone gate the merge. A Cask livecheck cannot resolve, or a PR it cannot arm, fails the run.
- `scripts/changed-casks.sh` — lists the Casks a pull request or merge group adds or modifies, which is what the style gate checks.
- `scripts/cask-version-order.sh` — refuses a pull request or merge group that moves a changed Cask to an older version than the branch it merges into, or a prerelease over the stable version it precedes; an unreadable version fails. CI runs it as `🔢 Cask version order`, part of the required-checks gate, so a retried older release run cannot downgrade a Cask.
- `test/*.test.sh` — hermetic regression tests for the scripts above; run on Linux by the `ci.yaml` `🧪 Test scripts` job on every PR.

Each Cask carries `version`, `sha256` + `url` pointing at its owning product's GitHub release asset (KSail or World at Ruin), a `livecheck` on the product's latest GitHub release (`strategy :github_latest`, which never returns a draft or prerelease), a `binary`/`app` stanza, and post-install handling that strips the macOS quarantine xattr. The KSail Casks select platform-specific assets; World at Ruin uses a universal macOS archive. Start human contributions with [CONTRIBUTING.md](CONTRIBUTING.md).

## Validation

CI runs `brew audit --strict --online` on every Cask and blocks merge on failure. It also runs a check-only `brew style` gate (`style-casks` in `ci.yaml`) on the Casks the pull request or merge group adds or modifies, so a change that touches no Cask cannot fail on another Cask's style. Nothing autocorrects in CI: `brew bump-cask-pr` runs `brew style --fix` before `bump-casks.sh` commits a bump, and a human PR fixes its own style. `style-drift.yaml` checks every Cask on `main`, because a new Homebrew release can bring a cop that flags a Cask nobody changed. Audit and style judge only the runner's own platform, but `brew tap` loads every Cask for every OS and architecture and refuses the whole tap when one variant fails to load (devantler-tech/ksail#7034), so `load-casks` runs `brew readall --os=all --arch=all devantler-tech/tap` on every pull request, drafts included. Homebrew skips a tap it does not trust and still exits 0, so the job trusts the tap explicitly and fails on any skip notice. `brew audit` refuses to load a Cask from an untrusted tap, so `audit-casks` trusts the tap too, and its self-test passes only when the audit itself reports the broken fixture's known defect. Every macOS job runs `brew update` first, so audit and style judge with current Homebrew rather than whichever version the runner image bundles (#2039). Validate locally:

- If `brew` is available: `brew style ./Casks/<cask>.rb`, `brew audit --strict --online --cask <cask>`, and `brew readall --os=all --arch=all devantler-tech/tap` with the tap trusted.
- Otherwise: `ruby -c Casks/<cask>.rb` for a syntax check, plus a careful manual read.

Keep each Cask in a layout `brew bump-cask-pr` can rewrite. The ksail Cask uses one root `version`, a per-platform `sha256 arm:, arm64_linux:, x86_64_linux:` and an `#{os}_#{arch}` URL, because `bump-cask-pr` skips a `sha256` nested two levels deep (`on_linux` → `on_arm`).

## Maintenance (Agentic Engineer)

These conventions guide the autonomous **Agentic Engineer** — and any agentic tool — doing repository maintenance. The **shared** cross-repo conventions (autonomy and promotion, the trust gate, untrusted input, per-run worktrees, Conventional-Commit titles, root-cause fixing, the AI-disclosure line) are defined centrally in the devantler-tech monorepo `AGENTS.md` and apply here too. **Read them there rather than from a copy** — this section deliberately keeps only what is specific to this tap, because a restatement of the shared rules drifts silently as they change.

**The tap bumps Casks itself.** `bump-casks.yaml` runs hourly: `brew livecheck` reads each product's latest GitHub release, and `scripts/bump-casks.sh` opens one `bump-<cask>-<version>` PR titled `chore(cask): update <cask> to v<version>` per outdated Cask, skipping a version whose branch already exists. Products no longer write to the tap. **Do NOT hand-edit version/sha to chase a release**: the next hourly run does it with checksums Homebrew computed. Your job is Cask *correctness/hygiene*, not version bumps.

A bump PR points at a release GitHub already lists as latest, so it is never a draft fence: it follows the normal readiness and merge gates.

**Recommended local validation before any PR:** CI runs `brew audit --strict --online` and the check-only `style-casks` gate and blocks on both — still validate locally first: `brew style ./Casks/<cask>.rb` and `brew audit --strict --online --cask <cask>` if `brew` is available; else `ruby -c Casks/<cask>.rb` + a careful read.

**Task menu** (minimal; usually nothing to do):
- **Triage** new issues/PRs; one insightful comment on the oldest un-commented item (e.g. an install-failure report → investigate the Cask).
- **Cask hygiene** (clear, low-risk only): deprecated Homebrew DSL, broken `homepage`/`url`, bad `desc`/license, lint/style failures, dead Casks, README-table drift → draft PR. NOT speculative version bumps.
- **CI/workflow health:** keep the tap's CI green and tidy.
- **Maintain your own PRs:** fix CI you caused, resolve conflicts.

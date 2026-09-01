# AGENTS.md

## Project overview

`devantler-tech/homebrew-tap` is the **Homebrew tap** for devantler-tech tools — installable via `brew tap devantler-tech/tap`. Despite the repo name, it currently distributes **Casks** (not formulas): the `ksail` CLI and the `ksail-desktop` app. Users install with `brew install --cask devantler-tech/tap/<cask>`.

## Structure

- `Casks/ksail.rb` — Cask for the `ksail` CLI binary (macOS arm64, Linux amd64/arm64). GoReleaser-generated (`# DO NOT EDIT`).
- `Casks/ksail-desktop.rb` — Cask for the `KSail.app` desktop app (macOS arm64). GoReleaser-generated (`# DO NOT EDIT`).
- `README.md` — tap landing page: a Cask/Description table and install instructions.
- `.github/workflows/ci.yaml` — runs `brew audit --strict --online` on every Cask (macOS) and aggregates the result into the required-checks gate (`devantler-tech/actions/aggregate-job-checks`) on `pull_request` and `merge_group`.
- `.github/workflows/sync-labels.yaml` — weekly + on-demand GitHub label sync.
- `.github/workflows/todos.yaml` — scans pushed-to-`main` commits for TODO comments and files issues.
- `.github/workflows/close-superseded-cask-bumps.yaml` — closes stale `goreleaser/<cask>-v*` bump PRs whose version is at-or-below the version already on `main` (and deletes their branches), keeping only a genuinely-newer pending bump. Runs after a bump lands on `main`, daily, and on demand. Its close/keep version comparison lives in `scripts/is-superseded.sh`.
- `.github/dependabot.yaml` — daily `github-actions` dependency updates.
- `scripts/is-superseded.sh` — version-comparison predicate (`<candidate> <current>` → exit 0 = superseded/close, exit 1 = newer/keep) shared by `close-superseded-cask-bumps.yaml`; the single source of truth for the destructive close/keep decision.
- `test/is-superseded.test.sh` — hermetic regression test for `scripts/is-superseded.sh` (no network/Homebrew); run on Linux by the `ci.yaml` `🧪 Test scripts` job on every PR.

Each Cask carries `version`, per-platform `sha256` + `url` pointing at the corresponding `devantler-tech/ksail` GitHub release asset, a `livecheck` skipped as auto-generated-on-release, a `binary`/`app` stanza, and a `postflight` that strips the macOS quarantine xattr.

## Validation

CI runs `brew audit --strict --online` on every Cask and blocks merge on failure. It also runs a `brew style` gate (`style-casks` in `ci.yaml`): the GoReleaser-generated Casks (`# DO NOT EDIT`) are not style-clean as generated and upstream declined to change the template ([goreleaser/goreleaser#6678](https://github.com/goreleaser/goreleaser/issues/6678), closed not-planned), and a tap-level `.rubocop.yml` cop-allowlist does **not** override `brew style` (it uses Homebrew's own bundled RuboCop config) — so the job first **autocorrects** with `brew style --fix` and pushes the correction back to same-repo PR branches (every known generated offense is auto-correctable), then gates on a clean `brew style`. Merge-group and fork-PR runs are check-only (they cannot push) and fail if the tree needs fixing. Validate locally:

- If `brew` is available: `brew style ./Casks/<cask>.rb` and `brew audit --strict --online --cask <cask>`.
- Otherwise: `ruby -c Casks/<cask>.rb` for a syntax check, plus a careful manual read.

Note the Casks are GoReleaser-generated and marked `# DO NOT EDIT`; the upstream generator is the source of truth for their content.

## Maintenance (Agentic Engineer)

These conventions guide the autonomous **Agentic Engineer** — and any agentic tool — doing repository maintenance. The **shared** cross-repo conventions (autonomy and promotion, the trust gate, untrusted input, per-run worktrees, Conventional-Commit titles, root-cause fixing, the AI-disclosure line) are defined centrally in the devantler-tech monorepo `AGENTS.md` and apply here too. **Read them there rather than from a copy** — this section deliberately keeps only what is specific to this tap, because a restatement of the shared rules drifts silently as they change.

**Releases bump Casks automatically, on an evergreen branch per cask.** A tool release (e.g. ksail) force-updates one long-lived branch — `goreleaser/ksail`, `goreleaser/ksail-desktop` — and reuses a single open PR per cask to update that Cask's `url`/`version`/`sha256`. There is no `-v<version>` branch and no per-release PR. **Do NOT hand-edit version/sha to chase a release** — you'd race the automation and risk a wrong sha. Your job is Cask *correctness/hygiene*, not version bumps.

🔴 **The draft state on a `goreleaser/*` PR is a release gate — do NOT promote it.** ksail's CD workflow re-drafts these PRs at the start of every release (`redraft-evergreen-cask-prs.sh`), and flips them ready only once the release assets are published. Promoting one early does real damage: `🔍 Audit Casks` is skipped while a PR is a draft, so promoting runs it against a release that does not exist yet and it fails on a `404` for the download URL. Leave promotion and merge to the release pipeline; a red audit on a freshly-opened cask PR usually means the release is still publishing, not that the Cask is wrong.

**Recommended local validation before any PR:** CI runs `brew audit --strict --online` and the `style-casks` gate (`brew style` with autocorrect-and-push on same-repo PR branches) and blocks on both — still validate locally first: `brew style ./Casks/<cask>.rb` and `brew audit --strict --online --cask <cask>` if `brew` is available; else `ruby -c Casks/<cask>.rb` + a careful read.

**Task menu** (minimal; usually nothing to do):
- **Triage** new issues/PRs; one insightful comment on the oldest un-commented item (e.g. an install-failure report → investigate the Cask).
- **Cask hygiene** (clear, low-risk only): deprecated Homebrew DSL, broken `homepage`/`url`, bad `desc`/license, lint/style failures, dead Casks, README-table drift → draft PR. NOT speculative version bumps.
- **CI/workflow health:** keep the tap's CI green and tidy.
- **Maintain your own PRs:** fix CI you caused, resolve conflicts.

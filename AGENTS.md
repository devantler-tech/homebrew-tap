# AGENTS.md

## Project overview

`devantler-tech/homebrew-tap` is the **Homebrew tap** for devantler-tech tools — installable via `brew tap devantler-tech/tap`. Despite the repo name, it currently distributes **Casks** (not formulas): the `ksail` CLI, the `ksail-desktop` app, and the World at Ruin game. Users install with `brew install --cask devantler-tech/tap/<cask>`.

## Structure

- `Casks/ksail.rb` — Cask for the `ksail` CLI binary (macOS arm64, Linux amd64/arm64). GoReleaser-generated (`# DO NOT EDIT`).
- `Casks/ksail-desktop.rb` — Cask for the `KSail.app` desktop app (macOS arm64). GoReleaser-generated (`# DO NOT EDIT`).
- `Casks/world-at-ruin.rb` — Cask for World at Ruin (macOS universal, Apple Silicon and Intel). Generated (`# DO NOT EDIT`).
- `README.md` — tap landing page: a Cask/Description table and install instructions.
- `.github/workflows/ci.yaml` — runs `brew audit --strict --online` on every Cask (macOS), loads the whole tap on every OS and architecture with `brew readall --os=all --arch=all`, and aggregates the results into the required-checks gate (`devantler-tech/.github/actions/aggregate-job-checks`) on `pull_request` and `merge_group`.
- `.github/workflows/todos.yaml` — scans pushed-to-`main` commits for TODO comments and files issues.
- `.github/workflows/style-drift.yaml` — runs `brew style` on every Cask on `main` after each merge and daily, and keeps one issue open while any Cask fails.
- `.github/dependabot.yaml` — daily `github-actions` dependency updates.
- `scripts/autocorrect-pr-casks.sh` — autocorrects brew style offenses on PR branches.
- `scripts/changed-casks.sh` — lists the Casks a pull request or merge group adds or modifies, which is what the style gate checks.
- `scripts/cask-version-order.sh` — refuses a pull request or merge group that moves a changed Cask to an older version than the branch it merges into, or a prerelease over the stable version it precedes; an unreadable version fails. CI runs it as `🔢 Cask version order`, part of the required-checks gate, so a retried older release run cannot downgrade a Cask.
- `test/*.test.sh` — hermetic regression tests for the scripts above; run on Linux by the `ci.yaml` `🧪 Test scripts` job on every PR.

Each Cask carries `version`, `sha256` + `url` pointing at its owning product's GitHub release asset (KSail or World at Ruin), a `livecheck` skipped as auto-generated-on-release, a `binary`/`app` stanza, and post-install handling that strips the macOS quarantine xattr. The KSail Casks select platform-specific assets; World at Ruin uses a universal macOS archive. Start human contributions with [CONTRIBUTING.md](CONTRIBUTING.md).

## Validation

CI runs `brew audit --strict --online` on every Cask and blocks merge on failure. It also runs a `brew style` gate (`style-casks` in `ci.yaml`): the GoReleaser-generated Casks (`# DO NOT EDIT`) are not style-clean as generated and upstream declined to change the template ([goreleaser/goreleaser#6678](https://github.com/goreleaser/goreleaser/issues/6678), closed not-planned), and a tap-level `.rubocop.yml` cop-allowlist does **not** override `brew style` (it uses Homebrew's own bundled RuboCop config) — so the job first **autocorrects** with `brew style --fix` and pushes the correction back to same-repo PR branches (every known generated offense is auto-correctable), then gates on a clean `brew style`. The gate checks only the Casks the pull request or merge group adds or modifies, so a change that touches no Cask cannot fail on another Cask's style. Merge-group and fork-PR runs are check-only (they cannot push) and fail if a changed Cask needs fixing. `style-drift.yaml` checks every Cask on `main`, because a new Homebrew release can bring a cop that flags a Cask nobody changed. Audit and style judge only the runner's own platform, but `brew tap` loads every Cask for every OS and architecture and refuses the whole tap when one variant fails to load (devantler-tech/ksail#7034), so `load-casks` runs `brew readall --os=all --arch=all devantler-tech/tap` on every pull request, drafts included. Homebrew skips a tap it does not trust and still exits 0, so the job trusts the tap explicitly and fails on any skip notice. `brew audit` refuses to load a Cask from an untrusted tap, so `audit-casks` trusts the tap too, and its self-test fails if the refusal, rather than the audit, rejected the broken fixture. Every macOS job runs `brew update` first, so audit and style judge with current Homebrew rather than whichever version the runner image bundles (#2039). Validate locally:

- If `brew` is available: `brew style ./Casks/<cask>.rb`, `brew audit --strict --online --cask <cask>`, and `brew readall --os=all --arch=all devantler-tech/tap` with the tap trusted.
- Otherwise: `ruby -c Casks/<cask>.rb` for a syntax check, plus a careful manual read.

Note the Casks are GoReleaser-generated and marked `# DO NOT EDIT`; the upstream generator is the source of truth for their content.

## Maintenance (Agentic Engineer)

These conventions guide the autonomous **Agentic Engineer** — and any agentic tool — doing repository maintenance. The **shared** cross-repo conventions (autonomy and promotion, the trust gate, untrusted input, per-run worktrees, Conventional-Commit titles, root-cause fixing, the AI-disclosure line) are defined centrally in the devantler-tech monorepo `AGENTS.md` and apply here too. **Read them there rather than from a copy** — this section deliberately keeps only what is specific to this tap, because a restatement of the shared rules drifts silently as they change.

**Releases bump Casks automatically, on an evergreen branch per cask.** A tool release (e.g. ksail, world-at-ruin) force-updates one long-lived branch — `goreleaser/ksail`, `goreleaser/ksail-desktop`, `goreleaser/world-at-ruin` — and reuses a single open PR per cask to update that Cask's `url`/`version`/`sha256`. There is no `-v<version>` branch and no per-release PR. **Do NOT hand-edit version/sha to chase a release** — you'd race the automation and risk a wrong sha. Your job is Cask *correctness/hygiene*, not version bumps.

🔴 **The draft state on a `goreleaser/*` PR is a release gate — do NOT promote it.** ksail's CD workflow re-drafts these PRs at the start of every release (`redraft-evergreen-cask-prs.sh`), and flips them ready only once the release assets are published. Promoting one early does real damage: `🔍 Audit Casks` is skipped while a PR is a draft, so promoting runs it against a release that does not exist yet and it fails on a `404` for the download URL. Leave promotion and merge to the release pipeline; a red audit on a freshly-opened cask PR usually means the release is still publishing, not that the Cask is wrong.

**Recommended local validation before any PR:** CI runs `brew audit --strict --online` and the `style-casks` gate (`brew style` with autocorrect-and-push on same-repo PR branches) and blocks on both — still validate locally first: `brew style ./Casks/<cask>.rb` and `brew audit --strict --online --cask <cask>` if `brew` is available; else `ruby -c Casks/<cask>.rb` + a careful read.

**Task menu** (minimal; usually nothing to do):
- **Triage** new issues/PRs; one insightful comment on the oldest un-commented item (e.g. an install-failure report → investigate the Cask).
- **Cask hygiene** (clear, low-risk only): deprecated Homebrew DSL, broken `homepage`/`url`, bad `desc`/license, lint/style failures, dead Casks, README-table drift → draft PR. NOT speculative version bumps.
- **CI/workflow health:** keep the tap's CI green and tidy.
- **Maintain your own PRs:** fix CI you caused, resolve conflicts.

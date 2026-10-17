# Contributing to the Homebrew tap

A useful first contribution is a clearer installation explanation or a focused
packaging-test improvement. Discuss substantial work in an
[issue](https://github.com/devantler-tech/homebrew-tap/issues) first. Report
sensitive vulnerabilities through this repository's private
[Report a vulnerability](https://github.com/devantler-tech/homebrew-tap/security/advisories/new)
form, not a public issue or PR.

The Casks are **generated** by product releases. Do not hand-edit versions,
URLs, checksums or generated stanzas. Changes to their content belong in the
owning product's generator: KSail for its two Casks, World at Ruin for its game.
This repository owns the human guides, tap CI and packaging helper tests.

## Make a first documentation change

You need Git, Bash and standard Unix tools for the hermetic script tests.
They use disposable fixtures and do not need Homebrew, an installed product,
GitHub App credentials or cloud/cluster access.

Fork `devantler-tech/homebrew-tap` on GitHub, replace `YOUR-LOGIN` with your login,
and clone your fork:

```sh
git clone https://github.com/YOUR-LOGIN/homebrew-tap.git
cd homebrew-tap
git switch -c docs/first-contribution
```

Make a small wording improvement in `README.md` without changing Casks. Preview
the Markdown, then run from the root:

```sh
bash test/autocorrect-pr-casks.test.sh
bash test/changed-casks.test.sh
git diff --check
```

Both tests must exit 0 and report that all cases passed; whitespace validation
must exit 0. Their simulated autocorrector never changes the real Casks. This
does not install packages, validate download artifacts or replace native CI.

## Packaging and native validation

Read [AGENTS.md validation](AGENTS.md#validation) for the additional local Cask
checks. They need Homebrew on a compatible platform; online audit also needs
network access to public release metadata. `brew style` is a read-only check,
but its first run can download Homebrew's lint dependencies. Do not use a
documentation change as an excuse to autocorrect generated files by hand.

CI runs both script tests on drafts. Its style gate checks only Casks changed
by the PR; the separate drift workflow checks all Casks on `main`. A load gate,
also run on drafts, reads the whole tap for every OS and architecture, because
one Cask that fails to load anywhere breaks `brew tap` for everyone. Full online
audit runs when a draft becomes ready, so that additional run must finish
successfully before merge. An audit skipped on a draft does not prove the
release assets passed. Never promote an automated `goreleaser/*` draft early:
the owning release pipeline must publish its assets and lift that gate.

## Submit your change

Review the diff, configure commit signing, and stage explicit changed paths.
For the README-only first change above:

```sh
git add README.md
git commit -S -m "docs: clarify tap installation"
git push -u origin docs/first-contribution
```

Open a **draft** PR to `devantler-tech/homebrew-tap:main` with the inherited
[PR template](https://github.com/devantler-tech/.github/blob/main/.github/PULL_REQUEST_TEMPLATE.md).
Use a Conventional Commit title; explain the reader-facing problem and outcome
in Why/What, link the issue for substantial work, and put detailed checks in a
comment or check summary. Disclose AI assistance when used. Address findings;
required native checks and a substantive exact-current-head review must pass
before merge.

Follow the inherited [code of conduct](https://github.com/devantler-tech/.github/blob/main/.github/CODE_OF_CONDUCT.md)
and preserve the [Apache-2.0 license](LICENSE). Native macOS audit, other OS/
architecture installation and product runtime behavior are separate evidence
from a local documentation trial.

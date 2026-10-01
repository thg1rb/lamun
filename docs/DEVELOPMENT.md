# Developing Lamun

## Current Setup

W001 provides a native macOS Xcode project with a SwiftUI Menu Bar shell, app target `Lamun`, Swift Testing unit target `LamunTests`, XCTest UI target `LamunUITests`, and shared `Lamun` scheme. No audio feature is implemented. Open `Lamun.xcodeproj` in Xcode. The checked-in project file builds without the Ruby `xcodeproj` gem used to create the initial project.

The local W001 machine uses macOS 27.0, Xcode 27.0, and Swift 6.4. CI selects the supported `macos-26` runner and Xcode 26.6 from `/Applications/Xcode_26.6.app/Contents/Developer`; see the [runner image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md). Recheck this pairing when the runner image changes. The project deployment target of macOS 14.2 is **provisional**; Phase 0 must justify the final minimum. `org.example.lamun.bootstrap` is a **temporary** bundle identifier and must be replaced with an owned namespace before distribution.

## Local Commands

From repository root, use Xcode's command-line tools. Unsigned validation needs no Apple Developer account:

```bash
xcodebuild -project Lamun.xcodeproj -scheme Lamun -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/lamun-derived CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Lamun.xcodeproj -scheme Lamun -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/lamun-derived -only-testing:LamunTests CODE_SIGNING_ALLOWED=NO test
xcodebuild -project Lamun.xcodeproj -scheme Lamun -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/lamun-derived CODE_SIGNING_ALLOWED=NO analyze
```

Run UI smoke tests in an interactive macOS session when the test runner can launch the app:

```bash
xcodebuild -project Lamun.xcodeproj -scheme Lamun -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/lamun-derived -only-testing:LamunUITests CODE_SIGNING_ALLOWED=NO test
```

Check formatting, lint, docs, security, and dependencies:

```bash
bash scripts/check-format.sh
bash scripts/check-lint.sh
python3 scripts/check-docs.py
python3 scripts/check-whitespace.py
python3 scripts/check-security.py
python3 scripts/check-dependencies.py
```

To format intentionally, run `xcrun swift-format format --in-place --recursive Lamun LamunTests LamunUITests`, review the diff, then rerun checks. CI verifies; it does not rewrite source.

The whitespace check covers first-party tracked text. Copied Skills under `.agents/skills/` keep their upstream bytes so `skills-lock.json` remains verifiable; their existing trailing spaces are excluded. The upstream license notices are retained in `docs/licenses/`.

## Git and PR Workflow

The repository began with an unborn `main`. A one-time seed commit placed `PROMPT.md` and `PLAN.md` there so `develop` and `feature/project-bootstrap` could be created. Normal work now branches from latest `develop` and merges through a focused PR. Read [PROJECT-RULES.md](./PROJECT-RULES.md), [PROJECT-STATUS.md](./PROJECT-STATUS.md), relevant ADRs, and the work document before coding. Create/update the work document and acceptance criteria before implementation; update it and standing docs before PR review.

The W001 PR is `feature/project-bootstrap` → `develop`. Each significant PR requires green CI and an independent **review-only Sub-agent**. It reports findings without edits, commits, pushes, or merges. The main Agent fixes and revalidates. Focused PRs use squash merge unless a documented reason requires another strategy.

## CI and Branch Protection

`.github/workflows/ci.yml` runs for PRs and pushes involving `develop` or `main`. It checks docs, format, lint, entitlements/secret patterns, the zero-runtime-dependency baseline, build, unit tests, and Xcode static analysis. A release PR additionally builds Release configuration. Hardware audio and distribution validation require later phase-specific manual gates.

Repository administrators should configure rulesets for `develop` and `main`: require PRs, the `quality` check, up-to-date branches, conversation resolution, no force pushes or deletion, and reviews where available. Require `release-configuration` on PRs to `main` and stricter release review. Verify exact required check names after the first CI run. Do not claim protection is active until GitHub settings confirm it.

## Release Workflow

After integration validation, open `develop` → `main` release PR with features, fixes, limitations, tests, security status, and release notes. Run full automated and manual gates, release configuration, review-only Sub-agent review, and main-Agent fixes. Merge only after validation, then tag the validated `main` commit. Signing, notarization, production bundle ID, and distribution channel remain undecided until feasibility/release work. Never store signing secrets in the repository.

## Agent Skills

See [AGENT-SKILLS.md](./AGENT-SKILLS.md) for project-local installations and their intended use. `npx skills list --json` verifies visibility. Inspect a Skill's `SKILL.md` before using it.

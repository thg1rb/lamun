# Work 001 — Project Bootstrap

## Status

In Progress — Phase -1 Engineering Preparation.

## Context

Lamun has a complete product and engineering specification and an approved development plan, but no committed baseline, application target, tests, CI, or project knowledge base. Phase 0 and product features must wait for a documented and validated engineering foundation.

## Goals

- Establish `main`, `develop`, and `feature/project-bootstrap` from the unborn repository using only the necessary seed exception.
- Create a minimal native macOS SwiftUI Menu Bar app and baseline unit/UI test targets without audio product behavior.
- Create the required project documents, rules, work/decision directories, README, and status handoff.
- Inspect, discover, evaluate, install where justified, verify, and document project-relevant Agent Skills.
- Configure deterministic format, lint, build, test, static, documentation, dependency, and security checks locally and in GitHub Actions.
- Create the PR template and document branch protection, review-only Sub-agent, and release workflows.
- Validate locally, open the W001 PR to `develop`, run CI, obtain independent review, fix findings, and merge only when complete.

## Non-Goals

- No per-app volume, process-tap production code, Smart Ducking, profiles, rules, audio permissions, or release artifact.
- No claim that an audio architecture, production bundle identifier, minimum supported macOS version, or distribution channel is validated.

## Current State

- `docs/PROMPT.md` and `docs/PLAN.md` exist; this work document and `PROJECT-STATUS.md` are being established before implementation.
- Git is initialized but `main` has no commits, `develop` does not exist, and `origin` points to the GitHub repository.
- There is no Xcode project, source, tests, CI, established docs, or project-local Skill.
- Local machine: macOS 27.0, Xcode 27.0, Swift 6.4. CI compatibility is not yet selected.

## Proposed Changes

- Seed `main` with the approved specification and plan, then branch `develop` and `feature/project-bootstrap`.
- Add a minimal Menu Bar app with an informational placeholder and a functioning test target. Keep the placeholder explicit that audio features are not yet available.
- Add the documentation set listed in `docs/PLAN.md` and make it internally consistent.
- Add format/lint configuration, local check commands, GitHub Actions, and a PR template.
- Evaluate Skills using the built-in discovery workflow; install only verified, relevant candidates at project scope.

## Technical Approach

- Use Xcode's native macOS app target and SwiftUI `MenuBarExtra`; prefer an Xcode project with shared scheme and tests, no third-party runtime dependency.
- Use a clearly temporary development bundle identifier and record its replacement before distribution.
- Choose supported GitHub-hosted macOS runner/Xcode versions after checking current availability. Use unsigned CI builds and no signing secrets.
- Use repository-local configuration and scripts for repeatable local/CI checks. Keep Phase -1 checks proportionate to the empty application.
- Follow `docs/PLAN.md` Section 11 for the one-time root commit and branch sequence; all W001 implementation commits go on `feature/project-bootstrap`.

## Files / Areas Expected to Change

- `Lamun.xcodeproj/`, app source and test directories, repository configuration, `.github/`, `README.md`, and `docs/` knowledge base.
- Project-local Skills directory only if evaluated candidates justify installation.

## Dependencies

- Approved `docs/PROMPT.md` and `docs/PLAN.md`.
- Working local Xcode and Git; GitHub access for PR, CI, and branch-protection configuration.
- A production bundle identifier and signing identity are future release dependencies, not W001 prerequisites.

## Risks

- The unborn Git branch requires a documented seed commit exception.
- CI may not have the local Xcode version; pin a compatible supported runner/Xcode pairing.
- Tooling or Skills may add more maintenance than value; keep only justified, verified additions.
- Project setup may accidentally imply audio feasibility; label audio architecture provisional.

## Security / Privacy Impact

- W001 does not capture audio or request audio permissions.
- Commit no secrets, keys, certificates, or production entitlement claims.
- Establish least-privilege defaults and secret/dependency checks before Phase 0 experiments.

## Acceptance Criteria

- [x] The approved plan and W001 work document are persisted; the required project docs and directories exist and reflect actual state.
- [x] `main`, `develop`, and `feature/project-bootstrap` exist with bootstrap changes isolated to the feature branch.
- [x] The native Menu Bar app and baseline test targets build locally with a shared scheme.
- [x] Formatting, lint, build, unit tests, static analysis, documentation, and security/dependency checks run with documented commands.
- [x] GitHub Actions uses a supported macOS runner and compatible Xcode and passes on the W001 PR.
- [x] Built-in Skills are inspected; discovery, candidate evaluation, any installation, and verification are documented.
- [x] PR template and branch protection plan are present.
- [x] Review-only Sub-agent reports findings; main Agent resolves required findings and reruns checks.
- [ ] W001 is merged to `develop` only after Definition of Done, with status updated honestly.

## Test Plan

1. Clean unsigned Xcode build and unit/UI baseline test run where the runner supports them.
2. Run formatter in check mode, lint, Xcode static analysis, documentation link/required-file checks, and security/dependency checks.
3. Inspect app launch and Menu Bar presence locally if the graphical session allows it; otherwise document the manual validation still due.
4. Verify no audio access, capture, or unexpected network dependency is introduced.
5. Verify local and PR CI results, repository status, branch ancestry, Skill visibility, and documentation links.

## Implementation Notes

Planning sections were completed before substantial bootstrap implementation.

- Created one seed commit on `main` containing the approved specification and plan (`7bc9988`), then created `develop` and `feature/project-bootstrap` at that commit. This is the documented unborn-repository exception.
- Created a native SwiftUI `MenuBarExtra` shell, app sandbox entitlement only, shared Xcode scheme, Swift Testing unit target, and XCTest UI target. There is no audio code or audio permission request.
- Set temporary bundle ID `org.example.lamun.bootstrap` and provisional macOS 14.2 deployment target; Phase 0 must revisit the target and distribution work must replace the ID.
- Selected `macos-26` with Xcode 26.6 for CI after checking the current runner inventory. The local machine uses Xcode 27.0.
- Installed and read three project-local Skills: `swiftui-expert-skill`, `swift-testing-expert`, and `github-actions-hardening`. `skills-lock.json` records their sources and hashes. Core Audio search results did not justify an installation.
- Created the standing documentation, PR template, check scripts, and GitHub Actions workflow. The app has no third-party runtime dependencies.

## Result

Local baseline is built and checked. [PR #1](https://github.com/thg1rb/lamun/pull/1) is open to `develop`; its initial and post-review GitHub Actions quality runs passed. The review-only Sub-agent found no remaining blocker. Branch protection is active on `develop` and `main`. Final documentation CI and merge remain.

Local validation on macOS 27.0 / Xcode 27.0:

- App build: passed.
- Swift Testing unit target: 1 passed, 0 failed (final result bundle `/tmp/lamun-final-unit.xcresult`).
- `xcodebuild analyze`: passed.
- Format, lint, documentation links, security baseline, dependency baseline: passed.
- `actionlint` v1.7.12: passed for `.github/workflows/ci.yml`.
- Initial PR CI quality run `36835523478`: passed (documentation, format, lint, security, dependencies, build, unit tests, static analysis).
- Post-review PR CI quality run `36835936365`: passed, including the new first-party whitespace gate.
- Review-only Sub-agent follow-up on commit `4f785fa`: license and status findings resolved; vendor whitespace exception documented and accepted; no new actionable findings. The reviewer made no file changes.
- GitHub branch protection verified on `develop` and `main`: pull requests, strict required checks (`quality`; also `release-configuration` on `main`), administrator enforcement, linear history, conversation resolution, and force-push/deletion blocks.
- UI target compiled; UI test runner exited before establishing a connection. This local Xcode also reports a CoreDevice/CoreSimulator version mismatch. Root cause is unproven; the UI smoke result remains open and is not reported as passed.
- Built app launched as a process from Finder/open; Menu Bar accessibility inspection timed out, so visual presence remains unverified.

## Deviations From Plan

The optional local UI smoke test did not complete on this machine. Required CI runs the unit target; a functioning interactive macOS/Xcode environment must validate the Menu Bar UI before relying on UI automation.

The review-only Sub-agent found copied Skills lacked retained upstream license notices, and upstream reference files contain trailing whitespace. The notices are now in `docs/licenses/`. A first-party whitespace gate was added; vendored Skill bytes remain intact so lockfile hashes are unchanged.

## Follow-up Work

- Final documentation CI and W001 merge remain. After merge, update the project status to record W001 complete.
- Resolve the local Xcode CoreDevice/CoreSimulator mismatch or run UI smoke validation on a healthy Mac. Do not mistake this environment failure for a passing UI test.
- W002 — Audio Process Discovery, after W001 meets its exit criteria. Do not begin it in this work cycle.

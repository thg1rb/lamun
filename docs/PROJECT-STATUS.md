# Lamun Project Status

## Current Phase

Phase 0 — Technical Feasibility.

## Current Work

W002 — Audio Process Discovery (`docs/work/002-audio-process-discovery.md`). Status: Completed and merged to `develop` in [PR #3](https://github.com/thg1rb/lamun/pull/3) (`47f35e2`, 2026-10-01).

## Completed

- Product and engineering specification reviewed.
- Approved development plan recorded in `docs/PLAN.md`.
- W001 — Project Bootstrap merged to `develop` in [PR #1](https://github.com/thg1rb/lamun/pull/1) (`4e7d60f`). Its documentation, native shell, tests, project-local Skills, CI, and branch protection baseline are in place.

## In Progress

- W002 — Audio Process Discovery merged in [PR #3](https://github.com/thg1rb/lamun/pull/3) at `47f35e2`. Public Core Audio metadata discovery was observed with IINA, Safari, and Chrome Guest. Chrome audio appeared as a helper process; output-I/O state is not exact playback/pause state.
- Manual diagnostic view showed listener events and handled Chrome termination/relaunch. An ad-hoc signed Debug app with the App Sandbox entitlement enumerated process metadata without a permission prompt.
- Local build, unit/integration tests, static analysis, formatting, lint, documentation, whitespace, security-pattern, and dependency checks passed. PR CI quality passed; the review-only Sub-agent findings were resolved and its final pass found no remaining findings.
- W001 XCTest UI runner issue remains recorded. W002 diagnostic UI was manually inspected via accessibility scripting.

## Next

- W003 — Process Capture, Permission, and Sandbox POC (`docs/work/003-process-capture-poc.md`) is the next planned work item. It has not started.

## Blocked

None recorded.

## Known Risks

- Independent per-application gain, process capture, exact audio activity semantics, minimum macOS, production sandbox/signing, latency, and distribution remain unproven until Phase 0.
- No production bundle identifier or distribution channel has been selected.
- This Mac's Xcode CoreDevice/CoreSimulator mismatch still prevents the XCTest UI runner from bootstrapping. W002's Menu Bar diagnostic was manually inspected through accessibility scripting.

## Important Recent Decisions

- Product architecture remains provisional until Phase 0. ADR-001 accepts only a bounded Core Audio discovery prototype direction; it is not a production topology or minimum-OS decision.

## Git State

`main` contains the one-time specification/plan seed commit. `develop` contains W001 and W002; W002 merged in PR #3 at `47f35e2`. The `feature/audio-process-discovery` branch is merged. `main` and `develop` remain protected.

## Active Work Document

Active work document: `docs/work/002-audio-process-discovery.md`. W001 record: `docs/work/001-project-bootstrap.md`.

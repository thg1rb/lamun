# Lamun Project Status

## Current Phase

Phase 0 — Technical Feasibility.

## Current Work

W003 — Independent Per-Application Gain Feasibility (`docs/work/003-per-app-gain-feasibility.md`). Status: In Progress on `feature/per-app-gain-poc`; local POC and automated checks are complete, with review/CI/merge and several hardware/distribution gates outstanding.

## Completed

- Product and engineering specification reviewed.
- Approved development plan recorded in `docs/PLAN.md`.
- W001 — Project Bootstrap merged to `develop` in [PR #1](https://github.com/thg1rb/lamun/pull/1) (`4e7d60f`). Its documentation, native shell, tests, project-local Skills, CI, and branch protection baseline are in place.

## In Progress

- W003 combines the former W003 process-capture/permission item and former W004 independent-gain item. The scope revision and dependencies are recorded in `docs/PLAN.md`; ADR-002 records provisional Outcome B for continued Phase 0 validation, not production approval.
- W002 — Audio Process Discovery completed and merged in [PR #3](https://github.com/thg1rb/lamun/pull/3) at `47f35e2`. Public Core Audio discovery was observed with IINA, Safari, and Chrome Guest. Chrome audio appeared as a helper process; output-I/O state is not exact playback/pause state.
- W002 observed an ad-hoc signed Debug build with the App Sandbox entitlement enumerating process metadata without a permission prompt. This does not validate audio capture or distribution behavior.
- W003's DEBUG-only Core Audio process-tap POC independently scaled IINA and Chrome helper streams at measured RMS ratios 0.249 and 0.499 for requested gains 0.25 and 0.50. Safari remained a third active output client and system output scalar remained 0.25. See [ADR-002](./decisions/ADR-002-per-app-gain-architecture.md) for provisional Outcome B and its limits.
- W003 local validation: Debug build, Release build, `LamunTests`, Xcode static analysis, format, lint, docs, whitespace, security baseline, and dependency baseline passed. Xcode emits the existing CoreDevice/CoreSimulator mismatch warnings; the UI test runner issue remains unresolved and is not treated as passed.
- W003 remaining unvalidated: acoustic listening/loopback and duplicate-leakage assessment, active physical output switching (no second physical device available), permission denial/recovery, five-minute resource/energy sampling, abnormal termination recovery, non-Float32/channel layouts, and Developer ID signed/notarized distribution (no valid identity installed). Mac App Store status remains unknown.

## Next

- After W003 is completed, reviewed, validated, documented, and merged, stop for a status review. W004 is conditional extended lifecycle/endurance validation; W005 is a Smart Ducking input feasibility probe; W006 is the Phase 0 synthesis gate. None is started.

## Blocked

None recorded.

## Known Risks

- Independent process-level signal gain is demonstrated on one host through a DEBUG-only tap/aggregate/HAL callback POC; audible quality, other formats/devices, permission failure behavior, minimum macOS, production sandbox/signing, full latency, and distribution remain unproven until Phase 0.
- A Developer ID signed/notarized direct-distribution path is the W003 minimum distribution feasibility gate; Mac App Store support must be assessed separately.
- This Mac's Xcode CoreDevice/CoreSimulator mismatch still prevents the XCTest UI runner from bootstrapping. W002's Menu Bar diagnostic was manually inspected through accessibility scripting.

## Important Recent Decisions

- Product architecture remains provisional until Phase 0. ADR-001 accepts only a bounded Core Audio discovery prototype direction; it is not a production topology or minimum-OS decision.
- W003 merges the former capture and gain work items into one architecture gate because their behaviors are inseparable for independent audible gain. See the revision note in `docs/PLAN.md`.

## Git State

`main` contains the one-time specification/plan seed commit. `develop` contains W001 and W002; W002 merged in PR #3 at `47f35e2`, with post-merge status closeout in PR #4. W003 branches from `develop` as `feature/per-app-gain-poc`. `main` and `develop` remain protected.

## Active Work Document

Active work document: `docs/work/003-per-app-gain-feasibility.md`. Completed records: `docs/work/001-project-bootstrap.md` and `docs/work/002-audio-process-discovery.md`.

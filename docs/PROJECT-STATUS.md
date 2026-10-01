# Lamun Project Status

## Current Phase

Phase 0 — Technical Feasibility.

## Current Work

W003 — Independent Per-Application Gain Feasibility (`docs/work/003-per-app-gain-feasibility.md`). Status: In Progress on `feature/per-app-gain-poc`. Draft [PR #5](https://github.com/thg1rb/lamun/pull/5) targets `develop` and remains unmerged. Earlier POC checks and read-only review covered the prior commit; continuation changes require fresh validation, CI, and review. Physical-output tone measurements now support independent attenuation and recovery, but the listener, device-switch, permission, lifecycle, latency/endurance, and Developer ID distribution gates remain open. The `release-configuration` check was skipped by workflow conditions on this `develop` PR; a separate unsigned W003 Release-validation build was added locally.

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
- W003 continuation physical-output run: with three concurrent tones, four transient microphone samples per state measured IINA at about −55 dBFS at unity, −60 to −62 dBFS at 50%, and near the microphone noise floor at 0%. Chrome independently moved from about −44 dBFS at unity to −50 dBFS at 50% and near the noise floor at 0%, while IINA stayed muted. Each native tone returned after its tap stopped. Safari stayed audible but drifted about 2–3 dB over the run. These observations support the gain path, but do not replace listening, prove sub-noise-floor suppression, or measure latency. Details are in the W003 work document.
- W003 remaining unvalidated: human acoustic listening/quality and duplicate-leakage assessment, active physical output switching (second stereo device not yet connected), in-process permission recovery and permission-state distinguishability, dropout-gap/audio-quality validation and acoustic latency p95, idle/energy and longer-than-five-minute resource sampling, physical restoration/resource inventory after abnormal exit, non-Float32/channel layouts, and Developer ID signed/notarized distribution (no valid local identity or signing-host connection yet). The user restored System Audio Recording permission; the switch is visibly on. After a fresh Lamun launch with Chrome's active test tone, the tap produced nonzero RMS and 50% callback scaling (`0.0353→0.0177`), while a 0% run produced zero callback output. This confirms callback recovery after permission restoration plus app launch, not listener/audible recovery or in-process recovery. A denied tap previously started callbacks with zero RMS and no error; silence and denial remain indistinguishable in the POC. Force-killed IINA and Lamun sessions were reconciled at process/UI level; a listener-removal warning appeared during Chrome helper churn, and physical output restoration/private HAL object inventory was not captured. Five-minute resource runs measured roughly 0.30% average CPU/105.7–109.1 MiB RSS for one target and 0.38%/102.2–103.7 MiB for two test processes, with callback counts advancing during the afplay run. This is limited host evidence, not a dropout or latency pass. The POC has no output-device change listener or rebuild path; real switching remains blocked by unavailable stereo hardware. Mac App Store status remains unknown. The GitHub CLI is currently unauthenticated, so PR #5's description remains unchanged.

## Next

- After W003 is completed, reviewed, validated, documented, and merged, stop for a status review. W004 is conditional extended lifecycle/endurance validation; W005 is a Smart Ducking input feasibility probe; W006 is the Phase 0 synthesis gate. None is started.

## Blocked

W003 feasibility closeout is blocked on listener confirmation (and permission to use Chrome's local acoustic meter), a second stereo output device, and access to a representative Mac with Developer ID signing/notarization capability. Keep PR #5 draft and unmerged while those and the remaining ordered gates are unresolved.

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

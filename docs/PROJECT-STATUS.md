# Lamun Project Status

## Current Phase

Phase 0 — Technical Feasibility.

## Current Work

W003 — Independent Per-Application Gain Feasibility (`docs/work/003-per-app-gain-feasibility.md`). Status: In Progress on `feature/per-app-gain-poc`. Draft [PR #5](https://github.com/thg1rb/lamun/pull/5) targets `develop` and remains unmerged (current GitHub state cannot be newly checked because `gh` is unauthenticated). Continuation changes require fresh CI and review. Prior repeated physical-output tests support attenuation; the current exploratory sample does not close listening/leakage. The latest active output-change probe exposed a discrepancy between Core Audio default-output selectors and the system-reported endpoint, while the existing tap stayed bound to CMF Buds; device recovery remains unvalidated. The `release-configuration` check was skipped by workflow conditions on this `develop` PR; a separate unsigned W003 Release-validation build was added locally.

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
- W003 previous physical-output run: with three concurrent tones, four transient microphone samples per state measured IINA at about −55 dBFS at unity, −60 to −62 dBFS at 50%, and near the microphone noise floor at 0%. Chrome independently moved from about −44 dBFS at unity to −50 dBFS at 50% and near the noise floor at 0%, while IINA stayed muted. Each native tone returned after its tap stopped. Safari stayed audible but drifted about 2–3 dB over the run. These observations support the gain path, but do not replace listener confirmation, prove sub-noise-floor suppression, or measure latency. A new single exploratory two-tone sample recorded −54.40/−42.24 dBFS at 440/660 Hz; the exact tap/output state was not sufficiently captured, so it is not used to pass the gate. The rebuilt DEBUG-only gain presets produced IINA callback RMS `0.0124→0.0062` at 50%; this is callback evidence only.
- W003 remaining unvalidated: a human listening report for IINA/Chrome at unity, half, and mute; same-run physical leakage and two-app isolation; active output-switch teardown/rebuild and routing (a second stereo output is now present); in-process permission revoke/regrant and reliable permission-state distinguishability; abnormal cleanup/resource inventory; dropout-gap/audio-quality validation and acoustic latency p95; ten-minute endurance/idle/energy sampling; non-Float32/channel layouts; and Developer ID signed/notarized distribution (no valid local identity or signing-host connection yet). The Screen & System Audio Recording permission is currently granted from the earlier W003 run. A denied tap previously started callbacks with zero RMS and no error; silence and denial remain indistinguishable in the POC. A listener-removal warning appeared for an invalid Core Audio object during process churn; whether this is benign invalidation ordering or a listener leak is unresolved. Five-minute resource runs measured roughly 0.30% average CPU/105.7–109.1 MiB RSS for one target and 0.38%/102.2–103.7 MiB for two test processes. These are not dropout or latency passes. The POC has no output-device change listener/rebuild path and currently binds the aggregate to `kAudioHardwarePropertyDefaultOutputDevice`, which disagreed with the system-reported output in this probe. The Chrome Guest microphone permission and local meter are W003 measurement tooling only; Lamun per-app gain has no production microphone requirement. Mac App Store status remains unknown. The GitHub CLI is unauthenticated, so PR #5's current state/description cannot be verified or updated.

## Next

- After W003 is completed, reviewed, validated, documented, and merged, stop for a status review. W004 is conditional extended lifecycle/endurance validation; W005 is a Smart Ducking input feasibility probe; W006 is the Phase 0 synthesis gate. None is started.

## Blocked

W003 feasibility closeout is blocked on human listening confirmation, running the permission revoke/regrant test (regrant requires explicit user confirmation at the OS permission action), active switching between the now-available stereo outputs, end-to-end latency/dropout measurements, extended endurance, and access to a representative Mac with Developer ID signing/notarization capability. The Chrome Guest mic meter permission has already been granted for local validation only. Keep PR #5 draft and unmerged while these gates are unresolved.

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

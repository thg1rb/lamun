# W002 — Audio Process Discovery

## Status

In Progress — Phase 0 Technical Feasibility.

## Context

W001 established the native macOS app shell, test targets, quality checks, CI, and project documentation. No audio behavior is implemented. W002 tests how public macOS APIs identify processes with active output and map them to applications. W001's local UI smoke test remains unresolved because the CoreDevice/CoreSimulator mismatch prevented its runner from bootstrapping; this remains documented and is not a W002 blocker.

`docs/PLAN.md` still named completed W001 as the immediate next step. This work corrects that stale handoff to W002 without changing the approved phase breakdown.

## Goals

- Identify Core Audio process objects and observe active output I/O using documented public APIs.
- Map process records to application name and bundle identity where the OS exposes them.
- Observe lifecycle, simultaneous applications, browser/helper behavior, and event delivery.
- Keep discovery logic outside SwiftUI and expose it through a development-only diagnostic list.
- Record confirmed facts, observations, inferences, and unknowns before drawing architecture conclusions.

## Non-Goals

- Per-application gain, audio capture/taps, routing, volume persistence, Smart Ducking, profiles, rules, or a production mixer UI.
- Tab-level browser discovery, final process filtering, and permanent identity persistence.
- Recording, retaining, logging, uploading, or analyzing audio samples.
- Selecting final minimum macOS, sandbox/distribution strategy, or production audio topology.

## Current State

- Branch: `feature/audio-process-discovery`, created from current `develop` at `5dfa09b`.
- W001 is merged. The working tree was clean before this work.
- Project target is macOS 14.2 with App Sandbox enabled; that deployment target remains provisional.
- Local environment reports macOS 27.0, Xcode 27.0, Swift 6.4. The active SDK is macOS 27.0.
- W001's unit test passed and CI is established. Its UI smoke runner failure remains an open limitation in `PROJECT-STATUS.md` and `TESTING.md`.
- Current Apple documentation and the local Core Audio SDK expose `AudioHardwareSystem.processes`, `AudioHardwareProcess` metadata and output-state properties, and property-listener APIs. Their effective availability on Lamun's provisional deployment target and their behavior on this machine still require verification.
- The inspected machine has IINA, Safari, Chrome, Firefox, Brave, Discord, Teams, and Zoom available for manual observations.

## Research Questions

- **RQ-001 — Discovery:** Does the process list expose the apps observed while they output audio? What changes signal process addition/removal?
- **RQ-002 — Identity:** Which fields are available per process, and which are transient versus suitable as an application key?
- **RQ-003 — App mapping:** Can Core Audio bundle IDs be mapped to `NSRunningApplication` name, bundle URL, executable URL, and icon? How do helper, agent, and multi-process apps behave?
- **RQ-004 — Activity:** Does output-I/O state distinguish playback, pause, silence, stop, and termination? What latency and recent-activity policy can be observed?
- **RQ-005 — Lifecycle:** Are start, pause, resume, termination, relaunch, PID changes, and simultaneous clients reflected without stale rows or leaks?
- **RQ-006 — Browsers:** How do Safari, Chrome, and Firefox represent browser audio and helper processes at process/application level?
- **RQ-007 — System processes:** Are system sounds, notifications, menu bar apps, or background agents exposed, and what metadata is available?
- **RQ-008 — Availability/security:** What API availability, permissions, entitlements, sandbox restrictions, and failure behavior apply to a sandboxed Lamun app?

## Proposed Technical Approach

Use Core Audio's public process-object enumeration as the first candidate, listening for system process-list changes and per-process output-state changes if the API behaves as documented. Register listeners on a serial dispatch queue, reconcile the initial snapshot after registration, and remove listeners when process objects disappear. Publish copied value snapshots to a consumer; do not pass callback-owned audio buffers or objects into SwiftUI.

Use `AudioHardwareProcess` PID and AudioObjectID only for the current runtime process instance. Use optional bundle ID as the preferred cross-launch application identity when present. Resolve app metadata with `NSRunningApplication` where possible. Keep multiple process objects with the same bundle ID visible in diagnostics; do not invent a grouping or filtering policy. A five-second in-memory recent-activity grace is diagnostic only, not product policy.

Expose results in a DEBUG-only diagnostic list inside the existing Menu Bar placeholder. Show process ID, bundle ID, resolved application name, output-I/O state, and recent activity. Label this signal as output I/O activity, not proof that samples are non-silent. If listeners prove unavailable or unreliable, document the evidence before considering low-frequency reconciliation; do not introduce aggressive polling.

## APIs / Frameworks to Investigate

- Core Audio: `AudioHardwareSystem.shared.processes`, `AudioHardwareProcess.pid`, `.bundleID`, `.devices`, `.isRunningOutput`, process-list property, and `AudioHardwareObject.addListener` / `removeListener` with a dispatch queue.
- AppKit: `NSRunningApplication(processIdentifier:)`, `NSWorkspace.runningApplications`, launch/termination notifications, and app metadata (`localizedName`, `bundleIdentifier`, `bundleURL`, `executableURL`, `icon`).
- SDK availability annotations and Apple documentation for the selected APIs. Do not use private APIs, process injection, audio taps, or capture APIs in W002.

## Expected Files / Modules

- `Lamun/Audio/AudioProcessDiscovery.swift` and a small value snapshot type in `Lamun/Audio/`.
- A DEBUG-only diagnostic view and dependency wiring; no production mixer UI.
- `LamunTests/AudioProcessSnapshotTests.swift` and, if deterministic on the host, a narrow integration test for enumeration/listener cleanup.
- This work document plus updates to `docs/PLAN.md`, `docs/PROJECT-STATUS.md`, `docs/ARCHITECTURE.md`, `docs/TESTING.md`, `docs/SECURITY.md`, and `docs/RISK-REGISTER.md` as evidence warrants.
- An ADR only if results justify selecting a discovery approach that materially constrains later work.

## Dependencies

- W001 baseline on `develop`, protected PR workflow, and current Xcode installation.
- Available media/browser/communication apps for manual tests; the inspected host currently has IINA, Safari, Chrome, Firefox, Brave, Discord, Teams, and Zoom.
- No new package or runtime dependency is planned.

## Risks

- Output-I/O state may not track audible non-silent samples or application pause consistently.
- Core Audio may expose helper processes or clients without usable application metadata.
- Property listener availability, delivery order, and object invalidation may differ from expectations.
- The provisional macOS 14.2 target may not support the selected APIs.
- The App Sandbox may restrict process enumeration or metadata mapping.
- A debug-only list may still be hard to inspect if the known local UI runner problem recurs; manual observation and automated UI validation must be distinguished.

## Security / Privacy Impact

W002 reads technical process metadata only. It does not create a process tap, read audio samples, request microphone access, write audio, persist process history, or send data over the network. Runtime snapshots and recent timestamps remain in memory. Logs, if needed, contain only technical error/status data and are not the primary state store. Keep the current sandbox entitlement unless experiments and an ADR justify a specific change.

## Acceptance Criteria

- [ ] A public macOS API identifies at least one tested application during active output I/O.
- [ ] Two simultaneously active applications appear as distinct process records when exposed independently.
- [ ] Useful application identity is mapped where available; missing mappings are represented honestly.
- [ ] PID and AudioObjectID are runtime-only; bundle ID is the preferred app key when available.
- [ ] Pause/stop/termination remove active state and stale process resources without crashes.
- [ ] Relaunch behavior and PID/object ID changes are observed and documented without requiring PID to change.
- [ ] Safari and at least one Chromium-based browser are observed; helper-process behavior is documented.
- [ ] API public status, availability, sandbox, permission, and entitlement findings are recorded from SDK/docs and experiment.
- [ ] No audio samples are captured or persisted.
- [ ] Basic idle/active CPU, memory, callback counts, and update latency are recorded.
- [ ] Unit/integration tests, manual scenarios, local quality gates, PR CI, and review pass; limitations remain explicit.

## Test Plan

1. Build and test the current sandboxed Debug target; run format, lint, static analysis, security, dependency, and documentation checks.
2. Unit-test mapping, absent/duplicate bundle IDs, process-instance distinction, output-state transitions, recent-grace expiry, and stale-record cleanup with deterministic inputs.
3. On macOS, observe IINA playback/pause/resume/quit/relaunch, then two simultaneous apps; record process count, PID, AudioObjectID, bundle ID, app name, and state-change latency.
4. Repeat local audio playback through Safari and Chrome or Firefox; record helper/process behavior. Observe Discord, Teams, or Zoom only when a local test tone or safe built-in test sound is available.
5. Check a system sound/notification and a non-audio running app to distinguish app existence from HAL output activity.
6. Record hardware/OS/Xcode, callbacks, and CPU/memory over five idle minutes and five minutes with two active apps.
7. Re-run W001 UI smoke only if the local runner can initialize; otherwise record the same unresolved CoreDevice/CoreSimulator limitation and manually inspect the debug list if the UI can be opened.

## Experiments

Planned; no W002 experiment has run yet. Record setup, app/version, expected state, observed state, timing, measurements, and evidence category here as work proceeds.

## Findings

No W002 runtime findings recorded yet. Keep entries labeled **Confirmed**, **Observed**, **Inferred**, or **Unknown**. Do not treat API presence in an SDK as proof of target OS availability or runtime behavior.

## Implementation Notes

Planning was completed before source implementation. The current branch is `feature/audio-process-discovery` from `develop`.

## Result

Pending implementation, experiments, validation, CI, review, and merge.

## Deviations From Plan

None so far.

## Follow-up Work

After W002 is merged, W003 — Process Capture, Permission, and Sandbox POC — is next. Do not begin it in this work cycle.

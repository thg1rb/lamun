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

Use Core Audio's public process-object enumeration as the current candidate, listening for system process-list changes and per-process output-state changes. Register listeners on a serial dispatch queue, reconcile the initial snapshot after registration, and remove listeners when process objects disappear. Publish copied value snapshots to a consumer; do not pass callback-owned audio buffers or objects into SwiftUI. This is a feasibility choice for the prototype, not a final production architecture.

Use `AudioHardwareProcess` PID and AudioObjectID only for the current runtime process instance. Use optional bundle ID as the preferred cross-launch application identity when present. Resolve app metadata with `NSRunningApplication` where possible. Keep multiple process objects with the same bundle ID visible in diagnostics; do not invent a grouping or filtering policy. A five-second in-memory recent-activity grace is diagnostic only, not product policy.

Expose results in a DEBUG-only diagnostic list inside the existing Menu Bar placeholder. Show process ID, bundle ID, resolved application name, output-I/O state, and recent activity. Label this signal as output I/O activity, not proof that samples are non-silent. If listeners prove unavailable or unreliable, document the evidence before considering low-frequency reconciliation; do not introduce aggressive polling.

## APIs / Frameworks to Investigate

- Core Audio: `AudioHardwareSystem.shared.processes`, `AudioHardwareProcess.pid`, `.bundleID`, `.devices`, `.isRunningOutput`, process-list property, and `AudioHardwareObject.addListener` / `removeListener` with a dispatch queue.
- AppKit: `NSRunningApplication(processIdentifier:)`, `NSWorkspace.runningApplications`, launch/termination notifications, and app metadata (`localizedName`, `bundleIdentifier`, `bundleURL`, `executableURL`, `icon`).
- SDK availability annotations and Apple documentation for the selected APIs. Do not use private APIs, process injection, audio taps, or capture APIs in W002.

## Expected Files / Modules

- `Lamun/AudioProcessDiscovery.swift` and `Lamun/AudioProcessSnapshot.swift` (kept beside the existing app entry point in W002).
- `Lamun/AudioProcessDiscoveryView.swift` and DEBUG-only wiring in `Lamun/LamunApp.swift`; no production mixer UI.
- `LamunTests/AudioProcessSnapshotTests.swift` and `LamunTests/AudioProcessDiscoveryIntegrationTests.swift` for live enumeration startup and stop cleanup.
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

- [x] A public macOS API identifies at least one tested application during active output I/O (IINA and browser output; this identifies output streams rather than audible samples).
- [x] Two simultaneously active applications appear as distinct process records when exposed independently (IINA and Chrome helper).
- [x] Useful application identity is mapped where available; missing mappings are represented honestly.
- [x] PID and AudioObjectID are runtime-only; bundle ID is the preferred app key when available.
- [x] Stop/termination and resource cleanup were observed; browser pause can leave output-I/O active and is explicitly not treated as playback state (evidence-driven clarification to the original criterion).
- [x] Relaunch behavior and helper PID changes are observed; bundle ID remains stable.
- [x] Safari and Chrome Guest were observed; WebKit and Chrome helper-process behavior is documented.
- [x] Public API status and Swift wrapper availability are documented from SDK/docs; signed Debug sandbox metadata access and lack of a prompt were observed; release implications remain unknown.
- [x] No audio samples are captured or persisted.
- [x] Basic idle/active CPU, memory, listener counts, and qualitative update observations are recorded; precise callback latency is not measured.
- [x] Unit and integration tests, manual scenarios with documented limitations, and local quality gates pass.
- [ ] Required PR CI and review-only Sub-agent review pass.

## Test Plan

1. Build and test the current sandboxed Debug target; run format, lint, static analysis, security, dependency, and documentation checks.
2. Unit-test mapping, absent/duplicate bundle IDs, process-instance distinction, output-state transitions, recent-grace expiry, and stale-record cleanup with deterministic inputs.
3. On macOS, observe IINA playback/pause/resume/quit/relaunch, then two simultaneous apps; record process count, PID, AudioObjectID, bundle ID, app name, and state-change latency.
4. Repeat local audio playback through Safari and Chrome or Firefox; record helper/process behavior. Observe Discord, Teams, or Zoom only when a local test tone or safe built-in test sound is available.
5. Check a system sound/notification and a non-audio running app to distinguish app existence from HAL output activity.
6. Record hardware/OS/Xcode, callbacks, and CPU/memory over five idle minutes and five minutes with two active apps.
7. Re-run W001 UI smoke only if the local runner can initialize; otherwise record the same unresolved CoreDevice/CoreSimulator limitation and manually inspect the debug list if the UI can be opened.

## Experiments

### E1 — Core Audio enumeration and IINA playback

- **Setup:** macOS 27.0, Xcode 27.0 / SDK 27.0; standalone Swift probe using `AudioHardwareSystem.shared.processes`; IINA played a generated 12-second local 440 Hz WAV. No Lamun audio capture was used.
- **Observed:** While IINA played, object 130 reported PID 92030, bundle ID `com.colliderli.iina`, application name `IINA`, and `isRunningOutput == true`. After playback stopped, the same connected process reported `false`. While idle, the process remained in the list. This distinguishes HAL connection from output-I/O state.
- **Confirmed:** The SDK header documents the process-object list as processes connected to the audio system. `IsRunningOutput` means the process is running I/O and has at least one active output stream; it does not establish non-silent samples or user-perceived sound.

### E2 — Safari and Chrome browser output, helper identity, pause

- **Setup:** Safari (already running) and a Chrome Guest session played the same local test WAV in loop mode using browser controls. No network content or personal Chrome profile was used.
- **Observed:** Safari output appeared as PID 93189, bundle ID `com.apple.WebKit.GPU`, resolved app name `Safari Graphics and Media`, output active. Chrome output appeared as a separate helper process, PID 94256, bundle ID `com.google.Chrome.helper`; `NSRunningApplication` returned no name/icon for that PID. Both browser records were output-active simultaneously. The top-level browser process was not the process carrying browser audio in this observation.
- **Observed:** After Chrome's play control showed the media paused, its helper's output-I/O property remained true for several seconds. Later both Chrome and Safari reported false after media stopped. Therefore this property is not a reliable paused-versus-playing signal and must be described as output-I/O activity, not playback truth.
- **Observed:** Quitting Chrome removed its audio process record. Reopening a Guest session and starting the test WAV produced a new helper PID (95502) with the same `com.google.Chrome.helper` bundle ID. PID is an instance identifier; bundle ID is a better application key where present. The browser may expose a helper identity rather than the browser application's bundle ID.

### E3 — Process metadata breadth

- **Observed:** The HAL process list also contained system services, background agents, menu-bar applications, browser helpers, and processes with missing bundle IDs or no resolvable `NSRunningApplication`. Lamun itself appeared as a HAL client while the app ran. Enumeration is not a ready-made user-facing list of applications.
- **Unknown:** Whether notifications/system sounds are exposed consistently and what product filtering policy should be used.

### E4 — API availability and security

- **Confirmed from local SDK interface:** `AudioHardwareSystem`, `AudioHardwareProcess`, `PropertyListenerDelegate`, and the Swift property-listener APIs used by this prototype are annotated for macOS 15.0 and later. The project deployment target remains 14.2, so the prototype shows a diagnostic placeholder below macOS 15. This does not prove that lower-level C APIs lack earlier availability.
- **Confirmed from local SDK headers:** Process object list, PID, bundle ID, device list, and running-output property selectors are public Core Audio declarations. No private API was used.
- **Unknown:** Whether process visibility differs on macOS 14; final production entitlements, signing, store eligibility, and distribution constraints.
- No permission prompt appeared during metadata-only enumeration. This observation is not a general permission guarantee.

### E5 — In-app listeners, lifecycle, and signed sandbox run

- **Observed:** The DEBUG Menu Bar diagnostic was opened via macOS accessibility scripting. It enumerated IINA and Chrome helper rows and reported both as output-I/O active while both apps were playing. Its property-listener event counter showed 110 after initial activity, advanced to 114 after a browser control changed, then to 116 after Chrome quit and 122 after Chrome relaunched and began output. This is evidence of delivered property events on this host; it is not a latency benchmark.
- **Observed:** Quitting Chrome removed its helper rows from the live diagnostic view without a crash. Relaunching created helper PID 2856 (earlier helper PIDs were 94256 and 95502) while preserving bundle ID `com.google.Chrome.helper`. IINA and Chrome were simultaneously reported active. IINA's process output flag changed after playback ended.
- **Confirmed for this local configuration:** A Debug build ad-hoc signed with `CODE_SIGN_IDENTITY=-` embedded `com.apple.security.app-sandbox=true` and `com.apple.security.get-task-allow=true`. Running that app and opening its diagnostic view exposed the same local Core Audio process metadata, with no permission prompt. This is a local Debug observation, not a release signing/distribution guarantee.
- **Observed:** The diagnostic list includes many system and helper clients and some anonymous entries. This reinforces that raw Core Audio enumeration cannot be exposed directly as a polished user-facing application list.

### E6 — Performance sample

- **Setup:** macOS 27.0; `top` sampled Lamun PID 3706 every 10 seconds for 31 samples (~5 minutes), while the sandbox-enabled DEBUG diagnostic was open and IINA plus Chrome Guest had active output. A five-minute generated tone and local looping browser test page were used. The Chrome helper was PID 2856 during this run.
- **Observed:** Lamun used 0.0–0.8% CPU across the 31 `top` samples (28 samples were 0.0%) and stayed near 30 MiB resident memory. This is a single-machine, short-duration feasibility sample, not an energy or population benchmark. The diagnostic's live list showed both audio processes; callback count was observed separately in E5.
- **Observed idle baseline:** Before discovery view was open, Lamun was sampled for 31 ten-second `top` samples and remained at 0.0% CPU and approximately 30 MiB resident memory. Treat this as a baseline only; it does not prove long-run stability.

### E7 — Listener behavior and remaining limits

- **Observed:** The in-app listener delivered property changes and the diagnostic view responded to browser lifecycle events. Integration tests require a registered process-list listener, exercise discovery start/stop cleanup, preserve unrelated delegates, and inject process-list listener failure to verify the warning survives enumeration while Lamun removes its failed observer. This does not establish callback latency under load or multi-hour stability.
- **Observed:** Five-minute idle samples reported 0.0% CPU / ~30 MiB resident memory; the two-app discovery sample reported 0.0–0.8% CPU / ~30 MiB resident memory for Lamun on this host. Energy impact and other hardware/OS combinations remain unknown. The W001 XCTest UI runner still cannot bootstrap because of the CoreDevice/CoreSimulator mismatch; W002 UI behavior was manually inspected with accessibility scripting.

## Findings

- **Confirmed:** Public Core Audio process objects expose connected clients and per-process active output-stream state on the tested current OS. The local Swift wrapper requires macOS 15.
- **Observed:** IINA active output state changed true during playback and false after its short file ended. Safari output mapped through a WebKit GPU process; Chrome output mapped through a Chrome helper. Multiple applications appeared independently. Chrome pause retained output-I/O true for several seconds. Termination removed its row; relaunch used a new helper PID and the same bundle ID.
- **Inferred:** Discovery needs a filtering/grouping policy and should treat helper processes as app-associated signals only where mapping is evidence-backed. Bundle ID is preferred over PID for cross-launch identity but is not always the browser's top-level bundle ID.
- **Unknown:** macOS 14-compatible implementation, exact event latency, system sounds, identity for anonymous/system clients, and long-run resource costs. Listener start/stop cleanup passes an integration test; manual termination/relaunch also removed the Chrome rows.

## Implementation Notes

Planning was completed before source implementation. The current branch is `feature/audio-process-discovery` from `develop`. A DEBUG-only diagnostic view uses Core Audio process-list and output-state listeners on macOS 15+, with copied `AudioProcessSnapshot` values and `NSRunningApplication` metadata mapping. Unit tests cover bundle identity, unknown identity, activity grace, and state labels; integration tests verify process-list listener registration, start/stop cleanup, and preservation of other Core Audio delegates. Listener failures are surfaced separately from transient enumeration errors. No audio sample APIs are used. Relevant verified Skills used: `swift-testing-expert` and `swiftui-expert-skill`; Core Audio behavior was checked against Apple documentation and the local SDK because no suitable dedicated Core Audio Skill was available.

## Result

Prototype and experiments are implemented. Local Debug build, unit and integration tests, static analysis, formatting, lint, documentation links, whitespace, security-pattern, and dependency checks pass after resolving the review findings: listener setup failures remain visible after enumeration, and both success and injected-failure cleanup remove only Lamun-owned delegates. Regression tests cover these behaviors. A sandbox-enabled ad-hoc signed Debug build also ran and enumerated process metadata. The five-minute active discovery sample and idle sample completed. CI, review, and PR merge remain pending. The separate XCTest UI target still exits before bootstrapping with signal kill under the local CoreDevice/CoreSimulator mismatch; the DEBUG Menu Bar diagnostic itself was manually inspected through accessibility scripting. No production discovery/filtering architecture is accepted yet.

## Deviations From Plan

The originally proposed acceptance that pause must immediately clear active state cannot be satisfied by `isRunningOutput`: Chrome media was paused while its output-I/O state remained true for several seconds. The acceptance is clarified to require the stop/termination and cleanup behavior plus truthful documentation of pause semantics; the property is not represented as a playback detector. Browser experiments show output-stream state can remain true while Chrome media is paused. The signal means active output I/O, not current audible content. We clarified the original pause acceptance wording to require this limitation to be documented rather than claim the API detects pause. W001 XCTest UI smoke remains unresolved, though W002 diagnostic UI was manually inspected through accessibility scripting.

## Follow-up Work

After W002 is merged, W003 — Process Capture, Permission, and Sandbox POC — is next per `docs/PLAN.md`. Do not begin it in this work cycle. These discovery results do not prove capture or per-app gain feasibility.

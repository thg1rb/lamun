# W003 — Independent Per-Application Gain Feasibility

## Status

In Progress — Phase 0. Scope consolidates the former W003 process-capture/permission POC and former W004 independent-gain/routing POC. See the dated revision note in `docs/PLAN.md`.

## Context

W002 verified public Core Audio process discovery but did not capture samples or control gain. It observed that browser audio can be emitted by helper processes and that `isRunningOutput` indicates active output I/O, not exact audible playback. W003 must prove or reject an architecture that independently changes the effective audible level of multiple applications before production mixer work begins.

The existing project is a native SwiftUI macOS shell with a provisional macOS 14.2 target, a DEBUG-only discovery view, Swift Testing unit tests, XCTest UI tests, and macOS GitHub Actions CI. The W001 UI-test runner still fails to bootstrap locally because of the documented CoreDevice/CoreSimulator mismatch; it remains unrelated unless it directly blocks this work.

## Goals

- Determine whether a supported public API offers direct arbitrary per-process gain.
- Experimentally evaluate public process-tap capture, original-output suppression, gain processing, and rendering to the current physical output.
- Prove or disprove independent effective gain for two simultaneous target applications without affecting an untargeted application or system master volume.
- Measure feasibility-level latency, CPU, memory, audio quality, lifecycle, cleanup, and output-switch behavior.
- Validate capture permission behavior and document entitlements, App Sandbox, Mac App Store, and direct-distribution implications.
- Produce an evidence-backed architecture classification and an ADR when results justify one.

## Non-Goals

- Production mixer architecture/UI, persistence, Smart Ducking, VAD, profiles, rules, browser tab mixing, per-app routing, professional effects, or a production virtual audio device/driver.
- Recording, storing, uploading, transcribing, logging, or analyzing audio beyond the transient measurements required by this POC.
- Selecting a final minimum macOS version solely from a single host's result.

## Current State

- Branch starts from `develop` at W002 closeout `08def26`.
- W002 source is `AudioProcessDiscovery` and its copied process snapshots. PID and AudioObjectID are runtime process-instance identifiers; bundle identity is useful when present but helper IDs may differ from the top-level app.
- W002 observed IINA, Safari/WebKit, and Chrome Guest audio clients, including simultaneous clients and Chrome helper process relaunches.
- Current local environment recorded by W002: macOS 27.0 / Xcode 27.0 / SDK 27.0; re-record versions during W003.
- W002 observed an ad-hoc signed Debug build with App Sandbox enabled enumerating process metadata without a permission prompt. This does not validate capture permission or production signing/distribution. `docs/SECURITY.md` is corrected as part of this work to match that limited observation.
- The Core Audio taps guide documents process taps, mute behavior, use as aggregate-device input, `NSAudioCaptureUsageDescription`, and a system audio recording prompt when starting an aggregate containing a tap. The guide's sample requires macOS 14.2+. Verify every selected API and actual host behavior before treating this as Lamun support evidence.
- Current SDK `AudioHardwareProcess` documentation exposes process metadata and activity, not a writable arbitrary-gain property. The device process-mute selector described by the local SDK is mute-only and scoped to the current process on a physical device. Direct gain remains a research question until the API inventory and supported documentation are checked in this work.

## W002 Dependencies

- W001 project, CI, quality baseline, and review workflow are complete.
- W002 process discovery is merged in `develop` and is available as a runtime discovery input. Do not reinterpret its playback-state finding without a reproducible contradictory result.
- Start from latest `develop` on `feature/per-app-gain-poc`.

## Research Questions

1. Is there a public writable arbitrary gain control on `AudioHardwareProcess` or another per-process public object? Does a device process-mute property provide only mute or any useful gain control?
2. Can a `CATapDescription` target one process and suppress its original output while Lamun reads the tap? What are `.muted`, `.mutedWhenTapped`, and `.unmuted` failure behaviors?
3. Can a captured tap be multiplied and rendered to the selected physical output without double playback, echo, leakage, or affecting unrelated clients?
4. Is a private aggregate device containing one or several taps sufficient, or must the physical output be part of the aggregate? How are clocks, formats, and cleanup handled?
5. Can two target applications be controlled independently while a third untargeted application and system volume remain unchanged?
6. How do helper-process identity, process termination/relaunch, permission denial/revocation, output switching, and app shutdown affect resources and audible recovery?
7. What added latency distribution, CPU, memory, energy indication, and audible artifacts occur with one and two controlled applications?
8. Is the leading public-API design compatible with a credible Developer ID signed/notarized direct-distribution path? What remains unknown for the Mac App Store?

## Candidate Architectures

| Candidate | Initial status | Experiment / disposition |
|---|---|---|
| A — Direct public process gain | No gain property found in the documented `AudioHardwareProcess` surface so far; confirm against current SDK/docs. Process mute is not arbitrary gain. | Inventory public process/device control properties and write support. Reject if there is no supported arbitrary per-process gain; do not substitute device volume. |
| B — Process Tap + gain + physical-output render | Public process taps and mute behavior are documented; independent-gain feasibility is unknown. | One muted tap per target, consume its stream through a private aggregate device, apply sample gain, and render to the selected physical output. Prove no duplicate original output. |
| C — Tap + aggregate topology | Apple's tap sample uses an aggregate device as a tap input; its necessity for Lamun output routing is unknown. | Compare tap-only input aggregate with a topology that also includes the physical output. Record clock, format, visibility, device-change, and cleanup behavior. |
| D — Virtual device/driver | Unvalidated fallback; very high distribution and maintenance impact. | Research only. Identify the driver/extension and install/signing implications; do not implement a driver. |
| E — Other public architecture | Not investigated. | Consider only if current Apple documentation or experiment shows a materially better supported route. |

## Proposed Technical Approach

- Keep all low-level audio resources in an isolated DEBUG-only POC service, not a SwiftUI view. The existing diagnostic surface may expose temporary target selection/start/stop and gain steps; it must remain visibly diagnostic and must not become product UI.
- First perform the API/header/documentation audit. If Candidate A is unsupported, continue to the public process-tap proof rather than ending without evaluating capture/rerender feasibility.
- Begin with one target and a local non-clipping test signal. Verify capture, suppression, actual audible output, and reliable restoration on every error path before adding a second target.
- Then run two target apps simultaneously plus one untargeted app. Use local test media in IINA and Chrome Guest where available; use Safari as the untargeted client. Record the actual process object/PID tapped, especially for browser helpers. No browser tab semantics are in scope.
- Process normalized gain from unity down to silence. Do not amplify above unity. Keep sample buffers transient; perform no disk, network, UI, or blocking work in a real-time callback. Any gain ramp is only a click-prevention POC mechanism, not Smart Ducking.
- Use a private aggregate device unless experiments justify another setting. Destroy aggregate devices, taps, audio units/IOProcs, listeners, and tasks on every stop/failure path. On render failure, restore the target to its normal output by stopping/destroying the suppressing tap.
- Do not write or change macOS master volume. Record its before/after state and keep it outside Lamun's gain model.

## APIs / Frameworks to Investigate

- Core Audio Process Tap: `CATapDescription`, `CATapMuteBehavior`, `AudioHardwareCreateProcessTap`, `AudioHardwareDestroyProcessTap`, tap stream format and UID.
- HAL aggregate devices: `AudioHardwareCreateAggregateDevice`, tap-list composition, private-device settings, `AudioHardwareDestroyAggregateDevice`, clock source and subdevice/subtap behavior.
- Audio output processing: compare an IOProc or suitable Audio Unit/AVFoundation output path based on support for real-time tap input and selected physical output; document why the selected minimal path is appropriate.
- `AudioHardwareProcess`, device properties including `kAudioDevicePropertyProcessMute`, and local SDK declarations/availability.
- Permission purpose string `NSAudioCaptureUsageDescription`, TCC System Audio Recording permission, Info.plist and sandbox/signing behavior.
- Apple Developer ID, Hardened Runtime, notarization, App Sandbox requirements for Mac App Store, and process-tap review constraints.
- Swift Testing for deterministic gain/sample math and resource-state logic; no new third-party runtime dependency without a documented necessity.

## Expected Files / Modules

- New isolated POC audio service and DEBUG-only diagnostic controls under `Lamun/`; keep `AudioProcessDiscovery` production-independent and reusable only where W002's verified observations support it.
- Deterministic unit tests under `LamunTests/` for gain normalization/math, supported buffer/channel shapes, and resource-state transitions.
- `Lamun.xcodeproj` / target configuration only for POC source, usage-description metadata, or test wiring justified by the chosen experiment.
- This work document, revised `docs/PLAN.md` and `docs/PROJECT-STATUS.md`, and evidence-based updates to `docs/ARCHITECTURE.md`, `docs/SECURITY.md`, `docs/TESTING.md`, and `docs/RISK-REGISTER.md`.
- `docs/decisions/ADR-002-per-app-gain-architecture.md` if the evidence supports selecting/rejecting a material architecture. Do not create a decision record that claims a decision when the result remains unknown.

## Security / Privacy Impact

This POC reads protected system audio. Add only the required purpose string and permissions; test prompt, grant, denial, and settings-based recovery. Audio samples remain in memory only for gain/render/ephemeral measurement, are promptly released, and never enter files, logs, crash attachments under Lamun's control, analytics, or network. Use technical lifecycle/errors only in logs. Confirm signed Debug sandbox behavior separately from the required Developer ID direct-distribution assessment. Do not commit signing credentials or personal audio.

## Permission / Entitlement Impact

Initial evidence says the Apple tap sample requires `NSAudioCaptureUsageDescription` and prompts for system audio recording access when first starting an aggregate device containing a tap. Verify the exact current OS prompt, TCC setting, denied behavior, and whether app sandbox/hardened runtime change functionality. Do not assume metadata-only W002 behavior predicts capture behavior. Keep the existing sandbox setting unless a reproducible experiment and ADR justify changing it.

## Distribution Impact

The hard feasibility gate is a credible Developer ID signed and notarized direct path, not Mac App Store availability. Assess Developer ID signing, Hardened Runtime, notarization, purpose string/permissions, required entitlements, update and uninstall implications. Classify Mac App Store support separately as Supported, Potentially Supported—Further Validation Required, Not Supported by Current Architecture, or Unknown. If no Developer ID credentials are available for a real signed/notarized run, document the path as assessed but not experimentally validated; never expose secrets or imply completion.

## Performance Risks

- Tap, processing, and output buffers add latency and may drift or underrun.
- Multiple taps/streams may increase CPU, memory, or energy use.
- Sample-rate/channel-format conversion may add delay, artifacts, or imbalance.
- Device changes or helper-process restarts may invalidate tap or render resources.
- Original-output suppression can leave an app silent if cleanup fails; unsafe real-time callbacks can interrupt all output.

## Acceptance Criteria

- [ ] AC-W003-001 — A and B are simultaneously audible in the POC and independently addressable through supported public APIs.
- [ ] AC-W003-002 — Current public API/SDK research determines whether arbitrary direct process gain exists; process mute and device volume are correctly distinguished.
- [ ] AC-W003-003 — At least one plausible independent-gain architecture is experimentally evaluated. Candidate A is not counted as the only experiment when no gain property exists.
- [ ] AC-W003-004 — Setting A to 0.30 leaves B at unity; changing B to 0.60 leaves A at 0.30, confirmed audibly and by transient signal measurement where available.
- [ ] AC-W003-005 — C, system master volume, and unrelated output remain unchanged when A/B gain changes.
- [ ] AC-W003-006 — Original-output suppression is demonstrated; no double output, echo, phase/comb effect, or unexpected leakage is heard/observed.
- [ ] AC-W003-007 — Target pause/resume, termination, relaunch/PID change, and render/tap failure do not crash Lamun or leave stale resources/audio suppression.
- [ ] AC-W003-008 — Built-in output and another locally available device are switched while active; otherwise the case is explicitly Not Tested with reason and risk.
- [ ] AC-W003-009 — Added pipeline latency includes reproducible p50, p95, and maximum plus buffer duration/size, format, output, and controlled-app count; compare to ≤50 ms p95 provisional gate.
- [ ] AC-W003-010 — CPU and memory are sampled under idle, one-app, and two-app conditions; energy observations are included when practical.
- [ ] AC-W003-011 — Clicks, pops, dropouts, echo, double audio, pitch/time drift, channel imbalance, and resampling artifacts are explicitly reported.
- [ ] AC-W003-012 — Capture permission prompt, authorized, denied, and recovery behavior are observed/documented where the host permits.
- [ ] AC-W003-013 — API availability, usage string, entitlements, sandbox, hardened runtime, and current/provisional minimum macOS implications are documented from SDK/docs and experiment.
- [ ] AC-W003-014 — Direct Developer ID signing/notarization path is assessed and Mac App Store support separately classified; unavailable credentials are not reported as validated.
- [ ] AC-W003-015 — No captured audio is persisted, uploaded, transcribed, or logged.
- [ ] AC-W003-016 — Taps, aggregates, IOProcs/audio units, listeners, and tasks are cleaned up after normal stop, errors, shutdown, and restart recovery where practical.
- [ ] AC-W003-017 — Deterministic tests pass for new gain/buffer/state logic; integration tests do not claim to prove device-specific sound quality.
- [ ] AC-W003-018 — Required manual scenarios and unavailable hardware/permission cases are recorded honestly.
- [ ] AC-W003-019 — Outcome is explicitly classified A/B/C/D; a latency result slightly above threshold may be marked conditionally viable only with identified optimization source.
- [ ] AC-W003-020 — Work, architecture, security, testing, risks, ADR, and status docs reflect actual findings and known limitations.
- [ ] AC-W003-021 — Build and local quality checks pass, CI is green, read-only review findings are resolved/justified, and the PR is merged to `develop`.

## Test Plan

### Automated

- Parameterized normalized gain values `0.0`, `0.25`, `0.5`, `0.75`, and `1.0`; reject/clamp invalid values according to the documented POC helper contract.
- Gain multiplication for supported float/integer PCM representation and interleaved/non-interleaved channel layouts selected by the POC; verify silence/unity, channel preservation, finite values, and no accidental over-unity gain.
- Verify optional ramp endpoints/monotonicity if a ramp is required to prevent clicks.
- Verify resource-state transitions and cleanup are idempotent for start/stop and partial setup failures.
- Build, `LamunTests`, static analysis, format, lint, docs, whitespace, security, dependency checks. Audio behavior requires manual macOS validation.

### Manual / Integration

1. **One app:** IINA local tone; unity → 0.75 → 0.50 → 0.25 → zero; verify output is audible then attenuates/silences and returns cleanly to normal on POC stop.
2. **Two apps:** IINA and Chrome Guest (or another independently emitting app); A=0.25/B=1.0, then A=0.25/B=0.50; listen and compare transient per-stream RMS and final output levels.
3. **Untargeted:** Safari remains audible and unchanged while A/B vary; record macOS master volume before/after without setting it.
4. **Pause/resume and identity:** Apply gain, pause/resume, terminate/relaunch targets; record PIDs/object IDs, process mapping, and resource recreation. Do not treat W002 `isRunningOutput` as exact playback truth.
5. **Output:** Built-in device → another available device → built-in while active; test stream format change if available. If unavailable, mark not tested.
6. **Failure/quit:** Deny permission, fail/stop tap/render, quit Lamun, and relaunch. Confirm target audio recovers and all temporary taps/aggregates/listeners/IOProcs are gone.
7. **Latency/quality:** Capture callback timestamps/frames without saving sample data; report p50/p95/max and buffer metadata. Listen for clicks, pops, glitches, echo, duplicates, pitch/timing drift, channel imbalance, and resampling artifacts.
8. **Resources:** Five-minute comparable idle, one-target, and two-target samples; record OS/Xcode/device, CPU range, RSS range, sample rate, buffer sizes, and energy indication when available.
9. **Distribution/privacy:** Inspect resulting entitlements and Info.plist; observe relevant OS permission state; perform no file/network operation with audio data. Assess both channel requirements using current Apple documentation.

## Experiments

To be filled incrementally, with each entry labeled **Confirmed**, **Observed**, **Measured**, **Inferred**, **Unknown**, or **Not Tested**, setup and OS/Xcode/device details, and links to primary references.

## Findings

No W003 experiment results yet.

## Measurements

Record per configuration: output device; process IDs/object IDs/app mapping; sample rate and channel layout; input/output frames and buffer durations; added-latency p50/p95/max; CPU/RSS sample range; energy note; gain steps; transient RMS ratios; audible artifacts; start/stop/recovery results. Do not save audio samples or raw callback payloads.

## Implementation Notes

Planning and this work document precede substantive source changes. Branch: `feature/per-app-gain-poc`, from `develop`. Do not add production controls or persist gain. Keep POC APIs internal/debug-only and lifecycle ownership outside SwiftUI.

## Result

Pending experiments, validation, review, and merge.

## Architecture Decision

Pending evidence. Use one of the explicit outcomes: A — direct gain feasible; B — tap/re-render feasible; C — virtual device required; D — requirements need re-planning. Record Mac App Store status separately. If no outcome can be justified, leave the decision unresolved and do not unlock W007.

## Deviations From Plan

None at start. Record the scope consolidation here and in `docs/PLAN.md`; record later changes with evidence.

## Follow-up Work

W004 extended lifecycle/endurance validation, W005 Smart Ducking input feasibility, and W006 Phase 0 synthesis remain conditional on the W003 outcome. Do not start any follow-up in this work cycle.

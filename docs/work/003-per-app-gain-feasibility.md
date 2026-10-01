# W003 — Independent Per-Application Gain Feasibility

## Status

In Progress — Phase 0. Local POC, documentation updates, and automated validation are complete; read-only review, CI, PR integration, and the remaining device/distribution limitations are outstanding. Scope consolidates the former W003 process-capture/permission POC and former W004 independent-gain/routing POC. See the dated revision note in `docs/PLAN.md`.

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

### X-001 — SDK/API and permission review

- **Confirmed:** Current public `AudioHardwareProcess` metadata API and the local macOS 27 SDK process property declarations expose process identity/output state, but no arbitrary per-process gain setter was found. `kAudioDevicePropertyProcessMute` is a mute property for the current client on a physical device; it is not an arbitrary gain API.
- **Confirmed:** Apple's public Process Tap API supports capturing process output and offers mute modes. `mutedWhenTapped` suppresses the original while another client reads the tap. A tap is read as an input of an aggregate device. The documented permission key is `NSAudioCaptureUsageDescription`; first tap/aggregate use prompted for system-audio recording permission.
- **Observed:** The initial Debug generated plist silently omitted the requested purpose key. Replacing only the Debug generated plist with `Lamun/Info-Debug.plist` made the key present in the built bundle. The Debug target now uses a separate sandbox plus `com.apple.security.device.audio-input` entitlement. A dedicated Release entitlement file is not used; Release remains on the existing app-sandbox-only entitlements.
- **Observed:** With AVAudioEngine consuming a private aggregate containing only the tap and rendering to the default output separately, `AVAudioEngine.start()` failed with AVFAudio error `-10875` (`kAudioUnitErr_FailedInitialization`). Adding the standard audio-input entitlement did not change this result.
- **Observed:** Switching the POC to a HAL aggregate containing the tap and built-in output subdevice, with a HAL I/O callback reading tap buffers and writing output buffers, started successfully and delivered nonzero Float32 stereo samples. This is the candidate C topology currently under test; it is not a production decision.
- **Confirmed source:** [Apple Process Tap capture guide](https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps), [Apple `AudioHardwareProcess`](https://developer.apple.com/documentation/coreaudio/audiohardwareprocess), [Apple `CATapMuteBehavior`](https://developer.apple.com/documentation/coreaudio/catapmutebehavior), [Apple audio-input entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.device.audio-input), [Apple notarization requirements](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

### X-002 — Two-process gain and third-process activity

- Setup: macOS 27.0, Xcode 27.0 / SDK 27.0, MacBook Pro Speakers, 48 kHz, synthetic local stereo PCM tones in IINA and Chrome, Safari playback later used as an untargeted third process. No recorded/user audio. App was an ad-hoc signed Debug build with App Sandbox, audio-input entitlement, `get-task-allow`, and granted System Audio Recording permission; this does not represent Developer ID distribution signing.
- **Observed:** Core Audio exposed IINA (`com.colliderli.iina`, PID 46960, object 128), Chrome helper (`com.google.Chrome.helper`, PID 47149, object 129), and Safari WebKit GPU (`com.apple.WebKit.GPU`, PID 93189, object 124) as separate output-I/O clients. These are process identities, not a proven final app-grouping policy.
- **Measured:** IINA and Chrome each ran a private tap + private aggregate with the same physical output as a subdevice. Each callback exposed one 2-channel input buffer and one 2-channel output buffer, each 4096 bytes (512 Float32 stereo frames; 10.67 ms at 48 kHz). Both streams delivered nonzero samples concurrently.
- **Measured:** IINA at gain 0.25: input RMS 0.1079 → output RMS 0.0269 (0.249 ratio); Chrome at gain 1.00: input RMS 0.0565 → output RMS 0.0565. After changing Chrome to 0.50, Chrome measured 0.0565 → 0.0282 (0.499 ratio), while IINA remained at 0.25 (later input/output 0.1054 → 0.0263). Values are transient callback metrics only.
- **Inferred from documented mute mode and observed callback:** In `mutedWhenTapped`, the original targeted client should be suppressed while the tap is read and the captured frames are written to the aggregate's physical output. The code path uses this documented mode. Whether the physical output actually contains no duplicated/leaked original signal was not confirmed by listening or analog loopback; audible suppression remains **Not Tested**.
- **Observed:** While A/B sessions were active and Safari's WebKit GPU process remained output-I/O active, the physical output device's master scalar volume read 0.25 both before and after the gain experiments. This supports isolation from master volume; it is not a calibrated acoustic comparison of Safari's level.
- **Measured:** Callback input-to-output host-time delta p50/p95/max was 23.90/23.90/23.90 ms for the active streams. This timestamp delta is a repeatable graph metric, not a complete acoustic round-trip measurement. Built-in output reports 512-frame nominal buffer, 70-frame output latency and 74-frame safety offset at 48 kHz (1.46 ms and 1.54 ms respectively); end-to-end speaker latency was **Not Tested**.
- **Measured:** During the two-session + discovery diagnostic interval, `ps` sampled Lamun at 4.5% CPU and 89,520 KiB RSS. During a later single-session diagnostic interval, three `top` observations showed 0.0%, 5.8%, and 7.0% CPU with about 34 MiB reported memory. These are point samples with no controlled idle comparison, not a five-minute profile or energy measurement.
- **Observed:** Process-list callbacks during Safari/process churn surfaced Core Audio listener remove/register warnings for process objects that had already become invalid. This appears to be W002 discovery lifecycle behavior and is recorded for review; the gain callbacks continued to run.
- **Observed:** The earlier MenuBarExtra-hosted live list produced a Lamun crash report due SwiftUI graph recursion while the menu contents changed. W003 moved the diagnostic into a dedicated DEBUG window and reduced dynamic menu contents. The crash artifact is local and is not committed.
- **Observed:** With a Chrome helper tap session active at unity, the diagnostic's “Stop all sessions and quit Lamun” action stopped the Lamun process. Core Audio still showed Chrome and Safari as output clients afterward. This is normal-quit recovery evidence only; abnormal termination/crash recovery was not tested.
- **Observed:** Quitting Chrome while its tap was active removed the old Chrome process row/session during reconciliation. Relaunching Chrome created helper PID 68306 / AudioObjectID 137 instead of PID 47149 / object 129, with the same `com.google.Chrome.helper` bundle identifier and no inherited gain. One stale-object listener cleanup warning was reported by discovery during churn.
- **Observed:** The final single-session diagnostic sample was input/output RMS 0.0566 → 0.0566 at unity, with a 23.90 ms graph callback delta. This reproduces unity preservation; the earlier two-process run records measured 0.25 and 0.50 attenuation and zero output.
- **Observed:** Local output inventory included MacBook Pro Speakers and a Teams virtual output. No second physical output was available; switching an active pipeline was not tested.
- **Observed:** `security find-identity -v -p codesigning` reported zero valid signing identities. Developer ID signed/notarized direct distribution could not be experimentally validated. The Mac App Store path remains unknown.
- **Observed:** The system-audio recording permission prompt appeared for the Debug process-tap experiment and was granted. Permission denial, revocation, and recovery through System Settings were not tested.
- **Not Tested:** No acoustic listening test or analog/loopback recording was performed. Therefore clicks, pops, dropouts, echo, duplicates, pitch/timing drift, channel imbalance, resampling artifacts, or audible leakage are not characterized. RMS measurements prove sample scaling within the callback, not listener-perceived output quality.
- **Not Tested:** Five-minute idle/one/two-target resource sampling and energy observations. The available CPU/RSS values are point samples only.
- **Not Tested:** Non-Float32 formats, non-stereo/channel layouts, Bluetooth/external device switching, output-device disappearance, explicit permission denial, abnormal process exit, render failure injection, full app restart recovery, and full acoustic end-to-end latency.

### X-003 — Lifecycle, shutdown, and environment limits

- **Observed:** Chrome target termination while tapped caused reconciliation to stop/remove the session; Chrome relaunch appeared with a new PID and AudioObjectID and unity default gain. The exact pause/resume transition was not separately measured.
- **Observed:** Normal Lamun quit used the explicit stop-all path and the process exited; Chrome and Safari remained listed as audio clients. The HAL tap/aggregate/IOProc destroy calls are in the stop path. Core Audio object inventory before/after and abnormal-exit recovery were not captured.
- **Not Tested:** Physical output change while active (no second physical device), five-minute load comparisons, acoustic loopback/listening, permission denial/recovery, and Developer ID notarization (no identity/certificate available).
- **Not Tested:** Candidate C in formats besides observed Float32 stereo, or with Bluetooth/external hardware. The callback currently assumes Float32 sample buffers and writes zeros for channel/format mismatch; this is not sufficient format support for production.

### X-004 — Local quality and deterministic tests

- **Confirmed:** `AudioGainValue.normalized` clamps finite inputs to `[0, 1]` and maps nonfinite values to unity; parameterized Swift Testing covers range points, over/under-range input, NaN, and infinity.
- **Confirmed:** Project-local Skill visibility was rechecked using `npx skills list --json`. `swift-testing-expert` guidance was read; no suitable dedicated Core Audio Skill was discovered, so Apple documentation and SDK declarations remain the technical authority.
- **Confirmed:** Debug build metadata contains `NSAudioCaptureUsageDescription`; the Debug app has sandbox and audio-input entitlements. Release remains on the bootstrap sandbox entitlement and does not enable capture.
- **Observed:** Initial Debug generated Info.plist omitted the requested usage string. The Debug target now uses `Lamun/Info-Debug.plist` to include it explicitly.
- **Confirmed:** Following review, the POC now reads the tap input and aggregate output `AudioStreamBasicDescription` before starting the callback and rejects formats other than packed little-endian linear PCM Float32. It records resource handles as setup proceeds; startup rollback and normal teardown retain ownership when destruction fails so a later stop can retry. Failure injection remains untested.
- **Confirmed:** The review found and the main agent corrected a stale status sentence that said no architecture outcome existed. Review did not validate acoustic output; that gate remains open.

## Findings

- **Confirmed (reviewed API surface):** No supported public arbitrary per-process gain setter was found in the current `AudioHardwareProcess` documentation/local SDK declarations reviewed. `kAudioDevicePropertyProcessMute` is a mute property and does not provide arbitrary gain. Device volume is not per-process gain.
- **Observed:** Candidate B with a tap-only aggregate consumed by `AVAudioEngine` failed to initialize on this host (`-10875`).
- **Measured:** Candidate C (one process tap and private aggregate containing that tap plus the selected physical output, with gain in a HAL I/O callback) scaled two simultaneously running process streams independently. The per-process RMS ratios matched the applied 0.25 and 0.50 gains within measurement rounding; zero produced zero callback output, and unity preserved the signal.
- **Observed / inferred:** Core Audio reported a third Safari WebKit client active and physical master scalar remained 0.25 while targets changed. This supports non-interference at process/client and master-property level; no calibrated acoustic test establishes that Safari sounded unchanged.
- **Outcome B — Tap/Re-render feasible for continued feasibility:** Current evidence justifies continuing Phase 0 with Candidate C, not starting product implementation. Two process signal paths and normal stop/relaunch behavior were demonstrated, but the full W003 gates are not all validated. In particular, audible independent output and original-output suppression, active device switching, permission denial/recovery, longer resource sampling, abnormal cleanup, and Developer ID signed/notarized distribution remain open. Mac App Store status is unknown. See [ADR-002](../decisions/ADR-002-per-app-gain-architecture.md).

## Measurements

Recorded values and limits are in X-002 and X-003. The 23.90 ms p50/p95/max value is only the delta between aggregate callback host timestamps; do not interpret it as total tap-to-speaker or acoustic latency. Built-in output reports 512-frame nominal buffer, 70-frame device latency, and 74-frame safety offset at 48 kHz. No complete end-to-end latency measurement exists. Do not save audio samples or raw callback payloads.

## Implementation Notes

Planning and this work document preceded substantive source changes. Branch: `feature/per-app-gain-poc`, from `develop`. The service/UI compile only in DEBUG. Gain is session-only and transient. Audio resource ownership is outside SwiftUI; the view starts/stops sessions and reconciles terminated process objects. The IO callback applies Float32 gain and updates lock-free transient measurements; it does not write samples or update UI directly. The output format assumption is validated only for this observed configuration. A first callback implementation inherited main-actor executor isolation and crashed; the block factory was changed to a nonisolated helper and this failure has not recurred during observed sessions. Dynamic MenuBarExtra content also crashed and was moved to a separate diagnostic window. Both are important prototype limitations, not production fixes.

### Local validation (2026-10-01)

- **Passed:** Debug build with ad-hoc signing enabled and required audio capture purpose string/entitlements.
- **Passed:** `LamunTests` unit tests via `xcodebuild -only-testing:LamunTests test`.
- **Passed:** Release configuration build; this caught and prompted correction of the DEBUG-only quit-notification reference.
- **Passed:** Xcode static analysis (`xcodebuild analyze`).
- **Passed:** `scripts/check-format.sh`, `scripts/check-lint.sh`, `scripts/check-docs.py`, `scripts/check-whitespace.py`, `scripts/check-security.py`, and `scripts/check-dependencies.py`.
- **Observed warning:** All local Xcode invocations continue to emit the known CoreDevice/CoreSimulator mismatch. The Lamun unit target still ran successfully. The W001 UI test runner issue remains unresolved and is not marked passed.
- **Not run:** XCTest UI target because its known runner-bootstrap failure is unrelated and persists. The diagnostic window itself was manually operated during the audio POC.
- **Pending:** Independent read-only code review, GitHub CI, and PR integration. No merge has occurred.

## Result

Outcome B is provisionally justified for continued Phase 0 work. The W003 work item is not complete: acoustic output quality, physical device switching, permission denial/recovery, endurance/resource comparisons, abnormal cleanup, and Developer ID signed/notarized validation remain open. Automated checks and independent review/CI/merge are pending.

## Architecture Decision

Provisional Outcome B — tap/re-render is feasible on the tested host using Candidate C's tap-plus-physical-output aggregate and HAL callback. ADR-002 records evidence and limits. This does not unlock production mixer work: Phase 0 distribution, device, format, lifecycle, and acoustic gates remain open. Mac App Store status is Unknown; direct Developer ID signed/notarized distribution is assessed but not experimentally validated.

## Deviations From Plan

The approved W003 scope was expanded to combine capture and gain feasibility. The DEBUG prototype uses a HAL I/O callback with the physical output included in the aggregate after AVAudioEngine failed on a tap-only aggregate. A Debug-only Info.plist was added because the generated plist omitted the permission purpose string. The dynamic process diagnostic was moved from the Menu Bar into a window after a SwiftUI crash. A nonisolated callback factory was added after an actor-executor crash. These changes are limited to the feasibility POC and are documented above.

## Follow-up Work

Before W003 closeout, complete remaining feasible checks and explicitly disposition unavailable hardware/signing tests. After W003 merge, stop for status review. The next work item is not authorized by this document alone; update `docs/PLAN.md`/`PROJECT-STATUS.md` based on the W003 outcome and unresolved feasibility gates. Do not start follow-up work in this cycle.

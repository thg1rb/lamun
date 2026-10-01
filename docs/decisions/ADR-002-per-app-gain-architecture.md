# ADR-002 — Per-Application Gain Feasibility Architecture

## Status

Accepted provisionally for continued feasibility work; not approved as production architecture. Outcome B: process tap, private aggregate, HAL gain processing, and output rendering are feasible on the tested host. The W003 PR and remaining validation gates are still in progress.

## Context

Lamun needs independent application gain. W002 discovered Core Audio process clients but did not capture or control their audio. W003 compared direct process gain, tap/re-render, tap plus aggregate-device topologies, and a virtual-device fallback.

## Requirements

- Use supported public APIs.
- Independently attenuate at least two application process streams.
- Keep untargeted output and macOS master volume unchanged.
- Suppress the original targeted output while rendering the processed stream.
- Keep captured samples transient and clean up temporary Core Audio resources.
- Preserve a credible distribution path; Developer ID signed/notarized validation is a release gate.

## Architectures Investigated

| Candidate | Evidence | Result |
|---|---|---|
| Direct `AudioHardwareProcess` gain | Current Apple API documentation and local SDK declarations expose process metadata/activity; no arbitrary writable per-process gain property was found. The process-mute selector is not gain. | Unsupported in the reviewed public surface. |
| Process tap + AVAudioEngine render, tap-only aggregate | On macOS 27, `AVAudioEngine.start()` failed with `-10875` (`kAudioUnitErr_FailedInitialization`), including with the audio-input entitlement. | Failed on this host/topology. |
| Process tap + private aggregate containing tap and physical output + HAL I/O callback | Two simultaneous process taps produced independently scaled Float32 stereo output. `mutedWhenTapped` suppressed originals per the documented mode. | Feasible for the tested host; selected for further validation. |
| Virtual device/driver | Research-only fallback; no driver was implemented or validated. | Not selected. |

## Decision

Continue Phase 0 using Candidate C as a **provisional feasibility topology**: create one process tap per controlled HAL process, create a private aggregate containing that tap and the selected physical output, and apply normalized gain in the aggregate HAL callback. On stop, destroy the IOProc, aggregate, and tap so native output resumes.

This decision does not establish production support, minimum macOS version, a stable application grouping policy, or distribution approval. Release configuration currently does not enable capture; the W003 experiment used an ad-hoc signed DEBUG build with App Sandbox, `com.apple.security.device.audio-input`, `NSAudioCaptureUsageDescription`, and user-granted System Audio Recording permission.

## Experimental Evidence

- With IINA and Chrome helper audio active, their per-process tap callbacks showed independent measured RMS ratios: IINA at 0.25 was 0.249; Chrome at 0.50 was 0.499. At zero, IINA output RMS was 0.0; unity preserved RMS.
- Safari WebKit GPU remained a third active HAL client while the target gains changed. The system output scalar remained 0.25 before and after.
- The callback exposed one 2-channel buffer per input and output, 4096 bytes each (512 Float32 stereo frames, 10.67 ms at 48 kHz).
- Input-to-output callback host-time delta was 23.90 ms in the observed sample. This is a graph callback timestamp metric, not acoustic end-to-end latency.
- Normal app termination after a Chrome tap session stopped the POC process; Chrome and Safari were still visible to Core Audio afterward. Chrome termination/relaunch replaced PID 47149/object 129 with PID 68306/object 137; reconciliation removed the old session and the new process had no inherited gain.
- One point sample during two sessions was 4.5% CPU / 89,520 KiB RSS; a later single-session process sample ranged 0.0–7.0% over three `top` observations and about 34 MiB reported memory. These are not comparable endurance benchmarks.

## Consequences and Limitations

- Independent signal-level gain is proven for two processes on the built-in 48 kHz, two-channel output. No analog/acoustic listening or loopback test was performed, so audible artifacts, duplicate leakage, and perceived quality remain unvalidated.
- The callback assumes Float32 buffers; other formats/channel topologies require explicit validation and conversion before production.
- No second physical output was available; active device switching is untested. A Teams virtual device was enumerated but not used for an active switch.
- Permission grant was observed; denial/recovery/revocation was not tested. The purpose string is present in the built Debug bundle after correcting generated Info.plist behavior.
- Developer ID credentials were unavailable (`0 valid identities found`); signed/notarized direct distribution is assessed but not experimentally validated. Mac App Store compatibility is unknown pending review and signed testing.
- Helper processes can be separate clients; app grouping remains unresolved. Audio process listener races during object removal were observed and need lifecycle hardening.
- The previous MenuBarExtra live list crashed under dynamic updates; the debug POC now runs in a separate window. A main-actor executor crash in the first callback version was fixed by using a nonisolated callback factory; it has not recurred in observed runs.
- Per-app process taps and private aggregates have resource, permission, latency, and failure-recovery costs. Candidate C remains a Phase 0 gate, not permission to start product mixer work.

## References

- [Apple: Capturing system audio with Core Audio taps](https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps)
- [Apple: `AudioHardwareProcess`](https://developer.apple.com/documentation/coreaudio/audiohardwareprocess)
- [Apple: `CATapMuteBehavior`](https://developer.apple.com/documentation/coreaudio/catapmutebehavior)
- [Apple: audio-input entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.device.audio-input)
- [Apple: notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

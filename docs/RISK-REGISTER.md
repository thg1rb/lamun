# Lamun Risk Register

Likelihoods are preliminary until experiments provide evidence. Update this register as work proceeds; resolved risks retain their disposition.

| ID | Risk | Impact | Likelihood | Validation / mitigation | Owner phase | Status |
|---|---|---|---|---|---|---|
| R01 | Public APIs cannot provide independent application gain | Critical | Reduced on tested host | Two-app process-tap/aggregate/HAL callback POC worked; validate supported devices, formats, lifecycle, distribution before Phase 1 | 0 | Reduced, not resolved |
| R02 | Capture/re-rendering adds audible delay or gaps | High | Unknown | Callback graph delta was 23.90 ms; this is not acoustic end-to-end latency. Perform loopback/listening and device-switch/endurance measurements | 0–1 | Open |
| R03 | Permissions, sandbox, or distribution block chosen topology | High | High | Denied tap setup produced callbacks with zero RMS and no error; after user regrant, fresh app launch captured/scaled an active tone. In-process recovery and a reliable permission-state signal remain unknown; Developer ID signed/notarized validation and separate App Store review remain open | 0 | Open |
| R04 | Device/process lifecycle leaks resources or interrupts audio | High | Medium | Lifecycle matrix and cleanup tests | 0–1 | Open |
| R05 | Trigger Source audio cannot be isolated for Smart Ducking | High | Unknown | Input-pipeline probe and source isolation tests | 0–2 | Open |
| R06 | Ducking pumps or overrides manual volume | High | Medium | Local detector evaluation and state/override tests | 2 | Open |
| R07 | Captured audio escapes through storage, logs, or network | Critical | Low if controls hold | Data-flow review and privacy verification | -1 onward | Open |
| R08 | CI runner/Xcode differs from development machine | Medium | Medium | Pin supported runner/Xcode; run local and CI gates | -1 | Open |
| R09 | Production signing namespace/identity unavailable | Medium | Unknown | Temporary bundle ID in bootstrap; resolve before distribution | Release | Open |
| R10 | Output-I/O state does not track audible playback or pause exactly | High | Confirmed | Use this signal only as process output-stream evidence; evaluate semantics against later control/capture POCs | 0–2 | Open |
| R11 | Swift Core Audio discovery wrapper requires macOS 15 while provisional deployment target is 14.2 | High | Confirmed | Evaluate lower-level public API availability and OS support before setting minimum target; keep prototype gated | 0 | Open |
| R12 | Process list contains system/helper/anonymous clients and browser audio can belong to a helper | Medium | High | Gather more evidence and define user-facing filter/group policy before mixer UI | 0–1 | Open |
| R13 | A muted process tap plus re-render path duplicates, leaks, or loses target audio on failure | Critical | Medium | Two-app signal flow and documented mute mode worked; no acoustic loopback, failure injection, or abnormal-exit recovery yet | 0 | Open |
| R14 | Tap/process/render callbacks introduce unacceptable latency, CPU, energy, or audio instability | High | Unknown | 23.90 ms callback timestamp delta and point CPU/RSS only; acoustic quality, repeated runs, device changes and endurance remain open | 0 | Open |
| R15 | System-audio capture permission, sandbox, Hardened Runtime, or distribution requirements block the chosen topology | Critical | High | Ad-hoc sandbox Debug capture granted; no Developer ID identity available, signing/notarization not validated, App Store unknown | 0 | Open |
| R16 | Current process discovery identity fails to associate target browser/helper process with intended app gain | High | Medium | Chrome helper PID/object changed on relaunch and old session was reaped; grouping helper(s) into a user-facing app remains unresolved | 0–1 | Open |

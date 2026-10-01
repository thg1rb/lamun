# Lamun Risk Register

Likelihoods are preliminary until experiments provide evidence. Update this register as work proceeds; resolved risks retain their disposition.

| ID | Risk | Impact | Likelihood | Validation / mitigation | Owner phase | Status |
|---|---|---|---|---|---|---|
| R01 | Public APIs cannot provide independent application gain | Critical | Unknown | Two-app capture/gain/routing POC; stop Phase 1 if failed | 0 | Open |
| R02 | Capture/re-rendering adds audible delay or gaps | High | Unknown | Measure latency on supported devices and switching | 0–1 | Open |
| R03 | Permissions, sandbox, or distribution block chosen topology | High | Unknown | Signed/sandboxed and denied-state experiments; ADR | 0 | Open |
| R04 | Device/process lifecycle leaks resources or interrupts audio | High | Medium | Lifecycle matrix and cleanup tests | 0–1 | Open |
| R05 | Trigger Source audio cannot be isolated for Smart Ducking | High | Unknown | Input-pipeline probe and source isolation tests | 0–2 | Open |
| R06 | Ducking pumps or overrides manual volume | High | Medium | Local detector evaluation and state/override tests | 2 | Open |
| R07 | Captured audio escapes through storage, logs, or network | Critical | Low if controls hold | Data-flow review and privacy verification | -1 onward | Open |
| R08 | CI runner/Xcode differs from development machine | Medium | Medium | Pin supported runner/Xcode; run local and CI gates | -1 | Open |
| R09 | Production signing namespace/identity unavailable | Medium | Unknown | Temporary bundle ID in bootstrap; resolve before distribution | Release | Open |
| R10 | Output-I/O state does not track audible playback or pause exactly | High | Confirmed | Use this signal only as process output-stream evidence; evaluate semantics against later control/capture POCs | 0–2 | Open |
| R11 | Swift Core Audio discovery wrapper requires macOS 15 while provisional deployment target is 14.2 | High | Confirmed | Evaluate lower-level public API availability and OS support before setting minimum target; keep prototype gated | 0 | Open |
| R12 | Process list contains system/helper/anonymous clients and browser audio can belong to a helper | Medium | High | Gather more evidence and define user-facing filter/group policy before mixer UI | 0–1 | Open |
| R13 | A muted process tap plus re-render path duplicates, leaks, or loses target audio on failure | Critical | Unknown | W003 validates suppression, render failure recovery, and normal/abnormal cleanup before architecture selection | 0 | Open |
| R14 | Tap/process/render callbacks introduce unacceptable latency, CPU, energy, or audio instability | High | Unknown | W003 records latency percentiles and resource observations at one and two targets; fail/condition gate on recurring artifacts | 0 | Open |
| R15 | System-audio capture permission, sandbox, Hardened Runtime, or distribution requirements block the chosen topology | Critical | Unknown | W003 tests actual TCC behavior and assesses Developer ID notarization plus App Store separately | 0 | Open |
| R16 | Current process discovery identity fails to associate target browser/helper process with intended app gain | High | Unknown | W003 records exact process objects and tests helper-based app cases without prematurely finalizing grouping policy | 0 | Open |

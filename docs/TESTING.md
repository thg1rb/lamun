# Lamun Testing Strategy

## Current Baseline

W001 establishes a native build, unit test target, and UI test target. The initial tests validate the bootstrap application configuration and launch, not audio behavior. Local commands and CI details are in [DEVELOPMENT.md](./DEVELOPMENT.md). A passing bootstrap suite does not prove mixer feasibility.

On the W001 development Mac, the unit test passed. The UI target compiled, but its runner exited before bootstrapping while local Xcode reported a CoreDevice/CoreSimulator mismatch. Menu Bar visual inspection also timed out. These are open validation limits, not passed UI results. CI requires the unit test; UI smoke validation remains manual until a healthy interactive runner is verified. W002 manually verified Core Audio metadata enumeration with IINA playback and browser playback through Safari and Chrome Guest; it did not complete a Lamun UI smoke test or validate the in-app listener's long-run cadence/teardown. Chrome's output-I/O property remained true briefly after media was paused, so these checks must not label the property as exact playback state.

W003 adds deterministic normalized-gain tests and a manual gate for captured audio and effective per-app gain. On macOS 27 / built-in 48 kHz output, two simultaneous process streams produced measured independent RMS ratios at 0.25 and 0.50; Safari remained a third active process client and output master scalar stayed 0.25. Chrome termination/relaunch caused process identity replacement and the old session was reconciled; normal app termination stopped the POC. The callback input/output timestamp delta was 23.90 ms, not end-to-end acoustic latency. Point CPU/RSS samples are not endurance measurements. Acoustic listening/loopback, a second physical output switch, permission denial/recovery, five-minute profiling, and Developer ID signed/notarized behavior remain untested. See [W003](./work/003-per-app-gain-feasibility.md). XCTest UI runner limitations from W001 remain unresolved and are unrelated.

## Test Layers

- **Unit:** Deterministic domain policies, persistence identity, ducking timing/state, volume restoration/manual override, profiles, and rules when those features exist. Prefer Swift Testing for new unit tests.
- **Integration:** Process discovery/capture lifecycle, permission states, tap cleanup, persistence, device monitoring, and detector/control wiring where macOS automation is feasible.
- **UI:** Basic app launch and accessible native controls where stable to automate; reserve XCTest for `XCUIApplication` tests.
- **Manual audio:** Multiple simultaneous applications, independent gain/mute, process restart, output changes, Bluetooth reconnect, sleep/wake, permission denial, speech/silence/short pauses, override, and long-running stability.
- **Performance:** Record hardware, OS, CPU, memory, energy indication, audio latency, and UI responsiveness. Phase 0 establishes quantitative baselines and acceptance thresholds for later phases.
- **Privacy:** Verify audio does not reach disk, logs, analytics, crash attachments under app control, or network transfer.

Each work document defines its relevant checks before implementation and records results afterward. Hardware scenarios that CI cannot reliably automate remain explicit manual release gates. Never claim a later phase's acceptance criteria from W001's baseline tests.

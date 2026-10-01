# ADR-001 — Core Audio Process Discovery Prototype

## Status

Accepted for the Phase 0 discovery prototype only. This does not approve a production audio-control architecture or establish Lamun's minimum macOS version.

## Context

W002 needs to identify audio-system client processes and observe their output-I/O state using public APIs. The project currently targets macOS 14.2 provisionally. On the development machine, the Core Audio Swift wrapper used by the prototype is annotated for macOS 15 and later. Manual experiments observed IINA, Safari, and Chrome process records, including browser helper processes and missing app metadata.

## Decision

Continue using `AudioHardwareSystem.shared.processes`, the public `AudioHardwareProcess` metadata/output-state properties, and property listeners for the Phase 0 discovery prototype. Map available runtime PIDs to `NSRunningApplication` metadata and publish copied value snapshots. Treat PID and AudioObjectID as transient process-instance identifiers, and use an available bundle identifier as the application identity candidate. Label `isRunningOutput` only as active output-I/O state; do not treat it as proof of audible content or exact pause/play state.

Keep the implementation DEBUG-only and gated to macOS 15. Do not raise the app's deployment target or select a C API fallback before the minimum-OS investigation. Do not use process discovery as evidence that process capture, independent gain, routing, sandbox permission, or App Store distribution is feasible.

## Alternatives Considered

- **`NSWorkspace.runningApplications` alone:** exposes running apps and metadata but does not establish which clients have Core Audio output I/O.
- **Aggressive process polling:** would add avoidable work without replacing a system signal; revisit only if listener experiments show a specific gap.
- **Private process inspection APIs:** rejected; the project requires public supported APIs.

## Consequences

- The prototype provides an event-oriented metadata path for W002, subject to listener validation.
- The current wrapper cannot run on the provisional macOS 14.2 minimum; lower-level public API compatibility remains an open question.
- The process list contains helpers, services, menu-bar processes, and anonymous clients, so product filtering/grouping needs further evidence.
- Browser audio may map to a helper bundle ID rather than the browser's top-level app identity.
- Output-I/O state can remain active after browser media is paused; it is not a playback classifier.

## Evidence and Follow-up

See [W002 — Audio Process Discovery](../work/002-audio-process-discovery.md) for the SDK evidence and reproducible local observations. Validate listener lifecycle and performance, signed sandbox behavior, the macOS 14 API path, and the eventual app-facing process identity policy before relying on this in production.

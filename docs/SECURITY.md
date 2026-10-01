# Lamun Security and Privacy

## Current State

W002's DEBUG-only diagnostic reads Core Audio process metadata and output-I/O state. It does not create a tap, read audio samples, request microphone access, persist process history, or send data over the network. No permission prompt appeared during the metadata-only local probe. W002 observed that an ad-hoc signed Debug build embedded the App Sandbox entitlement and enumerated process metadata without a prompt. This is limited local Debug evidence; it does not validate capture permission, Hardened Runtime, Developer ID signing/notarization, App Store eligibility, or production distribution. See [W002 findings](./work/002-audio-process-discovery.md).

W003 is evaluating a DEBUG-only process-tap/gain/render proof of concept. Until results are recorded in [the W003 work document](./work/003-per-app-gain-feasibility.md), capture permissions, audio-buffer handling, and distribution support remain unverified. The POC must keep audio transient in memory and must not write, upload, transcribe, log, or analyze captured content beyond gain processing and ephemeral signal measurement.

## Privacy Requirements

Future audio used for control or Smart Ducking must remain transient and local: no conversation recording, saved samples, transcription, cloud recognition, upload, or analytics. Release buffers after processing. Never log raw audio, transcripts, meeting content, or buffers. Log technical lifecycle/errors only, with `Logger`/OSLog where appropriate. Verify the public local-processing promise before using it.

## Security Baseline

- Prefer documented public APIs and least privilege. Phase 0 must test actual system-audio permission prompts, entitlements, App Sandbox, and denied/revoked behavior.
- Treat process names, bundle identifiers, and PIDs as local diagnostic metadata. Keep them in memory unless a later documented feature requires persistence; avoid logging full process inventories.
- Keep runtime and build dependencies minimal; review source, maintainer, license, maintenance, permissions, and supply-chain risk before adding one.
- Never commit tokens, passwords, private keys, certificates, provisioning profiles, or notarization credentials. Use protected release secrets only when needed.
- CI uses read-only repository permissions for untrusted PR code, pinned actions, and no signing secrets. Required checks block merge.
- Review security-sensitive PRs explicitly, including captured-audio lifetime, logs, persistence, and permission UX.

## Distribution

The production bundle identifier, Mac App Store suitability, direct distribution, signing, notarization, and hardened-runtime/sandbox configuration remain undecided. Phase 0 records evidence and ADRs; release validation inspects final entitlements and signatures.

## Findings

Record a finding's severity, affected component, threat, remediation, verification, and residual risk in a work document or this file. Update [RISK-REGISTER.md](./RISK-REGISTER.md) for ongoing risks. No product security finding has been confirmed in W001.

The W002 sandbox-enabled Debug metadata observation and W003 capture/distribution investigation are recorded in their work documents; no capture result is yet established.

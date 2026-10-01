# Lamun Security and Privacy

## Current State

Phase -1 has no audio capture, microphone access, network service, analytics, or production signing credentials. The bootstrap app is only a Menu Bar shell. No audio permission or entitlement behavior has been proven. See [PROJECT-STATUS.md](./PROJECT-STATUS.md).

## Privacy Requirements

Future audio used for control or Smart Ducking must remain transient and local: no conversation recording, saved samples, transcription, cloud recognition, upload, or analytics. Release buffers after processing. Never log raw audio, transcripts, meeting content, or buffers. Log technical lifecycle/errors only, with `Logger`/OSLog where appropriate. Verify the public local-processing promise before using it.

## Security Baseline

- Prefer documented public APIs and least privilege. Phase 0 must test actual system-audio permission prompts, entitlements, App Sandbox, and denied/revoked behavior.
- Keep runtime and build dependencies minimal; review source, maintainer, license, maintenance, permissions, and supply-chain risk before adding one.
- Never commit tokens, passwords, private keys, certificates, provisioning profiles, or notarization credentials. Use protected release secrets only when needed.
- CI uses read-only repository permissions for untrusted PR code, pinned actions, and no signing secrets. Required checks block merge.
- Review security-sensitive PRs explicitly, including captured-audio lifetime, logs, persistence, and permission UX.

## Distribution

The production bundle identifier, Mac App Store suitability, direct distribution, signing, notarization, and hardened-runtime/sandbox configuration remain undecided. Phase 0 records evidence and ADRs; release validation inspects final entitlements and signatures.

## Findings

Record a finding's severity, affected component, threat, remediation, verification, and residual risk in a work document or this file. Update [RISK-REGISTER.md](./RISK-REGISTER.md) for ongoing risks. No product security finding has been confirmed in W001.

# Lamun Project Rules

Read this document, [PROJECT-STATUS.md](./PROJECT-STATUS.md), and relevant work/decision documents before meaningful work. [PROMPT.md](./PROMPT.md) is the product and engineering specification; [PLAN.md](./PLAN.md) is the execution roadmap.

## Identity and Principles

Lamun is a native Swift/SwiftUI macOS Menu Bar audio-focus utility. Keep it calm, predictable, accessible, private, and lightweight. Prefer supported public Apple APIs. Phase 0 must prove independent effective application gain before production mixer work. Automation yields to direct user action.

## Documentation and New Sessions

Markdown under `docs/` is persistent project memory. Begin a fresh session by reading `README.md`, this file, `PROJECT-STATUS.md`, `ARCHITECTURE.md`, `DEVELOPMENT.md`, `AGENT-SKILLS.md`, `SECURITY.md`, `TESTING.md`, `RISK-REGISTER.md`, relevant ADRs and work docs, then Git status/history and implementation. Never treat chat history as authority. End substantial sessions by recording completed work, branch/state, decisions, risks, and the next action.

Before meaningful implementation, create/update a numbered `docs/work/` document with scope, non-goals, proposed behavior, approach, acceptance criteria, tests, and privacy/security impact. Update it during work and finalize actual results, deviations, limitations, and follow-ups before merge. Keep status, architecture, ADRs, security, and testing docs consistent with reality. Significant decisions get ADRs; supersede rather than erase old decisions.

## Skills

Inspect built-in Skills and use `find-skills` or equivalent for discovery. Evaluate source, maintenance, compatibility, permissions, and overlap before project-local installation. Verify installed Skills and use relevant ones. See [AGENT-SKILLS.md](./AGENT-SKILLS.md).

## Git and Pull Requests

`main` is release state; `develop` is buildable integration state. Normal work starts from latest `develop` on a focused `feature/*`, `fix/*`, `docs/*`, or similar branch. No normal direct work or pushes on `main` or `develop`. Meaningful merges require a PR to `develop`, with work-doc link, change rationale, tests, risks, security/privacy impact, and updated docs. Use squash merge consistently for focused PRs unless a documented exception applies. A one-time root commit was necessary to establish this previously unborn repository; it is not a precedent for direct feature work.

Before merging significant feature, fix, architecture, or security PRs—and every release PR—use a dedicated **review-only Sub-agent**. It reports located, prioritized findings and never edits files, applies fixes, commits, pushes, or merges. The main Agent evaluates/fixes findings, reruns local checks and CI, and requests re-review for substantial changes.

## Quality, Security, and Privacy

CI is required from Phase -1 and must block merge on required check failure. Run documented format, lint, build, test, static, documentation, and security/dependency checks. Do not suppress meaningful warnings or disable failing checks to obtain a green result. Test deterministic logic with unit tests, feasible system boundaries with integration tests, and hardware audio behavior with a documented manual matrix.

Use least privilege and minimal dependencies. Never commit secrets, signing credentials, or private keys. Captured audio must be transient, local, and absent from disk, logs, analytics, and uploads. Do not publicly promise validated privacy or distribution behavior before verification. Phase 0 determines audio permissions, entitlements, sandbox mode, minimum macOS version, and distribution implications.

## Definition of Ready

- Requirement, current behavior, dependencies, and relevant docs/ADRs understood.
- Work doc exists with goals, non-goals, approach, acceptance criteria, test plan, and security/privacy impact.
- Relevant Skills identified; architecture/phase gates satisfied; focused branch created from latest `develop`.

## Definition of Done

- Intended behavior and meaningful failures handled; build and relevant tests pass.
- Format, lint, static, security, privacy, and CI gates pass; applicable manual/performance evidence recorded.
- Review-only Sub-agent findings resolved or justified; main Agent reruns checks after fixes.
- Work doc, `PROJECT-STATUS.md`, and relevant standing docs/ADRs reflect actual behavior, limits, and follow-ups.
- Focused PR merged to `develop` only after these conditions hold.

## Release

Validate integrated `develop`, open a release PR `develop` → `main`, run full quality and security/distribution gates, obtain review-only Sub-agent review, then merge and tag the validated `main` commit. No normal feature branch merges directly to `main`. See [CONTRIBUTING.md](./CONTRIBUTING.md) and [DEVELOPMENT.md](./DEVELOPMENT.md).

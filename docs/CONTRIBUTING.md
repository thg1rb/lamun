# Contributing to Lamun

Read [PROJECT-RULES.md](./PROJECT-RULES.md), [PROJECT-STATUS.md](./PROJECT-STATUS.md), and the relevant work document before editing. The [specification](./PROMPT.md) and [plan](./PLAN.md) define intent and execution order.

For meaningful work, draft `docs/work/XXX-*.md` first with scope, acceptance criteria, testing, and security/privacy impact. Branch from current `develop` with a focused name. Implement and validate locally using [DEVELOPMENT.md](./DEVELOPMENT.md), then update the work document and status with actual results.

Open a PR into `develop`. Include the work-document path, what and why, test commands and results, risks, security/privacy impact, known limitations, and screenshots for UI changes. Required CI checks must pass. A dedicated review-only Sub-agent reports findings; the main Agent applies any fixes and reruns checks before merge. Use squash merge for focused PRs. Do not directly modify `main` or `develop` for normal development.

Release through integration validation and a `develop` → `main` PR with full gates and review. Tag `main` only after validation. Keep project documentation current enough for a fresh session to resume.

# Lamun Agent Skills

## Discovery and Selection

W001 inspected built-in `find-skills`, `skill-installer`, and `skill-creator` capabilities. `find-skills` was used to search SwiftUI/macOS, Core Audio, Swift testing, architecture/code quality, and GitHub Actions/security categories. Candidates were evaluated for relevance, maintainer, adoption, and overlap. The project-local Skills below were copied into `.agents/skills/` using the Skills CLI, and `skills-lock.json` records source and computed hash. Their `SKILL.md` files were read and `npx skills list --json` confirmed visibility to Codex.

| Skill | Source | Intended use |
|---|---|---|
| `swiftui-expert-skill` | `avdlee/swiftui-agent-skill` | Native SwiftUI scene/UI implementation and review, starting in W001 and later UI work. |
| `swift-testing-expert` | `avdlee/swift-testing-agent-skill` | Swift Testing design and review. XCTest remains appropriate for UI automation. |
| `github-actions-hardening` | `github/awesome-copilot` | Authoring and reviewing CI triggers, token scopes, action pinning, and untrusted input. |

No Core Audio-specific Skill passed the relevance/quality screen in W001. Do not treat generic search results as proof of expertise; Phase 0 must use Apple documentation and experiments. Revisit discovery when a concrete gap appears. Avoid redundant project Skills.

W003 re-verified project-local Skill visibility with `npx skills list --json` and used `find-skills` searches for “Core Audio macOS” and “Swift macOS audio.” Results included a general Swift/macOS Skill with 106 installs, but no dedicated Core Audio/process-tap Skill with sufficient demonstrated fit was found; no new Skill was installed. W003 uses `swift-testing-expert` for parameterized deterministic math/state tests and Apple documentation plus current SDK headers as the authority for Core Audio.

The copied Skills' upstream MIT licenses and copyright notices are retained in [`docs/licenses/`](./licenses/README.md). Copied Skill content is kept byte-for-byte as installed so the lockfile hashes remain valid; first-party whitespace checks exclude that vendor tree.

To inspect project Skills, run `npx skills list --json` and read the relevant `.agents/skills/<name>/SKILL.md`. Skills are copied into the repository so a fresh session can inspect them; do not execute bundled scripts without understanding them. Use `npx skills experimental_install` only after reviewing the lock and install scope. Verify updates before committing them.

#!/usr/bin/env python3
"""Check required project memory and local Markdown links."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
REQUIRED = [
    "README.md",
    "docs/PROMPT.md",
    "docs/PLAN.md",
    "docs/PROJECT-RULES.md",
    "docs/PROJECT-STATUS.md",
    "docs/ARCHITECTURE.md",
    "docs/DEVELOPMENT.md",
    "docs/CONTRIBUTING.md",
    "docs/AGENT-SKILLS.md",
    "docs/SECURITY.md",
    "docs/TESTING.md",
    "docs/RISK-REGISTER.md",
    "docs/work/001-project-bootstrap.md",
    "docs/decisions/README.md",
    "docs/licenses/README.md",
    "docs/licenses/swiftui-expert-skill-LICENSE",
    "docs/licenses/swift-testing-expert-LICENSE",
    "docs/licenses/github-actions-hardening-LICENSE",
]
LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
errors = []

for relative in REQUIRED:
    if not (ROOT / relative).is_file():
        errors.append(f"missing required file: {relative}")

for source in [ROOT / "README.md", *(ROOT / "docs").rglob("*.md")]:
    if not source.is_file() or source.name == "PROMPT.md":
        continue  # PROMPT.md contains illustrative links to future documents.
    for target in LINK.findall(source.read_text(encoding="utf-8")):
        if target.startswith(("https://", "http://", "mailto:", "#")):
            continue
        path = target.split("#", 1)[0]
        if path and not (source.parent / path).exists():
            errors.append(f"{source.relative_to(ROOT)}: missing link target {target}")

if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
print("Required documentation and local links: OK")

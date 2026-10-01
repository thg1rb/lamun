#!/usr/bin/env python3
"""Check first-party tracked text for trailing whitespace.

Copied Skills remain byte-for-byte as installed, matching skills-lock.json.
Their upstream whitespace is intentionally outside this repository's style gate.
"""

from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
VENDORED_PREFIX = ".agents/skills/"
TEXT_SUFFIXES = {".md", ".py", ".sh", ".swift", ".yml", ".yaml", ".json", ".pbxproj"}

tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).split(b"\0")
errors = []
for raw_path in tracked:
    if not raw_path:
        continue
    relative = raw_path.decode("utf-8")
    if relative.startswith(VENDORED_PREFIX):
        continue
    path = ROOT / relative
    if path.suffix not in TEXT_SUFFIXES or not path.is_file():
        continue
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if line.endswith((" ", "\t")):
            errors.append(f"{relative}:{number}: trailing whitespace")

if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
print("First-party trailing whitespace: OK")

#!/usr/bin/env python3
"""Check W001 entitlements and obvious embedded secrets."""

from pathlib import Path
import plistlib
import re
import sys

root = Path(__file__).resolve().parent.parent
entitlements = plistlib.loads((root / "Lamun/Lamun.entitlements").read_bytes())
errors = []
if entitlements != {"com.apple.security.app-sandbox": True}:
    errors.append("W001 app entitlements must contain only App Sandbox")

patterns = {
    "private key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "AWS access key": re.compile(r"AKIA[0-9A-Z]{16}"),
    "GitHub token": re.compile(r"(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}"),
}
for directory in ("Lamun", "LamunTests", "LamunUITests", ".github"):
    area = root / directory
    if not area.exists():
        continue
    for source in area.rglob("*"):
        if not source.is_file():
            continue
        content = source.read_text(encoding="utf-8", errors="ignore")
        for label, pattern in patterns.items():
            if pattern.search(content):
                errors.append(f"possible {label} in {source.relative_to(root)}")

if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
print("W001 entitlements and embedded-secret patterns: OK")

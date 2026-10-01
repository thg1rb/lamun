#!/usr/bin/env python3
"""Enforce the W001 zero-runtime-dependency baseline."""

from pathlib import Path
import sys

root = Path(__file__).resolve().parent.parent
project = (root / "Lamun.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
unexpected = [
    name
    for name in ("Package.swift", "Package.resolved", "Podfile", "Cartfile")
    if (root / name).exists()
]
if "XCRemoteSwiftPackageReference" in project or "XCSwiftPackageProductDependency" in project:
    unexpected.append("Xcode Swift package reference")

if unexpected:
    print("Review new dependencies and update this baseline: " + ", ".join(unexpected), file=sys.stderr)
    sys.exit(1)
print("Application runtime dependencies: Apple frameworks only")

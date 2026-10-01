#!/usr/bin/env bash
set -euo pipefail

xcrun swift-format lint --strict --recursive Lamun LamunTests LamunUITests

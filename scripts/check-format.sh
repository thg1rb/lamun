#!/usr/bin/env bash
set -euo pipefail

status=0
while IFS= read -r -d '' source_file; do
  if ! diff -u "$source_file" <(xcrun swift-format format "$source_file"); then
    status=1
  fi
done < <(rg --files -0 -g '*.swift' Lamun LamunTests LamunUITests)
exit "$status"

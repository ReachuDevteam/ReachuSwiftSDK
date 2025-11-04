#!/usr/bin/env bash
set -euo pipefail

echo "[CI] Swift toolchain"
swift --version

echo "[CI] Resolving dependencies"
swift package resolve

echo "[CI] Building (debug)"
swift build

echo "[CI] Building (release)"
swift build --configuration release

echo "[CI] Running tests"
swift test

echo "[CI] Scanning for stray demo references"
if command -v rg >/dev/null 2>&1; then
  rg -n "\\bDemo/|ReachuDemo|tv2demo|Viaplay|Vg\\b" -S --hidden --glob '!**/.git/**' || true
else
  echo "[CI] ripgrep not installed; skipping scan"
fi

echo "[CI] Done"


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

echo "[CI] Done"

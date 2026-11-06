#!/usr/bin/env bash
# Generates Pulse.xcodeproj from project.yml (needs `brew install xcodegen`).
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null || { echo "Install XcodeGen first: brew install xcodegen" >&2; exit 1; }
xcodegen generate --spec project.yml
echo "Open Pulse.xcodeproj, pick your team under Signing, and run."

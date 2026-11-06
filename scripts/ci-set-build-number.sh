#!/usr/bin/env bash
# Usage: ci-set-build-number.sh <build-number> [marketing-version]
# Rewrites project.yml so XcodeGen produces an Xcode project with this build number.
set -euo pipefail
BUILD="${1:?build number required}"
MARKETING="${2:-}"
cd "$(dirname "$0")/.."
sed -i.bak -E "s/CURRENT_PROJECT_VERSION: \"[^\"]*\"/CURRENT_PROJECT_VERSION: \"${BUILD}\"/" project.yml
if [ -n "$MARKETING" ]; then
  sed -i.bak -E "s/MARKETING_VERSION: \"[^\"]*\"/MARKETING_VERSION: \"${MARKETING}\"/" project.yml
fi
rm -f project.yml.bak
grep -E "CURRENT_PROJECT_VERSION|MARKETING_VERSION" project.yml

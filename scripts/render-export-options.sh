#!/usr/bin/env bash
# Usage: render-export-options.sh <team-id> <bundle-id> <profile-name> > build/exportOptions.plist
set -euo pipefail
cd "$(dirname "$0")/.."
sed -e "s/__TEAM_ID__/${1:?team id}/" -e "s/__BUNDLE_ID__/${2:?bundle id}/" -e "s/__PROFILE_NAME__/${3:?profile name}/" exportOptions.plist

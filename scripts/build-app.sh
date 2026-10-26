#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_dir="$project_dir/dist/K3BatteryBar.app"
iconset_dir="$project_dir/.build/AppIcon.iconset"
app_version="${APP_VERSION:-0.1.0}"
app_build_number="${APP_BUILD_NUMBER:-1}"

cd "$project_dir"
swift build -c release --product K3BatteryBar
bin_dir="$(swift build -c release --show-bin-path)"

swift "$project_dir/scripts/generate-app-icon.swift" "$iconset_dir"
iconutil -c icns "$iconset_dir" -o "$project_dir/.build/AppIcon.icns"

rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$bin_dir/K3BatteryBar" "$app_dir/Contents/MacOS/K3BatteryBar"
cp "$project_dir/App/Info.plist" "$app_dir/Contents/Info.plist"
cp "$project_dir/.build/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
plutil -replace CFBundleShortVersionString -string "$app_version" \
    "$app_dir/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$app_build_number" \
    "$app_dir/Contents/Info.plist"

sign_identity="${CODE_SIGN_IDENTITY:-}"
if [[ -z "$sign_identity" ]]; then
    sign_identity="$(
        security find-identity -v -p codesigning 2>/dev/null |
            sed -n 's/^[[:space:]]*[0-9]*) [0-9A-F]* "\(.*\)"/\1/p' |
            grep -E 'Developer ID Application|Apple Development' |
            head -n 1 ||
            true
    )"
fi

if [[ -n "$sign_identity" ]]; then
    echo "Signing with: $sign_identity"
    if [[ "$sign_identity" == Developer\ ID\ Application* ]]; then
        codesign --force --options runtime --timestamp \
            --sign "$sign_identity" "$app_dir"
    else
        codesign --force --options runtime \
            --sign "$sign_identity" "$app_dir"
    fi
else
    echo "No Apple signing identity found; using ad-hoc signing."
    codesign --force --sign - "$app_dir"
fi

echo "Built: $app_dir"

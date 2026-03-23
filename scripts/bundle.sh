#!/bin/bash
# Build and bundle HookHeroBar as a proper macOS .app
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release 2>&1

APP="HookHeroBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/release/HookHeroBar "$APP/Contents/MacOS/HookHeroBar"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>HookHeroBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.hook-hero.bar</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>HookHeroBar</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST

echo "✓ Built HookHeroBar.app ($(du -sh "$APP" | cut -f1))"

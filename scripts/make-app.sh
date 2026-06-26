#!/bin/bash
set -euo pipefail

# Wraps the SwiftPM-built binary into a proper .app bundle so macOS treats it
# as an LSUIElement agent app (no Dock icon, menu-bar status item only).

cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
BIN=".build/${CONFIG}/MyMemo"
APP="MyMemo.app"

if [ ! -f "$BIN" ]; then
    echo "error: $BIN not found. Run 'swift build' first (config: $CONFIG)." >&2
    exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/MyMemo"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.mymemo.app</string>
    <key>CFBundleName</key>
    <string>MyMemo</string>
    <key>CFBundleDisplayName</key>
    <string>MyMemo</string>
    <key>CFBundleExecutable</key>
    <string>MyMemo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Created $APP (config: $CONFIG)"

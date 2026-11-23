#!/bin/zsh
# Builds DisableBar.app into ./build (and a zip for releases).
# Usage: scripts/build-app.sh [--install]   (--install copies it to /Applications)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/DisableBar.app"
VERSION="${VERSION:-1.0.0}"

cd "$ROOT"
echo "▸ Compiling (release)…"
swift build -c release --arch arm64 --arch x86_64 >/dev/null
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/DisableBar"

echo "▸ Assembling bundle…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/DisableBar"

echo "▸ Rendering icon…"
ICONSET="$BUILD/AppIcon.iconset"
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
swift "$ROOT/scripts/make-icon.swift" "$BUILD/icon_1024.png" >/dev/null
for s in 16 32 128 256 512; do
  sips -z $s $s "$BUILD/icon_1024.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$BUILD/icon_1024.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>DisableBar</string>
  <key>CFBundleDisplayName</key><string>DisableBar</string>
  <key>CFBundleIdentifier</key><string>io.github.ri4dh.DisableBar</string>
  <key>CFBundleExecutable</key><string>DisableBar</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSAppleEventsUsageDescription</key><string>DisableBar uses this to restart the Touch Bar when you ask it to.</string>
  <key>NSHumanReadableCopyright</key><string>MIT License</string>
</dict>
</plist>
PLIST

echo "▸ Signing (ad-hoc)…"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1

echo "▸ Zipping…"
rm -f "$BUILD/DisableBar.zip"
ditto -c -k --keepParent "$APP" "$BUILD/DisableBar.zip"

if [[ "${1:-}" == "--install" ]]; then
  echo "▸ Installing to /Applications…"
  pkill -x DisableBar 2>/dev/null || true
  rm -rf /Applications/DisableBar.app
  cp -R "$APP" /Applications/
fi

echo "✔ Built $APP"

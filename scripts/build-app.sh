#!/bin/zsh
# Builds DisableBar.app into ./build.
#
# Usage: VERSION=1.2.0 scripts/build-app.sh [--release] [--install]
#   (default)   universal build, signed with Developer ID if one is in the
#               keychain (ad-hoc otherwise), plus build/DisableBar.zip
#   --release   also notarizes + staples the app, builds a notarized
#               DisableBar-<version>.dmg and a signed Sparkle appcast.xml
#   --install   copies the app to /Applications
#
# Release prerequisites (one-time):
#   xcrun notarytool store-credentials DisableBar --apple-id … --team-id …
#   Sparkle EdDSA key in the login keychain (account "disablebar")
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/DisableBar.app"
VERSION="${VERSION:-1.0.0}"
NOTARY_PROFILE="${NOTARY_PROFILE:-DisableBar}"
SPARKLE_VERSION="2.10.1"
SPARKLE_ACCOUNT="disablebar"
SPARKLE_PUBLIC_KEY="3DU1A1JFs4KCiXUa8px6ibZ5bu1L1eC7f0G5U2brQyw="
FEED_URL="https://github.com/Ri4dH/disablebar/releases/latest/download/appcast.xml"
DOWNLOAD_PREFIX="https://github.com/Ri4dH/disablebar/releases/download/v${VERSION}/"

RELEASE=0; INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --release) RELEASE=1 ;;
    --install) INSTALL=1 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/ {print $2; exit}')}"
if [[ -z "$IDENTITY" && $RELEASE == 1 ]]; then
  echo "✖ --release needs a Developer ID Application certificate" >&2; exit 1
fi

cd "$ROOT"
echo "▸ Compiling (release, universal)…"
swift build -c release --arch arm64 --arch x86_64 >/dev/null
PRODUCTS="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"

echo "▸ Assembling bundle…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Fonts" "$APP/Contents/Frameworks"
cp "$PRODUCTS/DisableBar" "$APP/Contents/MacOS/DisableBar"
ditto "$PRODUCTS/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
cp "$ROOT"/assets/fonts/*.woff2 "$ROOT"/assets/fonts/*.txt "$APP/Contents/Resources/Fonts/"

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
  <key>SUFeedURL</key><string>${FEED_URL}</string>
  <key>SUPublicEDKey</key><string>${SPARKLE_PUBLIC_KEY}</string>
  <key>SUEnableAutomaticChecks</key><true/>
</dict>
</plist>
PLIST

if [[ -n "$IDENTITY" ]]; then
  echo "▸ Signing with $IDENTITY (hardened runtime)…"
  sign() { codesign --force --timestamp --options runtime --sign "$IDENTITY" "$@"; }
  SPK="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
  # Inside-out, as Sparkle's docs describe.
  sign "$SPK/XPCServices/Installer.xpc"
  sign --preserve-metadata=entitlements "$SPK/XPCServices/Downloader.xpc"
  sign "$SPK/Autoupdate"
  sign "$SPK/Updater.app"
  sign "$APP/Contents/Frameworks/Sparkle.framework"
  sign "$APP"
  codesign --verify --strict --deep "$APP"
else
  echo "▸ No Developer ID found, signing ad-hoc…"
  codesign --force --deep --sign - "$APP" >/dev/null
fi

notarize() {
  echo "▸ Notarizing $(basename "$1")… (usually 1–5 min)"
  xcrun notarytool submit "$1" --keychain-profile "$NOTARY_PROFILE" --wait | tail -3
}

if [[ $RELEASE == 1 ]]; then
  rm -f "$BUILD/notarize.zip"
  ditto -c -k --keepParent "$APP" "$BUILD/notarize.zip"
  notarize "$BUILD/notarize.zip"
  xcrun stapler staple "$APP" >/dev/null
  rm -f "$BUILD/notarize.zip"

  echo "▸ Building DMG…"
  DMG="$BUILD/DisableBar-${VERSION}.dmg"
  STAGE="$BUILD/dmg"
  rm -rf "$STAGE" "$DMG" && mkdir -p "$STAGE"
  ditto "$APP" "$STAGE/DisableBar.app"
  ln -s /Applications "$STAGE/Applications"
  hdiutil create -volname "DisableBar" -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null
  rm -rf "$STAGE"
  codesign --force --timestamp --sign "$IDENTITY" "$DMG"
  notarize "$DMG"
  xcrun stapler staple "$DMG" >/dev/null
fi

echo "▸ Zipping…"
rm -f "$BUILD/DisableBar.zip"
ditto -c -k --keepParent "$APP" "$BUILD/DisableBar.zip"

if [[ $RELEASE == 1 ]]; then
  echo "▸ Writing Sparkle appcast…"
  TOOLS="$BUILD/sparkle-tools"
  if [[ ! -x "$TOOLS/bin/generate_appcast" ]]; then
    rm -rf "$TOOLS" && mkdir -p "$TOOLS"
    curl -sSL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" \
      | tar -xJ -C "$TOOLS" bin
  fi
  FEED="$BUILD/feed"
  rm -rf "$FEED" && mkdir -p "$FEED"
  cp "$BUILD/DisableBar.zip" "$FEED/DisableBar-${VERSION}.zip"
  "$TOOLS/bin/generate_appcast" --account "$SPARKLE_ACCOUNT" \
    --download-url-prefix "$DOWNLOAD_PREFIX" -o "$BUILD/appcast.xml" "$FEED"
  mv "$FEED/DisableBar-${VERSION}.zip" "$BUILD/"
  rm -rf "$FEED"

  echo "▸ Gatekeeper check…"
  spctl -a -vv -t exec "$APP" 2>&1 | sed 's/^/    /'
  spctl -a -vv -t open --context context:primary-signature "$BUILD/DisableBar-${VERSION}.dmg" 2>&1 | sed 's/^/    /'
fi

if [[ $INSTALL == 1 ]]; then
  echo "▸ Installing to /Applications…"
  pkill -x DisableBar 2>/dev/null || true
  sleep 1
  rm -rf /Applications/DisableBar.app
  ditto "$APP" /Applications/DisableBar.app
fi

echo "✔ Built $APP"

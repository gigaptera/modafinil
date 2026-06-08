#!/bin/bash
#
# Build script for Modafinil (keep-awake menu bar app).
# Run from the modafinil/ directory.
#
# Usage:
#   ./build.sh                  # Personal / local unsigned build
#   PROD=1 ./build.sh           # Production signed + DMG (auto-detects cert)
#   ./build.sh --production --identity "Developer ID Application: ..."
#
# After a production build, follow the printed notarization commands.

set -e

MODE="personal"
SIGNING_IDENTITY=""
VERSION="1.2.1"
APP_NAME="Modafinil"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

while [[ $# -gt 0 ]]; do
  case $1 in
    --production|-p) MODE="production"; shift ;;
    --identity|-i)   SIGNING_IDENTITY="$2"; shift 2 ;;
    --version)       VERSION="$2"; DMG_NAME="${APP_NAME}-${VERSION}.dmg"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -n "${PROD:-}" ]]; then
  MODE="production"
fi

if [[ "$MODE" == "production" ]]; then
  echo "Building Release PRODUCTION (signed + DMG)..."

  if [[ -z "$SIGNING_IDENTITY" ]]; then
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
      | grep "Developer ID Application" | head -1 \
      | sed -E 's/.*"([^"]+)".*/\1/' || true)
    if [[ -z "$SIGNING_IDENTITY" ]]; then
      echo "No 'Developer ID Application' certificate found."
      echo "Provide one with --identity or set SIGNING_IDENTITY env var."
      exit 1
    fi
    echo "Auto-selected: $SIGNING_IDENTITY"
  fi

  DEVELOPMENT_TEAM=$(echo "$SIGNING_IDENTITY" | sed -E 's/.*\(([A-Z0-9]+)\)$/\1/')

  rm -rf ./DerivedData/Build/Products/Release/${APP_NAME}.app 2>/dev/null || true

  xcodebuild \
    -project ${APP_NAME}.xcodeproj \
    -scheme ${APP_NAME} \
    -configuration Release \
    -derivedDataPath ./DerivedData \
    -quiet \
    clean build \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGNING_ALLOWED=YES

  BUILT_APP=$(find ./DerivedData -path "*/Release/${APP_NAME}.app" -type d | head -1)
  if [[ -z "$BUILT_APP" ]]; then
    echo "Failed to find built app"; exit 1
  fi

  mkdir -p Build
  rm -rf "Build/${APP_NAME}.app" "Build/${DMG_NAME}" 2>/dev/null || true
  cp -R "$BUILT_APP" "Build/${APP_NAME}.app"

  # Generate DMG background
  echo "Generating DMG background..."
  swift dmg-assets/make-bg.swift

  # Combine @1x and @2x into a retina-ready TIFF
  tiffutil -cathidpicheck dmg-assets/dmg-bg.png dmg-assets/dmg-bg@2x.png \
    -out dmg-assets/dmg-bg.tiff

  echo "Creating DMG: ${DMG_NAME}..."
  STAGE=$(mktemp -d)
  cp -R "Build/${APP_NAME}.app" "$STAGE/${APP_NAME}.app"
  create-dmg \
    --volname "${APP_NAME}" \
    --background "dmg-assets/dmg-bg.tiff" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 120 \
    --icon "${APP_NAME}.app" 150 180 \
    --app-drop-link 450 180 \
    --no-internet-enable \
    "Build/${DMG_NAME}" "$STAGE" > /dev/null
  rm -rf "$STAGE"

  codesign --force --sign "$SIGNING_IDENTITY" --timestamp "Build/${DMG_NAME}"

  echo ""
  echo "PRODUCTION BUILD COMPLETE"
  echo "  Signed app : Build/${APP_NAME}.app"
  echo "  DMG        : Build/${DMG_NAME}"
  echo ""
  echo "NOTARIZATION STEPS:"
  echo ""
  echo "  # One-time setup:"
  echo "  # xcrun notarytool store-credentials \"AC_NOTARY\" \\"
  echo "  #   --apple-id \"your@appleid.com\" --team-id \"YOURTEAMID\" \\"
  echo "  #   --password \"xxxx-xxxx-xxxx-xxxx\""
  echo ""
  echo "  xcrun notarytool submit \"Build/${DMG_NAME}\" --keychain-profile \"AC_NOTARY\" --wait"
  echo "  xcrun stapler staple \"Build/${DMG_NAME}\""
  echo "  spctl -a -vvv -t install \"Build/${DMG_NAME}\""
  echo ""

else
  echo "Building Release (unsigned, personal use)..."

  rm -rf ./DerivedData/Build/Products/Release/${APP_NAME}.app 2>/dev/null || true

  xcodebuild \
    -project ${APP_NAME}.xcodeproj \
    -scheme ${APP_NAME} \
    -configuration Release \
    -derivedDataPath ./DerivedData \
    -quiet \
    clean build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

  BUILT_APP=$(find ./DerivedData -path "*/Release/${APP_NAME}.app" -type d | head -1)
  if [[ -z "$BUILT_APP" ]]; then
    echo "Failed to find built ${APP_NAME}.app"; exit 1
  fi

  mkdir -p Build
  rm -rf "Build/${APP_NAME}.app" 2>/dev/null || true
  cp -R "$BUILT_APP" "Build/${APP_NAME}.app"

  echo ""
  echo "Build complete!"
  echo "  Output: $(pwd)/Build/${APP_NAME}.app"
  echo ""
  echo "To install: drag to /Applications"
  echo "First launch: System Settings -> Privacy & Security -> Open Anyway if warned."
fi

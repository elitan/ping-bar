#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_NAME="PingBar"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"

DEVELOPER_ID="Developer ID Application: Johan Eliasson (J2Z78W23W7)"
TEAM_ID="J2Z78W23W7"
BUNDLE_ID="com.elitan.pingbar"

cd "$PROJECT_DIR"

echo "Building $APP_NAME..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

echo "Signing app with hardened runtime..."
codesign --force --options runtime \
    --entitlements "$PROJECT_DIR/Resources/PingBar.entitlements" \
    --sign "$DEVELOPER_ID" \
    --timestamp \
    "$APP_BUNDLE"

echo "Verifying signature..."
codesign --verify --verbose "$APP_BUNDLE"

echo "Creating ZIP for notarization..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo ""
echo "====================================="
echo "App signed successfully!"
echo "ZIP ready for notarization: $ZIP_PATH"
echo ""
echo "To notarize, run:"
echo "  xcrun notarytool submit $ZIP_PATH --apple-id YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD --team-id $TEAM_ID --wait"
echo ""
echo "After notarization succeeds, staple with:"
echo "  xcrun stapler staple $APP_BUNDLE"
echo "====================================="

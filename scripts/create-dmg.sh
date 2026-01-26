#!/bin/bash
set -euo pipefail

APP_PATH="${1:-.build/release/PingBar.app}"
DMG_PATH="${2:-.build/release/PingBar.dmg}"
BACKGROUND_PATH="${3:-}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"

TEMP_DMG_PATH="${DMG_PATH%.dmg}-temp.dmg"

rm -f "$DMG_PATH" "$TEMP_DMG_PATH"

CREATE_DMG_ARGS=(
    --volname "PingBar"
    --window-size 660 400
    --icon-size 100
    --icon "PingBar.app" 180 170
    --app-drop-link 480 170
)

if [[ -n "$BACKGROUND_PATH" && -f "$BACKGROUND_PATH" ]]; then
    CREATE_DMG_ARGS+=(--background "$BACKGROUND_PATH")
fi

if [[ -n "$CODESIGN_IDENTITY" ]]; then
    CREATE_DMG_ARGS+=(--codesign "$CODESIGN_IDENTITY")
fi

create-dmg "${CREATE_DMG_ARGS[@]}" "$DMG_PATH" "$APP_PATH"

echo "Created DMG: $DMG_PATH"

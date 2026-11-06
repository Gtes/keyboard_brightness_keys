#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

DEST_DIR="${HOME}/Applications"
mkdir -p "$DEST_DIR" build

killall -9 \
  BrightnessKeys BrightnessKeysAgent BrightnessKeysHelper BrightnessKeysSettings \
  KeyboardBrightnessKeys KeyboardBrightnessKeysHelper \
  2>/dev/null || true

rm -rf \
  "$DEST_DIR/Brightness Keys.app" \
  "$DEST_DIR/Brightness Keys Agent.app" \
  "$DEST_DIR/Brightness Keys Helper.app" \
  "$DEST_DIR/Keyboard Brightness Keys.app" \
  "$DEST_DIR/Keyboard Brightness Keys Helper.app" \
  "./Brightness Keys.app" \
  "./Brightness Keys Helper.app" \
  "./Keyboard Brightness Keys.app" \
  "./Keyboard Brightness Keys Helper.app"

swiftc -target arm64-apple-macosx14.0 -swift-version 5 -framework Cocoa \
  Scripts/make-icon.swift -o build/make-icon

build_app() {
  local name="$1"
  local exec="$2"
  local plist="$3"
  shift 3
  local app="$name.app"
  rm -rf "$app"
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
  swiftc \
    -target arm64-apple-macosx14.0 \
    -swift-version 5 \
    -O \
    -framework Cocoa \
    "$@" \
    -o "$app/Contents/MacOS/$exec"
  cp "$plist" "$app/Contents/Info.plist"
  ./build/make-icon "$app/Contents/Resources/AppIcon.icns"
  chmod +x "$app/Contents/MacOS/$exec"
  codesign --force --sign - "$app"
  rm -rf "$DEST_DIR/$app"
  cp -R "$app" "$DEST_DIR/$app"
  codesign --force --sign - "$DEST_DIR/$app"
  rm -rf "$app"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST_DIR/$app" >/dev/null 2>&1 || true
  echo "Installed $DEST_DIR/$app"
}

build_app "Keyboard Brightness Keys Helper" "KeyboardBrightnessKeysHelper" "Helper-Info.plist" \
  Sources/Shared/*.swift Sources/Helper/*.swift

build_app "Keyboard Brightness Keys" "KeyboardBrightnessKeys" "Settings-Info.plist" \
  Sources/Shared/*.swift Sources/Settings/*.swift

echo "Done:"
echo "  open \"$DEST_DIR/Keyboard Brightness Keys.app\""

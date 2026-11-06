#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

DEST_DIR="${HOME}/Applications"
SETTINGS_APP="Keyboard Brightness Keys"
HELPER_APP="Keyboard Brightness Keys Helper"

mkdir -p "$DEST_DIR" build

if [[ ! -f Resources/Icon.png ]]; then
  echo "Missing Resources/Icon.png" >&2
  exit 1
fi

killall -9 KeyboardBrightnessKeys KeyboardBrightnessKeysHelper 2>/dev/null || true

rm -rf \
  "$DEST_DIR/${SETTINGS_APP}.app" \
  "$DEST_DIR/${HELPER_APP}.app" \
  "./${SETTINGS_APP}.app" \
  "./${HELPER_APP}.app"

make_icns() {
  local out="$1"
  rm -rf build/AppIcon.iconset
  mkdir -p build/AppIcon.iconset
  for size in 16 32 128 256 512; do
    sips -z $size $size Resources/Icon.png --out "build/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z $double $double Resources/Icon.png --out "build/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
  done
  iconutil -c icns build/AppIcon.iconset -o "$out"
  rm -rf build/AppIcon.iconset
}

fill_app() {
  local name="$1"
  local exec="$2"
  local plist="$3"
  shift 3
  local app="${name}.app"
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
  cp Resources/Icon.png "$app/Contents/Resources/Icon.png"
  make_icns "$app/Contents/Resources/AppIcon.icns"
  chmod +x "$app/Contents/MacOS/$exec"
}

# Build helper, then nest it inside Settings so users only install one .app
fill_app "$HELPER_APP" "KeyboardBrightnessKeysHelper" "Helper-Info.plist" \
  Sources/Shared/*.swift Sources/Helper/*.swift

fill_app "$SETTINGS_APP" "KeyboardBrightnessKeys" "Settings-Info.plist" \
  Sources/Shared/*.swift Sources/Settings/*.swift

mkdir -p "${SETTINGS_APP}.app/Contents/Library/LoginItems"
rm -rf "${SETTINGS_APP}.app/Contents/Library/LoginItems/${HELPER_APP}.app"
mv "${HELPER_APP}.app" "${SETTINGS_APP}.app/Contents/Library/LoginItems/${HELPER_APP}.app"

codesign --force --deep --sign - "${SETTINGS_APP}.app"

rm -rf "$DEST_DIR/${SETTINGS_APP}.app" "$DEST_DIR/${HELPER_APP}.app"
cp -R "${SETTINGS_APP}.app" "$DEST_DIR/${SETTINGS_APP}.app"
codesign --force --deep --sign - "$DEST_DIR/${SETTINGS_APP}.app"
rm -rf "${SETTINGS_APP}.app"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f \
  "$DEST_DIR/${SETTINGS_APP}.app" >/dev/null 2>&1 || true

echo "Installed $DEST_DIR/${SETTINGS_APP}.app"
echo "Helper nested at Contents/Library/LoginItems/${HELPER_APP}.app"
echo "Done: open \"$DEST_DIR/${SETTINGS_APP}.app\""

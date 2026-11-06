# Keyboard Brightness Keys

Restore **F5 / F6 keyboard backlight** control on modern MacBooks — the same behavior older MacBooks had — without turning on “Use F1, F2, etc. keys as standard function keys.”

F5 dims the keyboard backlight. F6 brightens it. Other function keys stay as they are. Hold **fn** for a normal F5 or F6.

![Settings](screenshots/settings.png)

> Replace `screenshots/settings.png` with a real capture of the Settings window (and optionally the menu bar icon).

## Apps

| App | Role |
| --- | --- |
| **Keyboard Brightness Keys** | Settings (Dock). Configure and start/stop the helper. |
| **Keyboard Brightness Keys Helper** | Background helper (no Dock). Applies the F5/F6 remap. |

Quit Settings anytime — the helper keeps running.

## Install

```bash
./build.sh
open ~/Applications/Keyboard\ Brightness\ Keys.app
```

Requires macOS 14+ (Apple Silicon build).

## Usage

1. Open **Keyboard Brightness Keys** from `~/Applications`.
2. Leave **Enabled** on.
3. Optionally show the menu bar icon, or start the helper at login.
4. Press **F5** / **F6** to change keyboard backlight.

## How it works

On current MacBook Pros, bare F5/F6 send Dictation and Focus HID usages. The helper remaps those usages to keyboard illumination down/up via `hidutil`, matching the 2015-era backlight keys.

## Development

```
Sources/Shared/     identity, config, HID remap, helper control
Sources/Helper/     background agent + menu bar icon
Sources/Settings/   settings UI
Resources/Icon.png  menu bar + app icon source
build.sh            builds and installs both apps
```

```bash
./build.sh
```

## License

Private / unpublished unless you add a license.

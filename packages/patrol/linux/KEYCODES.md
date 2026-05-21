# Linux evdev Keycode Reference for ydotool

This document maps every xdotool key name used in Patrol's Linux automation
(Dart client and Python service) to the corresponding Linux evdev keycode,
suitable for use with ydotool as a Wayland-compatible replacement.

## Key sources: `/usr/include/linux/input-event-codes.h`

---

## Keyboard Key Mappings

### Single Keys

| xdotool name          | Linux key constant       | evdev keycode | ydotool command                      | Used in                                 |
|-----------------------|--------------------------|---------------|--------------------------------------|-----------------------------------------|
| `Return` / `Enter`    | `KEY_ENTER`              | 28            | `ydotool key 28`                     | `openApp()` (Dart), `/pressKey` (Python)|
| `Super`               | `KEY_LEFTMETA`           | 125           | `ydotool key 125`                    | `pressHome()`, `openApp()` (Dart)       |
| `Tab`                 | `KEY_TAB`                | 15            | `ydotool key 15`                     | `pressRecentApps()`, `doublePressRecentApps()` |
| `XF86AudioRaiseVolume`| `KEY_VOLUMEUP`           | 115           | `ydotool key 115`                    | `pressVolumeUp()` (Dart)                |
| `XF86AudioLowerVolume`| `KEY_VOLUMEDOWN`         | 114           | `ydotool key 114`                    | `pressVolumeDown()` (Dart)              |
| `BackSpace`           | `KEY_BACKSPACE`          | 14            | `ydotool key 14`                     | `/pressKey` (Python, generic)           |
| `Escape`              | `KEY_ESC`                | 1             | `ydotool key 1`                      | `/pressKey` (Python, generic)           |
| `Left`                | `KEY_LEFT`               | 105           | `ydotool key 105`                    | key combination component (Dart)        |
| `Right`               | `KEY_RIGHT`              | 106           | `ydotool key 106`                    | `/pressKey` (Python, generic)           |
| `Up`                  | `KEY_UP`                 | 103           | `ydotool key 103`                    | `/pressKey` (Python, generic)           |
| `Down`                | `KEY_DOWN`               | 108           | `ydotool key 108`                    | `/pressKey` (Python, generic)           |
| `Home`                | `KEY_HOME`               | 102           | `ydotool key 102`                    | `/pressKey` (Python, generic)           |
| `End`                 | `KEY_END`                | 107           | `ydotool key 107`                    | `/pressKey` (Python, generic)           |
| `Page_Up`             | `KEY_PAGEUP`             | 104           | `ydotool key 104`                    | `/pressKey` (Python, generic)           |
| `Page_Down`           | `KEY_PAGEDOWN`           | 109           | `ydotool key 109`                    | `/pressKey` (Python, generic)           |
| `space` / `Space`     | `KEY_SPACE`              | 57            | `ydotool key 57`                     | `/pressKey` (Python, generic)           |

### Modifier Keys (for combinations)

| xdotool name  | Linux key constant | evdev keycode | Notes                        |
|---------------|--------------------|---------------|------------------------------|
| `Alt`         | `KEY_LEFTALT`      | 56            | Used in `Alt+Left`, `Alt+Tab`|
| `Ctrl`        | `KEY_LEFTCTRL`     | 29            | Available for future use     |
| `Shift`       | `KEY_LEFTSHIFT`    | 42            | Available for future use     |
| `Super`       | `KEY_LEFTMETA`     | 125           | Already covered above        |

### Alphanumeric Keys

| xdotool name | Linux key constant | evdev keycode | ydotool command        |
|--------------|--------------------|---------------|------------------------|
| `0`          | `KEY_0`             | 11            | `ydotool key 11`      |
| `1`–`9`      | `KEY_1`–`KEY_9`     | 2–10          | `ydotool key <code>`  |
| `Q`,`W`,`E`,`R`,`T`,`Y`,`U`,`I`,`O`,`P` | `KEY_Q`–`KEY_P` | 16–25 | `ydotool key <code>` |
| `A`,`S`,`D`,`F`,`G`,`H`,`J`,`K`,`L`     | `KEY_A`–`KEY_L` | 30–38 | `ydotool key <code>` |
| `Z`,`X`,`C`,`V`,`B`,`N`,`M`             | `KEY_Z`–`KEY_M` | 44–50 | `ydotool key <code>` |
| `A`–`Z`      | `KEY_A`–`KEY_Z`    | 16–50*        | `ydotool key 42:1 <code>:1 <code>:0 42:0` (with Shift) |

> **Note 1**: Linux evdev keycodes follow keyboard row layout, not alphabetical order.
> The ranges are: top row `Q`(16)–`P`(25), home row `A`(30)–`L`(38),
> bottom row `Z`(44)–`M`(50). Use the per-key table above to look up
> the exact code for each character.
>
> **Note 2**: Linux evdev keycodes do not distinguish uppercase/lowercase.
> Uppercase letters require holding `KEY_LEFTSHIFT` (42) while pressing the letter key.
> For text typing via `ydotool type`, use the `type` subcommand instead.

---

## Key Combinations

ydotool does not support named key combinations like `Alt+Left`.
You must send individual press and release events in sequence.

### `Alt+Left` — pressBack

```bash
# xdotool equivalent
xdotool key Alt+Left

# ydotool equivalent
ydotool key 56:1  105:1  105:0  56:0
#         ^ alt press  ^ left press  ^ left release  ^ alt release
```

### `Alt+Tab` — pressRecentApps / doublePressRecentApps

```bash
# xdotool equivalent
xdotool key Alt+Tab

# ydotool equivalent
ydotool key 56:1  15:1  15:0  56:0
#         ^ alt press  ^ tab press  ^ tab release  ^ alt release
```

### `Ctrl+C` (example for future use)

```bash
ydotool key 29:1  46:1  46:0  29:0
#         ^ ctrl press  ^ c press ('c' = 46)  ^ c release  ^ ctrl release
```

---

## Mouse Action Mappings

### Left Click — `click 1`

| Tool     | Command                                          |
|----------|--------------------------------------------------|
| xdotool  | `xdotool click 1`                                |
| ydotool  | `ydotool click 1`                                |

### Mouse Move — `mousemove x y`

| Tool     | Command                                          |
|----------|--------------------------------------------------|
| xdotool  | `xdotool mousemove <x> <y>`                      |
| ydotool  | `ydotool mousemove <x> <y>`                      |

### Mouse Down — `mousedown 1`

| Tool     | Command                                          |
|----------|--------------------------------------------------|
| xdotool  | `xdotool mousedown 1`                            |
| ydotool  | `ydotool mousedown 1`                            |

### Mouse Up — `mouseup 1`

| Tool     | Command                                          |
|----------|--------------------------------------------------|
| xdotool  | `xdotool mouseup 1`                              |
| ydotool  | `ydotool mouseup 1`                              |

> **Note**: ydotool uses the same convention as xdotool for mouse button numbers:
> - `1` = left button
> - `2` = middle button
> - `3` = right button
>
> Internally these map to evdev codes `BTN_LEFT` (272), `BTN_MIDDLE` (274), `BTN_RIGHT` (273).

---

## Text Typing

| Tool     | Command                                          |
|----------|--------------------------------------------------|
| xdotool  | `xdotool type "Hello world"`                     |
| ydotool  | `ydotool type "Hello world"`                     |

`ydotool type` works the same way as `xdotool type` — it types the given string
using the currently focused window.

---

## Screen Geometry (`getdisplaygeometry`)

| Tool     | Command                                          |
|----------|--------------------------------------------------|
| xdotool  | `xdotool getdisplaygeometry`                     |
| ydotool  | Not supported                                     |

**Alternatives for ydotool:**
- **wlroots compositors**: `wlr-randr` — parse output for current mode resolution
- **GNOME/KDE**: `gsettings get org.gnome.desktop.interface text-scaling-factor` (not resolution)
- **GDK/GTK**: Use Python's `gi.repository.Gdk` to query display geometry
- **XWayland fallback**: `xrandr --current` might work if the app runs via XWayland
- **Manual config**: Require user to specify resolution, or default to 1920×1080

---

## Usage in Code

### Dart — ydotool key press function

```dart
Future<void> _ydotoolKey(int keycode) async {
  await Process.run('ydotool', ['key', keycode.toString()]);
}

Future<void> _ydotoolKeyCombo(List<int> keycodes) async {
  // Send key-down for all, then key-up in reverse order
  final args = <String>['key'];
  for (final code in keycodes) {
    args.add('$code:1');
  }
  for (final code in keycodes.reversed) {
    args.add('$code:0');
  }
  await Process.run('ydotool', args);
}
```

### Python — ydotool key press function

```python
import subprocess

def ydotool_key(keycode: int):
    subprocess.run(["ydotool", "key", str(keycode)], check=True)

def ydotool_key_combo(keycodes: list):
    """Send a key combination (press all, release in reverse)."""
    args = ["key"]
    for code in keycodes:
        args.append(f"{code}:1")
    for code in reversed(keycodes):
        args.append(f"{code}:0")
    subprocess.run(["ydotool"] + args, check=True)
```

---

## ydotool Installation

```bash
# Most distros
sudo apt install ydotool          # Debian/Ubuntu (newer releases)
sudo dnf install ydotool          # Fedora
sudo pacman -S ydotool            # Arch

# Or from source
git clone https://github.com/ReimuNotMoe/ydotool.git
cd ydotool
cmake .
make
sudo make install
```

**udev rules for non-root access:**

```bash
sudo usermod -aG input $USER
echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/99-uinput.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

**Starting the daemon:**

```bash
ydotoold &
```

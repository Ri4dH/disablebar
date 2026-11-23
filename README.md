<div align="center">

<img src="docs/assets/hero.svg" alt="DisableBar switching off a flickering Touch Bar" width="100%">

# DisableBar

**Turn off a flickering MacBook Pro Touch Bar with one click, and stop ghost touches from pressing buttons.**

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black?logo=apple)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-SwiftUI-F05138?logo=swift&logoColor=white)](#build-from-source)
[![Apple Silicon + Intel](https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-6e5494)](#requirements)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Download](../../releases/latest) · [Features](#features) · [How it works](#how-it-works) · [FAQ](#faq)

</div>

---

Many Touch Bar MacBook Pros develop a **flickering, glitching or “ghost touching” Touch Bar**: the strip flashes, and phantom touches change the volume or brightness, or trigger Siri on their own. macOS has no setting to switch it off.

DisableBar adds a switch for it. It lives in your menu bar, needs no admin rights, doesn't modify macOS, and quitting it brings your Touch Bar back.

## Features

| | |
|---|---|
| ⏻ **One-click on/off** | Black out the whole Touch Bar (Esc and Control Strip included) from the menu bar or the main window. |
| ✋ **Ghost-touch shield** | While off, every touch is absorbed, so phantom touches can't press anything. A counter shows how many were blocked. |
| ⌨️ **Global shortcut** | Press <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>T</kbd> anywhere to toggle. |
| 👀 **Peek** | Need the Touch Bar for a moment? Peek shows it for 10 s – 5 min, then switches it off again. |
| ⎋ **Escape-key rescue** | Touch Bar Macs have no physical Esc key. Map **Caps Lock → Esc** (no permissions needed), or keep a dim, tappable `esc` on the bar. |
| 🚀 **Launch at login** | Optionally start with your Mac and switch the bar off immediately. |
| 🎛 **Layout switcher** | When the bar is on, choose *App Controls*, *Control Strip* or *F1–F12 keys*. |
| 🛠 **Restart Touch Bar** | One-click restart of `TouchBarServer` + `ControlStrip`, the usual fix for a frozen bar. It also detects and un-freezes a suspended Control Strip. |
| 🔁 **Self-healing** | Re-applies the blackout after sleep, wake, screen lock, or if macOS restarts the Touch Bar service. |

## Screenshots

<table>
  <tr>
    <td align="center" width="62%"><img src="docs/assets/window.png" alt="DisableBar main window"><br><sub>Main window</sub></td>
    <td align="center" valign="top"><img src="docs/assets/menu.png" alt="DisableBar menu bar popover"><br><sub>Menu bar popover</sub></td>
  </tr>
</table>

## Install

1. Download **`DisableBar.zip`** from the [latest release](../../releases/latest) and unzip it.
2. Drag **DisableBar.app** into **Applications**.
3. The app is ad-hoc signed (not notarized), so the first time you open it macOS will block it. Either right-click the app → **Open** → **Open**, or run:
   ```sh
   xattr -dr com.apple.quarantine /Applications/DisableBar.app
   ```
4. Look for the Touch Bar icon in your menu bar.

### Build from source

Requires Xcode 15+ (or the Swift 5.10+ toolchain).

```sh
git clone https://github.com/Ri4dH/disablebar.git
cd disablebar
./scripts/build-app.sh            # → build/DisableBar.app (universal)
./scripts/build-app.sh --install  # also copies it to /Applications
```

## How it works

The Touch Bar on every MacBook Pro is an **OLED** panel, so a black pixel emits no light. DisableBar uses the same private AppKit API that apps like MTMR and Pock rely on (`+[NSTouchBar presentSystemModalTouchBar:placement:systemTrayItemIdentifier:]`) to put a full-width, pure-black Touch Bar above every app and the Control Strip.

* **Visually off.** The panel shows nothing.
* **Touches go nowhere.** All input lands on a blank view, so ghost touches can't reach the volume slider, Siri or app buttons.
* **Nothing is changed on disk.** No system files, launch daemons or SIP changes. Quit the app (or toggle it on) and the normal Touch Bar comes back.

<details>
<summary><b>Why not just kill <code>TouchBarServer</code>?</b></summary>

That was the first thing tested, on a MacBook Pro (13", M1, 2020) with macOS 26:

| Approach | Result |
|---|---|
| `sudo pkill TouchBarServer` | launchd relaunches it instantly; the bar comes straight back. |
| `sudo launchctl bootout system/com.apple.touchbarserver` | `Operation not permitted while System Integrity Protection is engaged`. |
| `DFRSetStatus` / `DFRSetDimmingStep` (DFRFoundation) | No visible effect from a normal app. |
| **Full-width black system-modal Touch Bar** | ✅ Bar goes dark and touches are absorbed, without root. |

</details>

## FAQ

**Is the Touch Bar really off, or just black?**
It's showing pure black on an OLED panel, so the pixels are unlit. The touch digitizer stays powered, but every touch goes to DisableBar, which ignores it and counts it.

**Does it survive sleep, lock screen, or a Touch Bar crash?**
Yes. DisableBar re-applies itself on wake and unlock, and it watches `TouchBarServer` for restarts.

**What about Touch ID?**
Touch ID is a separate sensor and keeps working.

**How do I press Esc?**
Turn on **Caps Lock acts as Esc** in the app. It uses `hidutil`, keeps any key mappings you already have, and needs no permissions. You can also enable the dim on-bar `esc` key, which needs Accessibility permission to send the keystroke.

**How do I uninstall?**
Quit DisableBar from the menu bar and delete it from Applications. If you enabled Caps Lock → Esc, turn it off first, or log out / restart to clear it.

## Requirements

* A MacBook Pro with a Touch Bar (2016–2022), Apple Silicon or Intel
* macOS 13 Ventura or later (tested on macOS 26)

## Project layout

```
src/DisableBar/          SwiftUI app: state, menu bar, windows, hotkey, helpers
src/TouchBarPrivate/     Objective-C shim around the private Touch Bar API
scripts/build-app.sh     Builds, icons, signs and zips DisableBar.app
scripts/make-icon.swift  Renders the app icon
docs/assets/             README artwork
```

## License

[MIT](LICENSE). DisableBar isn't affiliated with Apple. “Touch Bar” and “MacBook Pro” are trademarks of Apple Inc.

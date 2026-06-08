![Modafinil](modafinil-lp.png)

# Modafinil

Keep your Mac awake while AI agents run. A minimal macOS menu bar app — left-click the pill icon to toggle, right-click to configure.

[![Download](https://img.shields.io/badge/Download-v1.2.1-0099FF?style=flat-square)](https://gigaptera.com/modafinil)
[![macOS](https://img.shields.io/badge/macOS-14.0%2B-lightgrey?style=flat-square&logo=apple)](https://gigaptera.com/modafinil)
[![License](https://img.shields.io/badge/License-Free-brightgreen?style=flat-square)](https://gigaptera.com/modafinil)

---

## Download

**[gigaptera.com/modafinil](https://gigaptera.com/modafinil)**

Or directly from [GitHub Releases](https://github.com/gigaptera/modafinil/releases/latest).
Open the DMG and drag Modafinil to Applications. Apple-notarized — no security warnings.

## Features

| | |
|---|---|
| **Left-click toggle** | The pill icon breaks apart when active |
| **Auto-stop timer** | 30 min / 1 hour / 2 hours / 4 hours / Unlimited (localized: Japanese only when system language is Japanese) |
| **Launch at login** | Configure from the right-click menu |
| **Lid-closed mode** | Optional privileged helper keeps a standalone MacBook awake with the lid shut (clamshell), via `pmset disablesleep` |
| **No Dock icon** | Lives only in the menu bar |

## Changelog

### v1.2.1
- **Reliable lid-closed (clamshell) mode** via an optional privileged helper. Enable it once from the right-click menu (a one-time approval in System Settings → Login Items). A root `LaunchDaemon` then toggles `pmset disablesleep` — the only mechanism that actually keeps a standalone MacBook awake with the lid shut. Replaces the previous best-effort `caffeinate` approach.
- The helper auto-reverts `disablesleep` whenever sleep prevention stops, or if Modafinil quits or crashes, so a lidded Mac never gets stuck awake.

### v1.2.0
- Fixed Japanese localization detection: now properly falls back to Japanese strings only when the system language is set to Japanese (using `Locale.preferredLanguages` for reliable detection even in accessory apps without `.lproj` resources).
- Bumped to 1.2.0 with the above fix.

### v1.1
- Added 30-minute option to the timer
- Added English localization (Japanese strings are shown only when the system language is set to Japanese)
- Simplified menu back to the original minimal design
- Better support for keeping the Mac awake with the lid closed on a standalone MacBook (no external display), including preventing automatic screen lock

## Requirements

- macOS 14.0 Sonoma or later
- Apple Silicon or Intel

## Build

```bash
# Local unsigned build
./build.sh

# Signed + notarized DMG (requires Developer ID certificate)
PROD=1 ./build.sh
```

## How it works

While active, Modafinil holds three IOPM assertions:
- `PreventSystemSleep`
- `PreventUserIdleSystemSleep`
- `PreventUserIdleDisplaySleep` (blocks the display-sleep timer that triggers auto-lock)

These keep the Mac awake while the lid is open, and are released on deactivate. They do **not** override clamshell sleep — for the lid-closed case, see below.

## Lid-closed / Clamshell mode

Closing the lid on a MacBook with no external display always sleeps it. IOPM assertions and `caffeinate` cannot override this — the only thing that does is the system-wide `SleepDisabled` flag (`pmset -a disablesleep 1`), which requires root.

Modafinil ships an optional privileged helper (a root `LaunchDaemon`) to toggle that flag:

1. Right-click the menu bar icon → **Keep awake with lid closed…**
2. Approve the background item once in **System Settings → General → Login Items**. macOS requires this — it cannot be enabled programmatically — but the approval persists across reboots.
3. With lid-closed mode on, activating sleep prevention also sets `disablesleep`. Close the lid and the Mac stays awake.

The helper automatically clears `disablesleep` when prevention stops, or if Modafinil quits or crashes — so a lidded Mac never gets stuck awake.

### Caveats

- **Security**: preventing sleep this way also prevents the lock screen — opening the lid resumes your session without a password prompt. Use only on machines you trust (your personal dev laptop, not a shared or travel machine).
- The Mac can run warm with the lid closed. Keep it on a hard surface with good airflow; never inside a bag.
- AC power is recommended for long runs; on battery the OS fights harder to sleep.

---

Made by [Gigaptera](https://gigaptera.com) · Kobe, Japan

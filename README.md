![Modafinil](modafinil-lp.png)

# Modafinil

Keep your Mac awake while AI agents run. A minimal macOS menu bar app — left-click the pill icon to toggle, right-click to configure.

[![Download](https://img.shields.io/badge/Download-v1.0-0099FF?style=flat-square)](https://gigaptera.com/modafinil)
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
| **Auto-stop timer** | 1h / 2h / 4h / unlimited |
| **Launch at login** | Configure from the right-click menu |
| **No Dock icon** | Lives only in the menu bar |

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

Uses `IOPMAssertionCreateWithName("PreventSystemSleep")` to prevent system sleep for the selected duration. The assertion is released immediately on deactivation or when the timer fires.

---

Made by [Gigaptera](https://gigaptera.com) · Kobe, Japan

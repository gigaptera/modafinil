# Modafinil

macOS menu bar app that prevents your Mac from sleeping — built for AI agent workflows that need to keep running with the lid closed.

![Modafinil icon](modafinil-icon.png)

## How it works

- **Left-click** the menu bar icon to toggle sleep prevention on/off
- The pill icon breaks apart when active, becomes whole when inactive
- **Right-click** to set a duration timer or manage settings

## Features

- Prevents system sleep via `IOPMAssertionCreateWithName("PreventSystemSleep")`
- Auto-stop timer: 1h / 2h / 4h / unlimited
- Launch at login
- No Dock icon — lives entirely in the menu bar

## Requirements

- macOS 14.0+
- Apple Silicon or Intel

## Build

```bash
# Local unsigned build
./build.sh

# Signed + notarized DMG (requires Developer ID certificate)
PROD=1 ./build.sh
```

After a production build, follow the printed notarization commands.

## Install

Download `Modafinil-1.0.dmg`, open it, and drag Modafinil to Applications.

On first launch, if macOS warns about the developer: **System Settings → Privacy & Security → Open Anyway**.

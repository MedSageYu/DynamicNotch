# 💊 Pill — Your Mac's New Best Friend

A sleek, pill-shaped command center that lives at the top of your screen.

> **100% AI-generated** — Every line of code was written by an AI assistant (OpenClaw + Claude).

## Features

| Feature | Description |
|---------|-------------|
| 🎵 Music | Now Playing with album art, play/pause/skip |
| 🪞 Mirror | Live camera preview, flip toggle |
| 📅 Calendar | 7-day scrollable view, event list, category filter |
| 📋 Clipboard | Auto-records last 20 copies (text + images), horizontal cards |
| 📡 AirDrop | Drag files near pill → expand → send, file tray with auto-clear |
| ⚙️ Settings | Auto-collapse timer, pill height, mirror flip, calendar filter |

## Build (3 commands)

```bash
git clone https://github.com/MedSageYu/Pill.git
cd Pill
swift build
```

That's it. `swift build` handles everything — no Xcode, no bridging headers, no manual compilation.

## Deploy

```bash
# Create app bundle
mkdir -p ~/Applications/Pill.app/Contents/MacOS

# Copy binary
cp .build/debug/Pill ~/Applications/Pill.app/Contents/MacOS/Pill

# Copy Info.plist (permissions, icon, etc.)
cp Sources/DynamicNotch/Info.plist ~/Applications/Pill.app/Contents/Info.plist

# Launch
open ~/Applications/Pill.app
```

## Requirements

- macOS 14.0+ (Sonoma or later)
- Apple Silicon (arm64)
- Swift 5.9+ (comes with Xcode 15+ or Command Line Tools)

### Swift Version Compatibility

This project is tested with Swift 6.3.2. If you have Swift 6.0.x, it should still work, but if you encounter issues:

```bash
# Check your Swift version
swift --version

# If older than 5.9, update Xcode or Command Line Tools
sudo softwareupdate --all --install --force
```

### Installing Swift

If `swift` command not found:
```bash
# Option 1: Install Xcode Command Line Tools
xcode-select --install

# Option 2: Install full Xcode from App Store
```

### Verifying Swift

```bash
swift --version
# Should show: swift-driver version X.X.X Apple Swift version 5.9+
```

## Permissions

| Permission | Why |
|-----------|-----|
| Camera | Mirror preview |
| Calendar | Event display |

The app will ask for permissions on first use.

## Architecture

```
Pill.app
├── Package.swift          ← Swift Package Manager config
├── Sources/DynamicNotch/
│   ├── main.swift         ← App entry point
│   ├── AppDelegate.swift  ← Lifecycle
│   ├── Info.plist         ← Permissions + bundle config
│   ├── Bridge/
│   │   └── mrhelper.c     ← Standalone C tool (compiled separately)
│   ├── Managers/
│   │   ├── NotchViewModel.swift    ← State management
│   │   ├── NotchWindow.swift       ← Transparent window
│   │   ├── NotchWindowController.swift ← Window lifecycle
│   │   ├── EventMonitor.swift      ← Global mouse tracking
│   │   ├── ClipboardManager.swift  ← Clipboard polling
│   │   └── NotificationManager.swift ← System notifications
│   ├── Views/
│   │   ├── NotchView.swift         ← Main pill UI
│   │   ├── MusicControlView.swift  ← Music controls
│   │   ├── MirrorPanel.swift       ← Camera + Settings
│   │   ├── ContentViews.swift      ← Calendar + File tray
│   │   ├── ClipboardPanelView.swift ← Clipboard history
│   │   ├── AirDropPanel.swift      ← AirDrop sharing
│   │   ├── FileTrayPanel.swift     ← File tray manager
│   │   ├── WaveformView.swift      ← Audio waveform animation
│   │   └── NotchTab.swift          ← Tab enum
│   └── Models/
│       └── AppSettings.swift       ← UserDefaults persistence
└── mrhelper/              ← Pre-compiled C tool (optional)
```

## How It Works

1. **Transparent Window** — A borderless NSWindow sits at the top of the screen, above the menu bar
2. **SwiftUI Content** — NotchView draws the pill shape and all content
3. **Global Event Monitor** — Tracks mouse position without NSTrackingArea (avoids click-through issues)
4. **Spring Animations** — Smooth expand/collapse with `.interactiveSpring`

## Troubleshooting

**Q: `swift build` says "manifest compilation error"**
A: This usually means Swift toolchain issue. Try:
```bash
# Reset Xcode Command Line Tools
sudo xcode-select --reset
xcode-select --install

# Or update to latest Xcode
sudo softwareupdate --all --install --force
```

**Q: `swift build` says "no such module"**
A: Make sure you're in the `Pill/` directory (where `Package.swift` is).

**Q: The app doesn't appear**
A: It's a background app (no Dock icon). Look at the top-center of your screen.

**Q: Music not showing**
A: Open Apple Music and play a song. The app polls every 2.5 seconds.

**Q: Calendar not showing events**
A: Grant calendar permission when prompted. Check Settings → calendar filter.

**Q: `swift` command not found**
A: Install Xcode Command Line Tools:
```bash
xcode-select --install
```

**Q: macOS version too old**
A: The app requires macOS 14.0 (Sonoma) or later. Check with:
```bash
sw_vers -productVersion
```

## Attribution

- **Author**: Yu Zhu (余铸)
- **AI Development**: OpenClaw + Claude
- **Repository**: https://github.com/MedSageYu/Pill

## License

MIT License

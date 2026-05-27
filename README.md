# Pill

A macOS menu bar application that lives at the top of your screen, providing quick access to everyday tools through a sleek, pill-shaped interface.

> **100% AI-generated** — Every line of code was written by an AI assistant (OpenClaw/Claude), from architecture to pixel.

## Features

### 🎵 Music Control
- Now Playing display with album art
- Play/Pause, Next, Previous controls
- Works with Apple Music

### 🪞 Mirror
- Live camera preview directly in the pill
- Flip/mirror toggle
- Dynamic circular frame

### 📅 Calendar
- 7-day horizontal scrollable view
- Today highlighted
- Event list from system Calendar (EKEventStore)
- Filter by calendar category in Settings

### 📋 Clipboard History
- Auto-records last 20 copied items (text + images)
- Horizontal card layout (like social media feed)
- Hover to expand text preview
- One-click copy back to clipboard
- Auto-cleanup beyond 20 items

### 📡 AirDrop
- Drop files near the pill → auto-expand → send via AirDrop
- File tray for temporary storage
- Configurable auto-clear policy (on drag out / 1 hour / 2 hours / 1 day / never)

### ⚙️ Settings
- Auto-collapse timer (0.5–10.0s)
- Collapsed pill height (18–40pt)
- Camera mirror flip
- Calendar category filter
- File tray clear policy

## Architecture

```
Pill.app
├── NotchWindow (NSWindow, .statusBar+8, transparent)
├── DragOverlayView (file drag detection)
│   └── NSHostingView → NotchView
│       ├── CollapsedMusicView (album art + waveform)
│       ├── CollapsedNotificationView
│       └── expandedContent
│           ├── Tab 1: Home (Music | Mirror | Calendar)
│           ├── Tab 2: AirDrop + File Tray
│           ├── Tab 3: Clipboard History
│           └── Tab 4: Settings
└── Global EventMonitor (mouse tracking, no NSTrackingArea)
```

## Build

```bash
# Clone
git clone https://github.com/MedSageYu/Pill.git
cd Pill

# Build
swift build

# Deploy
mkdir -p ~/Applications/Pill.app/Contents/MacOS
cp .build/debug/Pill ~/Applications/Pill.app/Contents/MacOS/Pill
cp Sources/DynamicNotch/Info.plist ~/Applications/Pill.app/Contents/Info.plist
open ~/Applications/Pill.app
```

## Requirements

- macOS 14.0+
- Apple Silicon (arm64)
- Swift 5.9+

## Permissions

| Permission | Purpose |
|-----------|---------|
| Camera | Mirror preview |
| Calendar | Event display |
| Accessibility | Media key simulation (optional) |

## Attribution

This project was **entirely developed by AI** (OpenClaw agent powered by Claude).

If you use, modify, or redistribute this code, please credit:
- **Author**: Yu Zhu (余铸)
- **AI Development**: OpenClaw + Claude
- **Repository**: https://github.com/MedSageYu/Pill

## License

MIT License — use freely for any purpose.

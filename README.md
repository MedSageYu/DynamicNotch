# DynamicNotch

> **A free, open-source Dynamic Island for your Mac.**

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14+-blue?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6.3-orange?logo=swift" alt="Swift 6.3">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/github/stars/MedSageYu/DynamicNotch?style=social" alt="GitHub Stars">
</p>

<p align="center">
  <strong>English</strong> | <a href="README_CN.md">中文</a>
</p>

---



**DynamicNotch** brings the iPhone Dynamic Island experience to macOS — a smart, floating notch that lives in your menu bar and adapts to what you're doing.

### Why DynamicNotch?

- 🎵 **Music Control** — See what's playing, skip tracks, all from the notch
- 📷 **Camera Preview** — Quick webcam access right from the menu bar
- 📅 **Calendar Glance** — 11-day scrolling calendar with your events
- 📡 **AirDrop** — Drag files to the notch, share instantly
- 🤖 **AI Chat** — Built-in QClaw AI assistant
- 🔔 **Smart Notifications** — iMessage & Mail alerts appear in the notch
- 🎨 **Native Design** — Feels like it belongs on your Mac

All of this, **100% free and open source**.

---

## 📸 Screenshots

> Screenshots coming soon. Clone and try it yourself — takes 30 seconds.

---

## 🚀 Quick Start

### Requirements

- macOS 14.0+ (Sonoma or later)
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Swift 6.0+ (install via `xcode-select --install`)

### Install & Run

```bash
git clone https://github.com/MedSageYu/DynamicNotch.git
cd DynamicNotch
swift build

# Deploy to Applications
mkdir -p ~/Applications/DynamicNotch.app/Contents/{MacOS,Resources}
cp .build/debug/DynamicNotch ~/Applications/DynamicNotch.app/Contents/MacOS/
cp Sources/DynamicNotch/Info.plist ~/Applications/DynamicNotch.app/Contents/

# Launch
open ~/Applications/DynamicNotch.app
```

### One-liner (rebuild & launch)

```bash
pkill -f DynamicNotch 2>/dev/null; sleep 0.3 && swift build && cp .build/debug/DynamicNotch ~/Applications/DynamicNotch.app/Contents/MacOS/ && cp Sources/DynamicNotch/Info.plist ~/Applications/DynamicNotch.app/Contents/ && open ~/Applications/DynamicNotch.app
```

---

## 🎯 Features

### Collapsed State (the notch)

| Trigger | Behavior |
|---------|----------|
| Idle | Sleek black capsule, no shadow |
| Hover | Subtle shadow appears (visual feedback) |
| Hover 0.4s | Auto-expands to full panel |
| Playing music | Pill widens with album art + waveform animation |
| Notification | Shows message preview for 5 seconds |
| Right-click | Quick exit menu |

### Expanded State — Three-Tab Layout

**🏠 Home** — Music | Camera | Calendar side by side

| Panel | What it does |
|-------|-------------|
| **Music** | Real-time track info via AppleScript — title, artist, album art, play/pause/skip |
| **Camera** | Live webcam preview with mirror toggle |
| **Calendar** | 11-day horizontal scroll (today ± 5), trackpad-native swipe, event list with color coding |

**📡 AirDrop** — Drop files to share via system AirDrop + local file tray for temporary storage

**⚙️ Settings** — Auto-collapse delay, calendar selection, file tray cleanup policy, and more

---

## ⚙️ Configuration

| Setting | Range | Default | Description |
|---------|-------|---------|-------------|
| Auto-collapse | 0.5 – 10s | 2.0s | Time before expanded panel auto-closes |
| Collapsed height | 18 – 40pt | 26pt | Height of the capsule in idle state |
| Mirror preview | on/off | on | Flip camera preview horizontally |
| Calendar filter | multi-select | all | Which calendars to display |
| File tray cleanup | 5 options | remove on drag | What happens when files leave the tray |

---

## 🔒 Permissions

DynamicNotch will request permissions on first launch:

| Permission | Used for | Required? |
|------------|----------|-----------|
| **Accessibility** | Mouse hover & click detection | ✅ Yes |
| Camera | Webcam preview | Optional |
| Calendar | Event display | Optional |

> **Accessibility permission is required.** Go to **System Settings → Privacy & Security → Accessibility** and enable DynamicNotch. Without it, the notch can't detect your mouse.

---

## 🏗️ Architecture

```
DynamicNotch.app
├── main.swift                     # App entry, LSUIElement (no Dock icon)
├── AppDelegate.swift              # Lifecycle management
├── Managers/
│   ├── NotchViewModel.swift       # Core state (size, animation, events, settings)
│   ├── NotchWindow.swift          # Transparent borderless window (statusBar+8 level)
│   ├── NotchWindowController.swift # Window control + drag overlay
│   ├── EventMonitor.swift         # Global/local mouse event monitoring
│   └── NotificationManager.swift  # System notification listener (iMessage/Mail)
├── Views/
│   ├── NotchView.swift            # Main notch view (capsule/collapsed/expanded/tabs)
│   ├── MusicControlView.swift     # Music controls + AppleScript queries
│   ├── MirrorPanel.swift          # Camera preview + settings
│   ├── ContentViews.swift         # Calendar + file tray
│   ├── AirDropPanel.swift         # AirDrop sharing
│   ├── FileTrayPanel.swift        # File tray manager + UI
│   ├── WaveformView.swift         # Audio waveform animation
│   └── QClawChatView.swift        # AI chat WebView
├── Models/
│   └── AppSettings.swift          # Settings + file tray cleanup strategy
└── Info.plist                     # Permissions + LSUIElement
```

### Key Technical Decisions

| Challenge | Solution |
|-----------|----------|
| Floating window above menu bar | `NSWindow.Level.statusBar + 8` with `isOpaque = false` |
| Global mouse detection | `NSEvent.addGlobalMonitorForEvents` (no NSTrackingArea) |
| Music metadata | AppleScript queries to Music.app |
| Album art export | `write artData to fd` (not `as data`!) |
| Camera frame sync | Custom `NSView.layout()` sets `previewLayer.frame = bounds` |
| Screen adaptation | Dynamic sizing based on screen width (13%–35% range) |

---

## 🐛 Known Issues

- Music panel text alignment may vary on extreme screen sizes
- AirDrop requires target device to be nearby with receiving enabled
- Camera preview may have ~0.5s startup delay on some Macs

---

## 🛣️ Roadmap

- [ ] Spotify & other music app support
- [ ] Widget system (customizable panels)
- [ ] More notification sources (Slack, Discord, etc.)
- [ ] Theming & color customization
- [ ] Homebrew Cask distribution
- [ ] Intel Mac optimization

---

## 🤝 Contributing

Contributions are welcome! Here's how:

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- [NotchDrop](https://github.com/Lakr233/NotchDrop) — Global event monitoring architecture reference
- [OpenClaw](https://github.com/nicepkg/openclaw) — AI Agent development platform
- Apple — SwiftUI, AppKit, EventKit frameworks

---

<p align="center">
  <strong>⭐ If you like DynamicNotch, give it a star! ⭐</strong><br>
  <em>It helps others discover this project.</em>
</p>

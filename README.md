# DynamicNotch

macOS 虚拟灵动岛应用 —— 为没有刘海的 Mac 带来 iPhone 灵动岛体验。

> 🍎 用 OpenClaw AI Agent 对话式驱动开发，从零到完成约 30 轮迭代。

![macOS](https://img.shields.io/badge/macOS-14+-blue)
![Swift](https://img.shields.io/badge/Swift-6.3-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## ✨ 功能一览

### 🏠 主页（三栏布局）

| 栏位 | 功能 | 说明 |
|------|------|------|
| 左栏 | **音乐控制** | AppleScript 实时获取当前播放曲目、歌手、专辑封面；支持播放/暂停/上下曲；无播放时显示居中占位提示 |
| 中栏 | **摄像头预览** | 前置摄像头实时预览，支持镜像翻转；点击激活，离开自动关闭 |
| 右栏 | **日历** | 11 天横向滚动（today ± 5），触控板双指滑动；点击日期查看当天日程（最多 3 条彩色竖条） |

### 📡 隔空投送页（Tab 2）

| 区域 | 功能 |
|------|------|
| 左 1/3 | **AirDrop**：拖入文件或点击选择，通过系统 AirDrop 发送 |
| 右 2/3 | **文件托盘**：虚线框拖放区，文件复制到本地暂存，支持拖出、点击打开、Option+点击删除 |

### ⚙️ 更多页（Tab 3）

| 按钮 | 功能 |
|------|------|
| 设置 | 自动收起时间、收起高度、镜像翻转、日历选择、文件托盘清除策略 |
| AI | 嵌入 QClaw 对话界面（WKWebView 加载本地 gateway） |

### 🎯 折叠态交互

| 状态 | 表现 |
|------|------|
| 空闲 | 黑色胶囊，无阴影 |
| 悬停 | 加深阴影（opacity 0.5, radius 16, y 4），不改变尺寸 |
| 播放音乐 | pill 自动加宽，左侧专辑封面 + 右侧波形动画 |
| 收到通知 | 显示通知摘要（标题 + 副标题），5 秒后自动消失 |
| 右键 | 弹出退出菜单 |

---

## 🏗️ 技术架构

```
DynamicNotch.app
├── main.swift                    # 应用入口，LSUIElement 隐藏 Dock
├── AppDelegate.swift             # 生命周期管理
├── Managers/
│   ├── NotchViewModel.swift      # 核心状态管理（尺寸/动画/事件/设置）
│   ├── NotchWindow.swift         # 透明无边窗口（statusBar+8 层级）
│   ├── NotchWindowController.swift # 窗口控制 + DragOverlayView 拖拽
│   ├── EventMonitor.swift        # 全局/本地鼠标事件监听
│   └── NotificationManager.swift # 系统通知监听（iMessage/邮件）
├── Views/
│   ├── NotchView.swift           # 灵动岛主视图（胶囊/折叠/展开/Tab）
│   ├── MusicControlView.swift    # 音乐控制 + AppleScript 查询
│   ├── MirrorPanel.swift         # 摄像头预览 + 设置面板
│   ├── ContentViews.swift        # 日历视图 + 文件托盘
│   ├── AirDropPanel.swift        # AirDrop 面板
│   ├── FileTrayPanel.swift       # 文件托盘管理器 + UI
│   ├── WaveformView.swift        # 音频波形动画
│   ├── NotchTab.swift            # Tab 枚举定义
│   └── QClawChatView.swift       # AI 对话 WebView
├── Models/
│   └── AppSettings.swift         # 应用设置 + 文件托盘清除策略
├── Bridge/
│   └── mrhelper.c                # MediaRemote C 桥接（备用）
└── Info.plist                    # 权限声明 + LSUIElement
```

---

## 🚀 快速开始

### 环境要求

- macOS 14.0+（Sonoma 及以上）
- Apple Silicon（M1/M2/M3/M4）
- Swift 6.0+（Xcode Command Line Tools）

### 编译运行

```bash
# 克隆仓库
git clone https://github.com/MedSageYu/DynamicNotch.git
cd DynamicNotch

# 编译
swift build

# 部署到应用程序
mkdir -p ~/Applications/DynamicNotch.app/Contents/{MacOS,Resources}
cp .build/debug/DynamicNotch ~/Applications/DynamicNotch.app/Contents/MacOS/
cp Sources/DynamicNotch/Info.plist ~/Applications/DynamicNotch.app/Contents/

# 启动
open ~/Applications/DynamicNotch.app
```

### 一键部署脚本

```bash
pkill -f DynamicNotch 2>/dev/null; sleep 0.3
swift build && \
cp .build/debug/DynamicNotch ~/Applications/DynamicNotch.app/Contents/MacOS/ && \
cp Sources/DynamicNotch/Info.plist ~/Applications/DynamicNotch.app/Contents/ && \
open ~/Applications/DynamicNotch.app
```

---

## 📋 权限说明

首次运行时系统会弹出权限请求：

| 权限 | 用途 | 必需 |
|------|------|------|
| 摄像头 | 镜子预览功能 | 可选 |
| 日历 | 读取日程事件 | 可选 |
| 辅助功能 | 全局鼠标事件监听 | ✅ 必需 |

> ⚠️ **辅助功能权限**：首次运行后需到 **系统设置 → 隐私与安全性 → 辅助功能** 中勾选 DynamicNotch。没有此权限，灵动岛无法检测鼠标悬停和点击。

---

## ⚙️ 设置项

| 设置 | 范围 | 默认值 | 说明 |
|------|------|--------|------|
| 自动收起时间 | 0.5 - 10 秒 | 2.0s | 展开后无操作自动收起的等待时间 |
| 收起高度 | 18 - 40 pt | 26pt | 折叠态胶囊高度（自适应屏幕尺寸） |
| 镜像翻转 | 开/关 | 开 | 摄像头预览是否水平翻转 |
| 日历选择 | 多选 | 全部 | 勾选要显示的日历分类 |
| 文件托盘策略 | 5 种 | 拖出后清除 | 文件从托盘拖出后的清除规则 |

### 文件托盘清除策略

| 策略 | 行为 |
|------|------|
| 拖出后清除 | 文件从托盘拖出后立即删除缓存 |
| 1 小时后清除 | 文件在托盘中保留 1 小时后自动删除 |
| 2 小时后清除 | 文件在托盘中保留 2 小时后自动删除 |
| 1 天后清除 | 文件在托盘中保留 1 天后自动删除 |
| 永不清除 | 文件永久保留在托盘中 |

---

## 🖱️ 交互方式

| 操作 | 效果 |
|------|------|
| 鼠标悬停在胶囊上 | 加深阴影（视觉反馈） |
| 悬停 0.4 秒 | 自动展开灵动岛 |
| 点击胶囊 | 立即展开 |
| 点击空白区域 | 收起灵动岛 |
| 右键点击胶囊 | 弹出退出菜单 |
| 触控板双指滑动 | 日历横向滚动 |
| 拖文件到 AirDrop 区域 | 发起隔空投送 |
| 拖文件到文件托盘区域 | 复制文件到本地暂存 |
| Option + 点击托盘文件 | 删除该文件 |

---

## 🔧 核心技术点

### 窗口渲染

```swift
// 透明无边窗口，浮动在状态栏之上
window.isOpaque = false
window.backgroundColor = .clear
window.level = NSWindow.Level.statusBar + 8
window.collectionBehavior = [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces]
```

### 全局事件监听（参考 NotchDrop 架构）

```swift
// 不使用 NSTrackingArea / SwiftUI onTapGesture
// 直接用 NSEvent.addGlobalMonitorForEvents 捕获鼠标事件
mouseMoveMonitor = EventMonitor(mask: .mouseMoved) { _ in
    let loc = NSEvent.mouseLocation
    let nearNotch = self.hitRect.contains(loc)
    // 坐标判断 → 控制 hover/popping/opened 状态
}
```

### AppleScript 音乐查询

```applescript
tell application "Music"
    if it is running then
        set t to name of current track
        set a to artist of current track
        -- 封面：raw data → 写入文件 → NSImage 加载
        set d to raw data of artwork 1 of current track
        set fd to open for access POSIX file "/tmp/dn_artwork.jpg"
        write d to fd
    end if
end tell
```

### 屏幕自适应尺寸

```swift
// 根据屏幕尺寸动态计算 pill 大小
let closedW = (screenWidth * 0.13).clamped(to: 155...220)
let expandedW = (screenWidth * 0.35).clamped(to: 420...580)
let hasNotch = menuBarHeight >= 30  // 检测刘海屏
```

---

## 📁 文件缓存

| 路径 | 内容 | 自动清理 |
|------|------|----------|
| `~/Library/Caches/DynamicNotch/FileTray/` | 文件托盘暂存 | 按策略清理 |
| `~/Library/Caches/DynamicNotch/AirDrop/` | AirDrop 临时副本 | 启动时清理 |
| `/tmp/dn_artwork.jpg` | 当前歌曲封面 | 每次查询覆写 |
| `/tmp/notch_wc.log` | 诊断日志 | 超 512KB 自动截断 |

---

## 🐛 已知问题

- 未播放音乐时，展开态音乐列文字居中可能受屏幕尺寸影响
- AirDrop 需要目标设备在附近且开启 AirDrop 接收
- 摄像头预览在部分 Mac 上可能延迟 0.5 秒启动

---

## 📝 开发日志

| 日期 | 里程碑 |
|------|--------|
| 2026-05-15 | 项目启动，基础窗口渲染 |
| 2026-05-18 | 音乐控制接入（AppleScript） |
| 2026-05-19 | 摄像头预览 + 日历功能 |
| 2026-05-21 | 设置面板 + UserDefaults 持久化 |
| 2026-05-22 | 全局事件监听架构重构（参考 NotchDrop） |
| 2026-05-23 | 折叠态音乐展示 + 通知上岛 + AirDrop 拖拽 |
| 2026-05-24 | 屏幕自适应 + 右键退出 + 动画优化 |
| 2026-05-25 | 三栏 Tab 重构 + 文件托盘 + QClaw AI 集成 |
| 2026-05-26 | 拖拽修复 + GitHub 开源 |

---

## 📄 License

MIT License - 自由使用、修改、分发。

---

## 🙏 致谢

- [NotchDrop](https://github.com/Lakr233/NotchDrop) - 全局事件监听架构参考
- [OpenClaw](https://github.com/nicepkg/openclaw) - AI Agent 开发平台
- Apple - SwiftUI、AppKit、EventKit 框架

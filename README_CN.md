# DynamicNotch

> **免费、开源的 macOS 虚拟灵动岛**

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14+-blue?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6.3-orange?logo=swift" alt="Swift 6.3">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/github/stars/MedSageYu/DynamicNotch?style=social" alt="GitHub Stars">
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>中文</strong>
</p>

---



**DynamicNotch** 为 macOS 带来 iPhone 灵动岛体验 —— 一个智能浮动胶囊，驻留在菜单栏，随你的操作自动适配。

### 为什么选择 DynamicNotch？

- 🎵 **音乐控制** — 显示当前曲目、切歌、播放/暂停，一切在胶囊中完成
- 📷 **摄像头预览** — 菜单栏一键开启前置摄像头
- 📅 **日历速览** — 11 天横向滚动，触控板原生滑动
- 📡 **隔空投送** — 拖文件到胶囊，一键 AirDrop
- 🤖 **AI 助手** — 内置 QClaw AI 对话界面
- 🔔 **通知上岛** — iMessage 和邮件通知自动显示
- 🎨 **原生设计** — 和 macOS 融为一体

全部功能 **100% 免费开源**。

---

## 🚀 快速开始

### 环境要求

- macOS 14.0+（Sonoma 及以上）
- Apple Silicon（M1/M2/M3/M4）或 Intel Mac
- Swift 6.0+（通过 `xcode-select --install` 安装）

### 编译运行

```bash
git clone https://github.com/MedSageYu/DynamicNotch.git
cd DynamicNotch
swift build

# 部署到应用程序
mkdir -p ~/Applications/DynamicNotch.app/Contents/{MacOS,Resources}
cp .build/debug/DynamicNotch ~/Applications/DynamicNotch.app/Contents/MacOS/
cp Sources/DynamicNotch/Info.plist ~/Applications/DynamicNotch.app/Contents/

# 启动
open ~/Applications/DynamicNotch.app
```

### 一键重新编译部署

```bash
pkill -f DynamicNotch 2>/dev/null; sleep 0.3 && swift build && cp .build/debug/DynamicNotch ~/Applications/DynamicNotch.app/Contents/MacOS/ && cp Sources/DynamicNotch/Info.plist ~/Applications/DynamicNotch.app/Contents/ && open ~/Applications/DynamicNotch.app
```

---

## 🎯 功能详解

### 折叠态（胶囊）

| 触发 | 表现 |
|------|------|
| 空闲 | 黑色胶囊，无阴影 |
| 悬停 | 阴影加深（视觉反馈） |
| 悬停 0.4s | 自动展开 |
| 播放音乐 | 胶囊加宽，显示专辑封面 + 波形动画 |
| 收到通知 | 显示通知摘要，5 秒后消失 |
| 右键 | 快捷退出菜单 |

### 展开态 — 三栏布局

**🏠 主页** — 音乐 | 摄像头 | 日历 并排显示

| 面板 | 功能 |
|------|------|
| **音乐** | AppleScript 实时获取曲目信息 — 歌名、歌手、封面、播放/暂停/切歌 |
| **摄像头** | 前置摄像头实时预览，支持镜像翻转 |
| **日历** | 11 天横向滚动（today ± 5），触控板原生滑动，彩色日程条 |

**📡 隔空投送** — 拖文件分享 + 本地文件暂存

**⚙️ 设置** — 自动收起时间、日历筛选、文件托盘策略等

---

## 🔒 权限说明

| 权限 | 用途 | 必需？ |
|------|------|--------|
| **辅助功能** | 鼠标悬停和点击检测 | ✅ 必需 |
| 摄像头 | 摄像头预览 | 可选 |
| 日历 | 日程显示 | 可选 |

> **辅助功能权限必须开启。** 前往 **系统设置 → 隐私与安全性 → 辅助功能**，勾选 DynamicNotch。

---

## 📄 许可证

MIT 许可证 — 自由使用、修改、分发。

---

<p align="center">
  <strong>⭐ 喜欢 DynamicNotch？给个 Star 吧！⭐</strong>
</p>

# DynamicNotch 推广策略

## 第一步：视觉素材（最重要，0 星 → 50 星的关键）

### 必须制作的素材

| 素材 | 用途 | 拍摄方法 |
|------|------|----------|
| **demo.gif** (主图) | README 顶部，所有平台分享 | 见下方拍摄指南 |
| screenshot-collapsed.png | 折叠态截图 | `screencapture -x` |
| screenshot-expanded.png | 展开态截图 | 展开后 `screencapture -x` |
| screenshot-music.png | 播放音乐时的截图 | 播放音乐后截图 |

### GIF 拍摄指南

```bash
# 1. 启动 DynamicNotch
open ~/Applications/DynamicNotch.app

# 2. 用系统录屏（按 Cmd+Shift+5 → 选择录制区域 → 录制）
#    录制内容建议：
#    - 静止 1 秒（展示折叠态）
#    - 鼠标悬停 → 展开动画
#    - 展开态停留 2 秒（展示三栏）
#    - 点击音乐播放 → 封面+波形出现
#    - 收起
#    总时长控制在 5-8 秒

# 3. 转 GIF（用 ffmpeg，如果没有先装）
# brew install ffmpeg
ffmpeg -i recording.mov -vf "fps=15,scale=600:-1:flags=lanczos" -loop 0 docs/demo.gif

# 4. 压缩到 5MB 以内（GitHub README 限制）
# 用 https://ezgif.com/optimize 在线压缩
```

### 截图拍摄

```bash
# 创建 docs 目录
mkdir -p docs

# 折叠态截图
screencapture -x docs/screenshot-collapsed.png

# 展开态截图（先展开灵动岛）
screencapture -x docs/screenshot-expanded.png

# 音乐播放截图
# 先用 Apple Music 播放一首歌，然后：
screencapture -x docs/screenshot-music.png
```

---

## 第二步：GitHub 优化

### 已完成 ✅
- [x] 英文 README（主语言）
- [x] 中文 README（README_CN.md）
- [x] Badge（macOS/Swift/License/Stars）
- [x] 项目描述简洁有力
- [x] 功能表格清晰
- [x] 架构说明
- [x] 快速开始指南
- [x] Roadmap

### 待完成
- [ ] 录制 demo GIF 并放入 docs/
- [ ] 截图放入 docs/
- [ ] 添加 LICENSE 文件（如还没有）
- [ ] 添加 CONTRIBUTING.md
- [ ] 添加 .github/ISSUE_TEMPLATE
- [ ] 考虑 Homebrew Cask 安装方式

---

## 第三步：推广渠道（按优先级排序）

### 🥇 第一梯队（高转化率）

| 平台 | 发布方式 | 预期效果 | 时间点 |
|------|----------|----------|--------|
| **Reddit r/macapps** | 发帖介绍，附 GIF | 50-200 stars | 素材准备好后立即 |
| **Reddit r/macOS** | 同上 | 30-100 stars | 同上 |
| **Hacker News (Show HN)** | "Show HN: DynamicNotch – Free Dynamic Island for Mac" | 100-500 stars | 工作日上午（美东时间） |
| **Product Hunt** | 提交为新产品 | 50-300 stars | 准备好后 |

### 🥈 第二梯队（持续曝光）

| 平台 | 发布方式 | 预期效果 |
|------|----------|----------|
| **Twitter/X** | 发 GIF 演示视频，tag @macapps @SwiftUI | 20-100 stars |
| **V2EX** | 分享到 macOS 节点 | 20-50 stars |
| **少数派** | 投稿介绍文章 | 30-100 stars |
| **即刻** | 发布到 macOS 相关圈子 | 10-30 stars |

### 🥉 第三梯队（长尾效应）

| 平台 | 发布方式 |
|------|----------|
| **YouTube** | 录制 2 分钟演示视频 |
| **B站** | 中文演示视频 |
| **GitHub Trending** | 自然上榜（需要前两步的积累） |
| **Awesome-macOS** | 提交 PR 到 awesome 列表 |

---

## 第四步：发布模板

### Reddit 帖子模板

```
Title: I built a free Dynamic Island for macOS – DynamicNotch

Hey r/macapps!

I've always loved the Dynamic Island on iPhone, so I built one for Mac.
It's 100% free and open source.

What it does:
• 🎵 Music control (album art, waveform, play/pause/skip)
• 📷 Quick camera preview
• 📅 11-day calendar with your events
• 📡 AirDrop from the notch
• 🔔 Smart notifications (iMessage, Mail)

Built with Swift/SwiftUI, runs on macOS 14+.

[GIF demo]

GitHub: https://github.com/MedSageYu/DynamicNotch

Would love your feedback! What features would you add?
```

### Hacker News (Show HN) 模板

```
Title: Show HN: DynamicNotch – Free, Open-Source Dynamic Island for macOS

I built a macOS app that brings the iPhone Dynamic Island experience to
MacBooks. It lives in the menu bar as a smart capsule that expands to show
music controls, calendar events, camera preview, and AirDrop sharing.

Key technical decisions:
- Floating window at statusBar+8 level with transparent background
- Global mouse monitoring via NSEvent (no NSTrackingArea)
- AppleScript for Music.app integration
- Dynamic sizing based on screen dimensions

Built with Swift 6.3 + SwiftUI, MIT licensed.

[link to GitHub]
```

### Twitter/X 推文模板

```
🎵 I built a free Dynamic Island for macOS!

✅ Music control with album art & waveform
✅ Camera preview from the menu bar
✅ Calendar glance with trackpad swipe
✅ AirDrop drag & drop
✅ Smart notifications

100% free & open source ⭐

[GIF demo]

https://github.com/MedSageYu/DynamicNotch

#macOS #SwiftUI #OpenSource #DynamicIsland
```

---

## 第五步：发布时间表

| 日期 | 任务 | 状态 |
|------|------|------|
| **Day 1** | 录制 demo GIF + 截图 | ⬜ |
| **Day 1** | 更新 README 加入图片 | ⬜ |
| **Day 1** | Git commit + push | ⬜ |
| **Day 2** | 发 Reddit r/macapps + r/macOS | ⬜ |
| **Day 2** | 发 Twitter/X | ⬜ |
| **Day 3** | 发 Show HN（美东上午 9-10 点） | ⬜ |
| **Day 3** | 发 V2EX + 少数派 | ⬜ |
| **Day 4** | 发 Product Hunt | ⬜ |
| **Day 5-7** | 回复评论，收集反馈 | ⬜ |
| **Week 2** | 根据反馈修复 bug，发更新 | ⬜ |

---

## 关键指标

| 里程碑 | Stars 目标 | 时间预期 |
|--------|-----------|----------|
| Reddit 首帖 | 50-100 | 1-3 天 |
| HN 首页 | 200-500 | 3-7 天 |
| GitHub Trending | 500+ | 1-2 周 |
| 1000 Stars | 1000 | 1-2 月 |

---

## 注意事项

1. **GIF 必须小于 5MB** — GitHub README 限制
2. **英文为主** — GitHub 80% 流量来自英文圈
3. **回复每条评论** — 社区互动是增长的关键
4. **不要同时发所有平台** — 分散发会导致每个平台都没热度
5. **选择发布时间** — Reddit/HN 最佳时间是美东工作日上午

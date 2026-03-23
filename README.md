# Hook Hero Bar

macOS menu bar status item that shows your Claude Code agent metrics at a glance.

```
● 6 | $93.20
```

Green dot = active sessions. Click to expand detailed metrics.

![Menu Bar](https://img.shields.io/badge/macOS-menu%20bar-blue)

## What It Shows

**Menu bar:** `● [sessions] | [cost]`

**Dropdown (click to open):**
- Sessions (total + open count)
- Cost (total USD today)
- Prompts (total today)
- Tokens (input / output / cache)
- Git activity (commits, files changed)
- Per-session breakdown (project, duration, cost)

## Requirements

- macOS 13+
- Swift 5.9+ (Xcode Command Line Tools)
- [Hook Hero](https://github.com/damahua/claude-code-hook-hero) installed as a Claude Code plugin (on the `feature/menubar-status` branch until merged)

## Install

```bash
git clone https://github.com/damahua/hook-hero-bar.git
cd hook-hero-bar
swift build -c release
cp .build/release/HookHeroBar /usr/local/bin/
```

## Run

```bash
HookHeroBar
```

No dock icon — runs as a background app. The menu bar item appears immediately.

To launch at login, add `HookHeroBar` to System Settings > General > Login Items.

## How It Works

Hook Hero (Claude Code plugin) writes `~/.claude/hook-hero/status.json` whenever hook events fire (session start/end, prompts, AI turns). This app watches that file with FSEvents and updates the menu bar display in real time.

```
Claude Code hooks → Hook Hero writes status.json → Hook Hero Bar reads & displays
```

Zero IPC, zero networking — just a JSON file on disk.

## Architecture

```
Sources/HookHeroBar/
├── main.swift              — Entry point, no dock icon
├── AppDelegate.swift       — Starts file watcher + menu bar
├── StatusModel.swift       — Codable structs for status.json
├── StatusFileWatcher.swift — FSEvents-based file watcher
├── MenuBarController.swift — NSStatusItem + popover
└── DropdownView.swift      — SwiftUI dropdown with metrics
```

## Status File Schema

See [`config/status-schema.json`](https://github.com/damahua/claude-code-hook-hero/blob/feature/menubar-status/config/status-schema.json) in the Hook Hero repo for the full JSON Schema.

## License

MIT

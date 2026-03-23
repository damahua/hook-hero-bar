# Hook Hero Bar

macOS menu bar status item that shows your Claude Code agent metrics at a glance.

```
● 6 | 22m | $137.1
```

Green dot = open sessions. Click to expand detailed metrics.

## What It Shows

**Menu bar:** `● [open sessions] | [time] | [cost]`

- Green dot `●` — sessions are open
- Gray dot `●` — no open sessions
- Time — total wall-clock session time today
- Cost — total USD spent today

**Dropdown (click to open):**
- Sessions (total + open count)
- Cost (total USD today)
- Prompts (total today)
- Tokens (input / output / cache)
- Git activity (commits, files changed)
- Open sessions breakdown (project, duration, cost)

## Prerequisites

1. **macOS 13 (Ventura) or later**

2. **Xcode Command Line Tools** (provides the Swift compiler)
   ```bash
   xcode-select --install
   ```
   Verify with: `swiftc -version` (should show Swift 5.9+)

3. **Hook Hero** — the Claude Code telemetry plugin that generates the data
   ```bash
   # Clone and install Hook Hero
   git clone https://github.com/damahua/claude-code-hook-hero.git
   cd claude-code-hook-hero
   npm install
   cd dashboard && npm install && npm link && cd ..
   claude plugin marketplace add "$(pwd)"
   claude plugin install hook-hero
   ```
   Verify with: `hook-hero live` (should show the dashboard)

4. **Claude Code** — the CLI tool that fires hook events
   - Hook Hero Bar only shows data when Claude Code sessions are running or have run today

## Install

```bash
git clone https://github.com/damahua/hook-hero-bar.git
cd hook-hero-bar
swift build -c release
```

Optionally copy to your PATH:
```bash
cp .build/release/HookHeroBar /usr/local/bin/
```

## Run

```bash
# If installed to PATH:
HookHeroBar

# Or run directly from the build:
cd hook-hero-bar
.build/debug/HookHeroBar
```

- No dock icon — runs as a background app
- The menu bar item appears immediately (right side, near the clock)
- If no `status.json` exists yet, it shows `● 0 | 0m | $0.00` until the first Claude Code session fires a hook

## Stop

```bash
pkill HookHeroBar
```

## Launch at Login

To start automatically when you log in:

1. Open **System Settings > General > Login Items**
2. Click **+** and add the `HookHeroBar` binary (either from `/usr/local/bin/` or `.build/release/`)

## Troubleshooting

### Menu bar shows all zeros

The data file hasn't been generated yet. Start a Claude Code session (or interact with an existing one) — the hooks will write `~/.claude/hook-hero/status.json` automatically.

To force an immediate write:
```bash
cd /path/to/claude-code-hook-hero
node --input-type=module -e "
  import { writeStatus } from './lib/write-status.mjs';
  import { SessionStore } from './lib/session-store.mjs';
  const store = new SessionStore();
  writeStatus(store);
"
```

### Menu bar item doesn't appear

- Check if the app is running: `pgrep -l HookHeroBar`
- Some menu bar managers (Bartender, Hidden Bar) may hide new items — check their settings
- Try quitting other menu bar apps to free space

### Numbers don't match `hook-hero live` dashboard

The menu bar and dashboard use slightly different computation methods. Small differences (~5%) are expected. Large gaps may indicate the plugin cache is stale:
```bash
# Reinstall the plugin to refresh the cache
claude plugin uninstall hook-hero
claude plugin marketplace remove hook-hero
claude plugin marketplace add /path/to/claude-code-hook-hero
claude plugin install hook-hero

# Install dependencies in cache
npm install --prefix ~/.claude/plugins/cache/hook-hero/hook-hero/1.0.0
```

### `ERR_MODULE_NOT_FOUND: @msgpack/msgpack`

The plugin cache is missing dependencies. Fix with:
```bash
npm install --prefix ~/.claude/plugins/cache/hook-hero/hook-hero/1.0.0
```

### Swift build fails with SDK version mismatch

Your Swift compiler doesn't match the macOS SDK. Update Command Line Tools:
```bash
softwareupdate --list
# Find and install the Command Line Tools update:
softwareupdate --install "Command Line Tools for Xcode <version>"
```

## How It Works

Hook Hero (Claude Code plugin) writes `~/.claude/hook-hero/status.json` whenever hook events fire (session start/end, prompts, AI turns). This app watches that file with FSEvents and updates the menu bar display in real time.

```
Claude Code hooks → Hook Hero writes status.json → Hook Hero Bar reads & displays
```

Zero IPC, zero networking — just a JSON file on disk.

### Update frequency

The menu bar updates whenever a hook event fires:
- `SessionStart` — new session opens
- `SessionEnd` — session closes
- `Stop` — AI finishes a turn (cost/token updates)
- `UserPromptSubmit` — you send a prompt

Between events, the display stays static. During long AI turns, numbers may be a few minutes stale.

### Data resets at midnight

The app compares the `updated_at` timestamp against the current date. When a new day starts, it resets to zeros until the first hook event of the day.

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

See [`config/status-schema.json`](https://github.com/damahua/claude-code-hook-hero/blob/master/config/status-schema.json) in the Hook Hero repo for the full JSON Schema.

## License

MIT

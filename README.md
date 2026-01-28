# MoltbotWidgets

macOS desktop widgets for monitoring your Moltbot gateway.

## Widgets

- **Cron Jobs** - Shows scheduled task count and scheduler status
- **Health** - Gateway status, uptime, version, and channel connectivity
- **Usage** - 30-day API costs and token usage

## Requirements

- macOS 14.0+
- Moltbot gateway running locally or remotely

## Installation

### Homebrew

```bash
brew install --cask 851-labs/tap/moltbot-widgets
```

### Manual

1. Download `MoltbotWidgets.dmg` from the [latest release](https://github.com/851-labs/MoltbotWidgets/releases/latest)
2. Open the DMG and drag MoltbotWidgets to Applications
3. Launch MoltbotWidgets from Applications
4. Configure your gateway connection:
   - **Host**: `127.0.0.1` (default for local)
   - **Port**: `18789` (default)
   - **Token**: Found in `~/.clawdbot/clawdbot.json` under `gateway.auth.token`
5. Click "Connect to Moltbot"
6. Add widgets to your desktop via Notification Center

Widgets automatically read the gateway token from `~/.clawdbot/clawdbot.json` if available.

## Building from Source

```bash
git clone https://github.com/851-labs/MoltbotWidgets.git
cd MoltbotWidgets
open MoltbotWidgets.xcodeproj
# Build and run with ⌘R
```

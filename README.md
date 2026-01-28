# MoltbotWidgets

macOS desktop widgets for monitoring your Moltbot gateway.

## Widgets

- **Cron Jobs** - Shows scheduled task count and scheduler status
- **Health** - Gateway status, uptime, version, and channel connectivity
- **Usage** - 30-day API costs and token usage

## Requirements

- macOS 14.0+
- Moltbot gateway running locally or remotely

## Setup

1. Clone and open in Xcode:
   ```bash
   git clone https://github.com/851-labs/MoltbotWidgets.git
   open MoltbotWidgets.xcodeproj
   ```

2. Build and run (⌘R)

3. Enter your gateway connection details:
   - **Host**: `127.0.0.1` (default for local)
   - **Port**: `18789` (default)
   - **Token**: Found in `~/.clawdbot/clawdbot.json` under `gateway.auth.token`

4. Click "Connect to Moltbot"

5. Add widgets to your desktop via Notification Center

## Widget Configuration

Widgets read the gateway token directly from `~/.clawdbot/clawdbot.json` if available. For remote gateways, configure the connection in the app first.

## Development

```bash
# Build from command line
xcodebuild -scheme MoltbotWidgets -configuration Debug build
```

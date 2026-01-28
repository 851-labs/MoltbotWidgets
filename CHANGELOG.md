# Changelog

## 0.2.0

**Custom Widgets** - Create dynamic widgets that fetch real-time data from any API endpoint.

- **Custom Widget** - Display data from any URL returning widget-schema JSON
- **CLI Tool** (`moltbot-widgets`) - Create, list, update, delete, and validate widgets
- **Moltbot Skill** - Enable Moltbot to create widgets via `moltbot-widgets skill install`
- **Widget Templates** - 5 widget types: status, number, gauge, list, text
- **Authentication** - Support for headers, basic auth, and query parameters
- **JSON Schema** - Full schema specification at `schema/widget.v1.json`

## 0.1.2

- Add app icon
- Fix cost text truncation in Usage widget

## 0.1.1

- Fix widgets not sharing settings with main app (re-enable App Groups)
- Fix widget extension registration for Homebrew installs

## 0.1.0

Initial release.

- **Cron Jobs Widget** - Monitor scheduled task count and scheduler status
- **Health Widget** - View gateway status, uptime, version, and channel connectivity
- **Usage Widget** - Track 30-day API costs and token usage
- macOS Settings-style configuration UI
- Automatic gateway token detection from `~/.clawdbot/clawdbot.json`

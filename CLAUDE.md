# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build debug (Xcode)
xcodebuild -scheme MoltbotWidgets -configuration Debug build

# Build CLI (Swift Package Manager)
swift build

# Build release archive
xcodebuild -project MoltbotWidgets.xcodeproj \
  -scheme MoltbotWidgets \
  -configuration Release \
  -archivePath build/MoltbotWidgets.xcarchive \
  archive

# Export for distribution (requires provisioning profiles)
xcodebuild -exportArchive \
  -archivePath build/MoltbotWidgets.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

# Create DMG
hdiutil create -volname "MoltbotWidgets" \
  -srcfolder build/export/MoltbotWidgets.app \
  -ov -format UDZO \
  build/MoltbotWidgets.dmg
```

## Release Process

1. **Bump version** in `project.pbxproj` (search for `MARKETING_VERSION`)
2. **Update CHANGELOG.md**
3. **Commit and push**
4. **Tag and push** to trigger CI:
   ```bash
   git tag v0.1.2 && git push origin v0.1.2
   ```
5. **Wait for GitHub Actions** to build, notarize, and publish the release
6. **Update Homebrew tap** (`851-labs/homebrew-tap`):
   ```bash
   # Get SHA256 of new DMG
   curl -sL "https://github.com/851-labs/MoltbotWidgets/releases/download/v0.1.2/MoltbotWidgets.dmg" | shasum -a 256

   # Edit Casks/moltbot-widgets.rb - update version and sha256
   # Commit and push to homebrew-tap repo
   ```

## Architecture

### Three Targets
- **MoltbotWidgets** (app) - Main macOS app with settings UI
- **MoltbotWidgetsExtension** (widget) - WidgetKit extension with 4 widgets (Cron, Health, Usage, Custom)
- **MoltbotWidgetsCLI** (cli) - Swift Argument Parser CLI for managing custom widgets

### Shared Code (`Shared/`)
Both app and extension share:
- `MoltbotAPI.swift` - Actor-based WebSocket RPC client for Moltbot gateway
- `SharedSettings.swift` - Configuration via App Groups (`group.com.moltbot.widgets`)
- `WidgetConfig.swift` - Custom widget configuration model
- `WidgetConfigStore.swift` - Persistence for custom widget configs
- `WidgetResponse.swift` - Widget JSON response models (status, number, gauge, list, text)
- `WidgetFetcher.swift` - HTTP client for fetching widget data

### Data Flow
1. User configures connection in main app (host, port, token)
2. App saves to shared UserDefaults via App Groups
3. Widgets read from shared UserDefaults independently
4. Each widget creates its own `MoltbotAPI` instance per refresh

### API Protocol
WebSocket RPC with custom handshake:
1. Server sends `connect.challenge`
2. Client sends `connect` request with auth token
3. Client sends method request (e.g., `cron.status`, `health`, `usage.cost`)
4. Connection closes after response

### Widget Refresh
- Cron Jobs & Health: 5 minutes
- Usage: 15 minutes
- Custom: User-configurable (1-60 minutes)

## Key Files

- `ExportOptions.plist` - Developer ID export with provisioning profile mapping
- `.github/workflows/release.yml` - CI/CD: archive, export, DMG, notarize, staple, GitHub release
- `Package.swift` - Swift Package Manager manifest for CLI
- `MoltbotWidgetsCLI/` - CLI commands (create, list, update, delete, validate, refresh, schema, skill)
- `MoltbotWidgetsExtension/Templates/` - SwiftUI template views for custom widget types
- `schema/widget.v1.json` - JSON Schema for widget API responses
- `skills/moltbot-widgets/SKILL.md` - Moltbot skill definition

## Entitlements

Both targets require:
- `com.apple.security.app-sandbox`
- `com.apple.security.application-groups` (group.com.moltbot.widgets)
- `com.apple.security.network.client`

## CI Secrets Required

- `DEVELOPER_ID_CERT_P12` / `DEVELOPER_ID_CERT_PASSWORD`
- `DEVELOPER_ID_APPLICATION`
- `PROVISIONING_PROFILE_APP` / `PROVISIONING_PROFILE_EXTENSION` (base64-encoded)
- `APP_STORE_CONNECT_KEY_ID` / `APP_STORE_CONNECT_ISSUER_ID` / `APP_STORE_CONNECT_PRIVATE_KEY`

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build debug
xcodebuild -scheme MoltbotWidgets -configuration Debug build

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

Push a tag matching `v*` pattern to trigger the GitHub Actions release workflow:
```bash
git tag v0.1.2 && git push origin v0.1.2
```

After release, update the Homebrew tap (`851-labs/homebrew-tap`) with new version and SHA256.

## Architecture

### Two Targets
- **MoltbotWidgets** (app) - Main macOS app with settings UI
- **MoltbotWidgetsExtension** (widget) - WidgetKit extension with 3 widgets

### Shared Code (`Shared/`)
Both targets share:
- `MoltbotAPI.swift` - Actor-based WebSocket RPC client for Moltbot gateway
- `SharedSettings.swift` - Configuration via App Groups (`group.com.moltbot.widgets`)

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

## Key Files

- `ExportOptions.plist` - Developer ID export with provisioning profile mapping
- `.github/workflows/release.yml` - CI/CD: archive, export, DMG, notarize, staple, GitHub release

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

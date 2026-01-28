import ArgumentParser
import Foundation

struct SkillCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "skill",
        abstract: "Manage Moltbot skill integration",
        subcommands: [
            SkillInstallCommand.self,
            SkillUninstallCommand.self,
            SkillStatusCommand.self,
        ],
        defaultSubcommand: SkillStatusCommand.self
    )
}

// MARK: - Install

struct SkillInstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install the Moltbot skill"
    )

    func run() throws {
        Output.info("Installing moltbot-widgets skill...")

        // Find Moltbot skills directory
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let clawdbotPath = homeDir.appendingPathComponent(".clawdbot")
        let moltbotPath = homeDir.appendingPathComponent(".moltbot")

        let basePath: URL
        if FileManager.default.fileExists(atPath: clawdbotPath.path) {
            basePath = clawdbotPath
            Output.success("Detected Moltbot config at ~/.clawdbot")
        } else if FileManager.default.fileExists(atPath: moltbotPath.path) {
            basePath = moltbotPath
            Output.success("Detected Moltbot config at ~/.moltbot")
        } else {
            // Create .moltbot directory
            try FileManager.default.createDirectory(at: moltbotPath, withIntermediateDirectories: true)
            basePath = moltbotPath
            Output.success("Created ~/.moltbot directory")
        }

        let skillsDir = basePath.appendingPathComponent("skills/moltbot-widgets")
        let skillPath = skillsDir.appendingPathComponent("SKILL.md")

        // Create skills directory
        try FileManager.default.createDirectory(at: skillsDir, withIntermediateDirectories: true)

        // Write skill file
        try skillContent.write(to: skillPath, atomically: true, encoding: .utf8)

        Output.success("Created \(skillPath.path)")
        print("")
        Output.info("Skill installed! Moltbot can now help you create widgets.")
        print("")
        Output.info("Try asking: \"Create a widget that shows my server status\"")
    }
}

// MARK: - Uninstall

struct SkillUninstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall the Moltbot skill"
    )

    func run() throws {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser

        // Check both possible locations
        let paths = [
            homeDir.appendingPathComponent(".clawdbot/skills/moltbot-widgets"),
            homeDir.appendingPathComponent(".moltbot/skills/moltbot-widgets"),
        ]

        var removed = false
        for path in paths {
            if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.removeItem(at: path)
                Output.success("Removed \(path.path)")
                removed = true
            }
        }

        if removed {
            Output.info("Skill uninstalled.")
        } else {
            Output.warning("Skill was not installed.")
        }
    }
}

// MARK: - Status

struct SkillStatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Check skill installation status"
    )

    func run() throws {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser

        let clawdbotSkill = homeDir.appendingPathComponent(".clawdbot/skills/moltbot-widgets/SKILL.md")
        let moltbotSkill = homeDir.appendingPathComponent(".moltbot/skills/moltbot-widgets/SKILL.md")

        if FileManager.default.fileExists(atPath: clawdbotSkill.path) {
            Output.success("Skill installed at ~/.clawdbot/skills/moltbot-widgets/")
        } else if FileManager.default.fileExists(atPath: moltbotSkill.path) {
            Output.success("Skill installed at ~/.moltbot/skills/moltbot-widgets/")
        } else {
            Output.warning("Skill not installed")
            Output.info("")
            Output.info("Install with: moltbot-widgets skill install")
        }
    }
}

// MARK: - Embedded Skill Content

private let skillContent = """
---
name: moltbot-widgets
description: Create and manage dynamic macOS desktop widgets that display real-time data from any URL/API endpoint. Use this when the user wants to create widgets, monitor APIs, display live data on their desktop, or asks about desktop widgets.
---

# Moltbot Widgets

Create dynamic macOS widgets that fetch and display data from any API endpoint.

## When to Use This Skill

Use this skill when the user:
- Wants to create a desktop widget
- Asks to monitor an API or service on their desktop
- Wants to display live data (build status, server health, metrics, etc.)
- Mentions dashboard, widget, or desktop monitoring

## Prerequisites

The user must have MoltbotWidgets installed:
```bash
brew install --cask 851-labs/tap/moltbot-widgets
```

## Creating Widgets

Widgets fetch JSON from a URL at a configurable interval. The JSON must match the widget schema.

### Command Format

```bash
moltbot-widgets create \\
  --name "<display name>" \\
  --url "<api endpoint>" \\
  [--header "Key: Value"] \\
  [--basic-auth "user:pass"] \\
  [--query "key=value"] \\
  --interval <minutes>
```

### Authentication Options

```bash
--header "Authorization: Bearer token"  # HTTP header (can repeat)
--basic-auth "username:password"        # Basic authentication
--query "api_key=xyz123"                # Query parameter (can repeat)
```

## Widget Types

The API endpoint must return JSON with `type` and `data` fields:

### Status Widget
Best for: service status, build results, alerts
```json
{
  "type": "status",
  "data": {
    "icon": "checkmark.circle.fill",
    "iconColor": "green",
    "title": "API Server",
    "subtitle": "us-east-1",
    "value": "Healthy",
    "footer": "Updated 2 min ago"
  }
}
```
Required: `title`

### Number Widget
Best for: metrics, counts, KPIs
```json
{
  "type": "number",
  "data": {
    "icon": "arrow.triangle.pull",
    "iconColor": "purple",
    "value": 12,
    "unit": "PRs",
    "label": "Open Pull Requests",
    "trend": "up",
    "trendValue": "+3"
  }
}
```
Required: `value`

### Gauge Widget
Best for: percentages, progress, utilization
```json
{
  "type": "gauge",
  "data": {
    "value": 73,
    "max": 100,
    "label": "CPU Usage",
    "color": "orange",
    "showPercentage": true
  }
}
```
Required: `value`, `max`

### List Widget
Best for: recent items, top N, activity feeds
```json
{
  "type": "list",
  "data": {
    "title": "Recent Deploys",
    "items": [
      { "icon": "checkmark.circle.fill", "iconColor": "green", "title": "v2.3.1", "subtitle": "10 min ago" },
      { "icon": "xmark.circle.fill", "iconColor": "red", "title": "v2.3.0", "value": "Failed" }
    ]
  }
}
```
Required: `items` (each item requires `title`)

### Text Widget
Best for: messages, notes, announcements
```json
{
  "type": "text",
  "data": {
    "title": "Daily Standup",
    "body": "Working on the widgets feature. Should be done by EOD.",
    "footer": "Updated 5 min ago"
  }
}
```
Required: `body`

## Available Colors

`red`, `orange`, `yellow`, `green`, `mint`, `teal`, `cyan`, `blue`, `indigo`, `purple`, `pink`, `brown`, `gray`, `primary`, `secondary`, or hex `#RRGGBB`

## Available Icons

Any SF Symbol name (e.g., `checkmark.circle.fill`, `server.rack`, `arrow.up.right`)
Browse at: https://developer.apple.com/sf-symbols/

## Other Commands

```bash
# List all widgets
moltbot-widgets list

# Update widget configuration
moltbot-widgets update <id> --interval 10
moltbot-widgets update <id> --name "New Name"

# Delete widget
moltbot-widgets delete <id>

# Validate URL without creating
moltbot-widgets validate "https://api.example.com/widget"

# Force refresh all widgets
moltbot-widgets refresh
```

## Example Workflow

User: "Create a widget that shows my GitHub PR count"

1. First, check if the user has an API endpoint that returns widget JSON
2. If they don't have one, help them create a simple server or use a service
3. Create the widget:

```bash
moltbot-widgets create \\
  --name "GitHub PRs" \\
  --url "https://your-api.com/github/prs-widget" \\
  --header "Authorization: Bearer $GITHUB_TOKEN" \\
  --interval 15
```

4. Tell user to add the widget:
   - Right-click desktop → Edit Widgets
   - Find MoltbotWidgets → Custom Widget
   - Add widget, click to configure, select "GitHub PRs"

## Troubleshooting

If widget creation fails:
1. Check the URL is accessible: `curl -s <url> | jq`
2. Validate schema: `moltbot-widgets validate <url>`
3. Review error messages for specific field issues
4. Ensure JSON has both `type` and `data` fields
"""

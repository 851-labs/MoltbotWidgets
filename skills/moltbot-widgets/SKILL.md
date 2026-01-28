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
moltbot-widgets create \
  --name "<display name>" \
  --url "<api endpoint>" \
  [--header "Key: Value"] \
  [--basic-auth "user:pass"] \
  [--query "key=value"] \
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
moltbot-widgets create \
  --name "GitHub PRs" \
  --url "https://your-api.com/github/prs-widget" \
  --header "Authorization: Bearer $GITHUB_TOKEN" \
  --interval 15
```

4. Tell user to add the widget:
   - Right-click desktop → Edit Widgets
   - Find MoltbotWidgets → Custom Widget
   - Add widget, click to configure, select "GitHub PRs"

## Creating a Simple Widget API

If the user needs help creating an endpoint, here's a minimal example:

### Node.js/Express
```javascript
app.get('/widget', (req, res) => {
  res.json({
    type: 'number',
    data: {
      icon: 'star.fill',
      iconColor: 'yellow',
      value: 42,
      label: 'Stars'
    }
  });
});
```

### Python/Flask
```python
@app.route('/widget')
def widget():
    return {
        'type': 'status',
        'data': {
            'icon': 'checkmark.circle.fill',
            'iconColor': 'green',
            'title': 'Service',
            'value': 'Online'
        }
    }
```

## Troubleshooting

If widget creation fails:
1. Check the URL is accessible: `curl -s <url> | jq`
2. Validate schema: `moltbot-widgets validate <url>`
3. Review error messages for specific field issues
4. Ensure JSON has both `type` and `data` fields
5. Check that required fields are present for the widget type

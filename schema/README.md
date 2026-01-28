# Widget Schema Documentation

Your API endpoint should return JSON matching this schema. The widget will poll your endpoint at the configured interval and render the response.

**Schema URL:** `https://raw.githubusercontent.com/851-labs/MoltbotWidgets/main/schema/widget.v1.json`

## Response Format

```json
{
  "$schema": "https://raw.githubusercontent.com/851-labs/MoltbotWidgets/main/schema/widget.v1.json",
  "type": "<widget-type>",
  "data": { ... }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `$schema` | No | Schema URL for validation |
| `type` | Yes | Widget type: `status`, `number`, `gauge`, `list`, `text` |
| `data` | Yes | Widget data (shape depends on type) |

---

## Widget Types

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
    "footer": "99.9% uptime"
  }
}
```

| Field | Required | Type | Max Length | Description |
|-------|----------|------|------------|-------------|
| `title` | Yes | string | 50 | Main title |
| `icon` | No | SF Symbol | - | Icon name |
| `iconColor` | No | color | - | Icon color |
| `subtitle` | No | string | 100 | Secondary text |
| `value` | No | string | 20 | Status value |
| `footer` | No | string | 50 | Footer text |

---

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

| Field | Required | Type | Max Length | Description |
|-------|----------|------|------------|-------------|
| `value` | Yes | string/number | - | The number |
| `icon` | No | SF Symbol | - | Icon name |
| `iconColor` | No | color | - | Icon color |
| `unit` | No | string | 10 | Unit label |
| `label` | No | string | 30 | Description |
| `trend` | No | enum | - | `up`, `down`, `neutral` |
| `trendValue` | No | string | 10 | Trend text |

---

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

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `value` | Yes | number | Current value |
| `max` | Yes | number | Maximum value |
| `label` | No | string (max 30) | Label text |
| `color` | No | color | Gauge color |
| `showPercentage` | No | boolean | Show % in center (default: true) |

---

### List Widget

Best for: recent items, top N, activity feeds

```json
{
  "type": "list",
  "data": {
    "title": "Recent Deploys",
    "items": [
      {
        "icon": "checkmark.circle.fill",
        "iconColor": "green",
        "title": "v2.3.1",
        "subtitle": "10 min ago"
      },
      {
        "icon": "xmark.circle.fill",
        "iconColor": "red",
        "title": "v2.3.0",
        "subtitle": "Yesterday",
        "value": "Failed"
      }
    ]
  }
}
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `items` | Yes | array | List items (max 5) |
| `title` | No | string (max 30) | List title |

**Item fields:**

| Field | Required | Type | Max Length | Description |
|-------|----------|------|------------|-------------|
| `title` | Yes | string | 50 | Item title |
| `icon` | No | SF Symbol | - | Item icon |
| `iconColor` | No | color | - | Icon color |
| `subtitle` | No | string | 50 | Item subtitle |
| `value` | No | string | 15 | Right-side value |

---

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

| Field | Required | Type | Max Length | Description |
|-------|----------|------|------------|-------------|
| `body` | Yes | string | 280 | Main text |
| `title` | No | string | 30 | Title |
| `footer` | No | string | 50 | Footer |

---

## Colors

### Named Colors

`red`, `orange`, `yellow`, `green`, `mint`, `teal`, `cyan`, `blue`, `indigo`, `purple`, `pink`, `brown`, `gray`, `primary`, `secondary`

### Hex Colors

Any hex color in `#RRGGBB` format, e.g., `#22c55e`, `#ef4444`

---

## Icons

Use any [SF Symbol](https://developer.apple.com/sf-symbols/) name.

**Common examples:**
- Status: `checkmark.circle.fill`, `xmark.circle.fill`, `exclamationmark.triangle.fill`
- Server: `server.rack`, `network`, `antenna.radiowaves.left.and.right`
- Code: `hammer.fill`, `arrow.triangle.pull`, `arrow.triangle.branch`
- Charts: `chart.bar.fill`, `chart.line.uptrend.xyaxis`, `gauge.medium`
- General: `star.fill`, `bell.fill`, `person.fill`

Browse all symbols: https://developer.apple.com/sf-symbols/

---

## Validation

Use `moltbot-widgets validate <url>` to check your endpoint returns valid JSON:

```bash
$ moltbot-widgets validate "https://api.example.com/widget"

Fetching https://api.example.com/widget...
✓ Valid "status" widget response
```

If validation fails, you'll see specific error messages:

```bash
Schema errors:
  • data.title is required
  • data.iconColor: "greenish" is not a valid color
```

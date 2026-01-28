import ArgumentParser
import Foundation

struct SchemaCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schema",
        abstract: "Show widget schema documentation"
    )

    @Option(name: .long, help: "Show schema for specific type (status, number, gauge, list, text)")
    var type: String?

    @Flag(name: .long, help: "Output raw JSON schema")
    var json: Bool = false

    func run() throws {
        if json {
            printJSONSchema()
            return
        }

        if let type = type {
            printTypeSchema(type)
            return
        }

        printFullDocumentation()
    }

    private func printFullDocumentation() {
        print("""
        Widget Schema Documentation
        ===========================

        Your API endpoint should return JSON matching this schema.

        Schema URL: https://raw.githubusercontent.com/851-labs/MoltbotWidgets/main/schema/widget.v1.json

        Response Format
        ---------------
        {
          "type": "<widget-type>",
          "data": { ... }
        }

        Widget Types
        ------------
        • status  - Service status, build results, alerts
        • number  - Metrics, counts, KPIs
        • gauge   - Percentages, progress, utilization
        • list    - Recent items, activity feeds
        • text    - Messages, notes, announcements

        Use --type <type> for detailed schema of each type.

        Colors
        ------
        Named: red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray
        Hex:   #RRGGBB (e.g., #22c55e)

        Icons
        -----
        Any SF Symbol name (e.g., checkmark.circle.fill, server.rack)
        Browse: https://developer.apple.com/sf-symbols/
        """)
    }

    private func printTypeSchema(_ typeName: String) {
        switch typeName.lowercased() {
        case "status":
            print("""
            Status Widget
            =============

            Best for: service status, build results, alerts

            Example:
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

            Fields:
            • title      (required)  string, max 50 chars
            • icon       (optional)  SF Symbol name
            • iconColor  (optional)  color value
            • subtitle   (optional)  string, max 100 chars
            • value      (optional)  string, max 20 chars
            • footer     (optional)  string, max 50 chars
            """)

        case "number":
            print("""
            Number Widget
            =============

            Best for: metrics, counts, KPIs

            Example:
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

            Fields:
            • value       (required)  string or number
            • icon        (optional)  SF Symbol name
            • iconColor   (optional)  color value
            • unit        (optional)  string, max 10 chars
            • label       (optional)  string, max 30 chars
            • trend       (optional)  "up", "down", or "neutral"
            • trendValue  (optional)  string, max 10 chars
            """)

        case "gauge":
            print("""
            Gauge Widget
            ============

            Best for: percentages, progress, utilization

            Example:
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

            Fields:
            • value           (required)  number
            • max             (required)  number
            • label           (optional)  string, max 30 chars
            • color           (optional)  color value
            • showPercentage  (optional)  boolean, default true
            """)

        case "list":
            print("""
            List Widget
            ===========

            Best for: recent items, top N, activity feeds

            Example:
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

            Fields:
            • items  (required)  array, max 5 items
            • title  (optional)  string, max 30 chars

            Item Fields:
            • title     (required)  string, max 50 chars
            • icon      (optional)  SF Symbol name
            • iconColor (optional)  color value
            • subtitle  (optional)  string, max 50 chars
            • value     (optional)  string, max 15 chars
            """)

        case "text":
            print("""
            Text Widget
            ===========

            Best for: messages, notes, announcements

            Example:
            {
              "type": "text",
              "data": {
                "title": "Daily Standup",
                "body": "Working on the widgets feature. Should be done by EOD.",
                "footer": "Updated 5 min ago"
              }
            }

            Fields:
            • body    (required)  string, max 280 chars
            • title   (optional)  string, max 30 chars
            • footer  (optional)  string, max 50 chars
            """)

        default:
            Output.error("Unknown widget type: \(typeName)")
            Output.info("Valid types: status, number, gauge, list, text")
        }
    }

    private func printJSONSchema() {
        // Embedded JSON schema
        let schema = """
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$id": "https://raw.githubusercontent.com/851-labs/MoltbotWidgets/main/schema/widget.v1.json",
          "title": "Moltbot Widget Response",
          "type": "object",
          "required": ["type", "data"],
          "properties": {
            "type": {
              "type": "string",
              "enum": ["status", "number", "gauge", "list", "text"]
            },
            "data": {
              "type": "object"
            }
          }
        }
        """
        print(schema)
        print("")
        Output.info("Full schema: https://raw.githubusercontent.com/851-labs/MoltbotWidgets/main/schema/widget.v1.json")
    }
}

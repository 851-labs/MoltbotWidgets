import ArgumentParser
import Foundation

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all configured widgets",
        aliases: ["ls"]
    )

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    func run() throws {
        let widgets = WidgetConfigStore.loadWidgets()

        if json {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(widgets)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
            return
        }

        if widgets.isEmpty {
            Output.info("No widgets configured.")
            Output.info("")
            Output.info("Create one with:")
            Output.info("  moltbot-widgets create --name \"My Widget\" --url \"https://...\" --interval 5")
            return
        }

        Output.info("Configured widgets:")
        Output.info("")

        for widget in widgets {
            let authType = authTypeString(widget.auth)
            print("  \(widget.name)")
            print("    ID:       \(widget.id)")
            print("    URL:      \(widget.url)")
            print("    Auth:     \(authType)")
            print("    Interval: \(widget.intervalMinutes) min")
            print("")
        }

        Output.info("Total: \(widgets.count) widget(s)")
    }

    private func authTypeString(_ auth: WidgetAuth?) -> String {
        guard let auth = auth else { return "None" }
        switch auth {
        case .header(let headers):
            return "Headers (\(headers.count))"
        case .basic:
            return "Basic Auth"
        case .query(let params):
            return "Query Params (\(params.count))"
        }
    }
}

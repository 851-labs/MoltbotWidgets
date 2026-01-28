import ArgumentParser
import Foundation

struct CreateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new widget from a URL"
    )

    @Option(name: .long, help: "Display name for the widget")
    var name: String

    @Option(name: .long, help: "URL to fetch widget data from")
    var url: String

    @Option(name: .long, help: "HTTP header (format: 'Key: Value'). Can be repeated.")
    var header: [String] = []

    @Option(name: .long, help: "Basic authentication (format: 'username:password')")
    var basicAuth: String?

    @Option(name: .long, help: "Query parameter (format: 'key=value'). Can be repeated.")
    var query: [String] = []

    @Option(name: .long, help: "Refresh interval in minutes")
    var interval: Int = 5

    mutating func run() async throws {
        Output.info("Fetching \(url)...")

        // Build auth config
        let auth = WidgetAuth.from(
            headers: header,
            basicAuth: basicAuth,
            queryParams: query
        )

        // Validate URL by fetching
        do {
            let (_, response) = try await WidgetFetcher.fetchRaw(url: url, auth: auth)
            Output.success("Valid \"\(response.type.rawValue)\" widget response")
        } catch let error as WidgetFetchError {
            Output.error("Failed to fetch URL")
            Output.error(error.localizedDescription)
            throw ExitCode.failure
        } catch {
            Output.error("Failed to fetch URL: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        // Create widget config
        let widget = CustomWidgetConfig(
            name: name,
            url: url,
            auth: auth,
            intervalMinutes: interval
        )

        // Save
        do {
            try WidgetConfigStore.addWidget(widget)
        } catch let error as WidgetConfigError {
            Output.error(error.localizedDescription)
            throw ExitCode.failure
        } catch {
            Output.error("Failed to save: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        print("")
        Output.success("Created widget \"\(name)\"")
        Output.info("  ID:       \(widget.id)")
        Output.info("  URL:      \(url)")
        Output.info("  Interval: \(interval) minutes")
        print("")
        Output.info("To add to your desktop:")
        Output.info("  1. Right-click desktop → Edit Widgets")
        Output.info("  2. Find \"MoltbotWidgets\" → \"Custom Widget\"")
        Output.info("  3. Add widget, then click to select \"\(name)\"")
    }
}

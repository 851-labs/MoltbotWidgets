import ArgumentParser
import Foundation

struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a widget configuration"
    )

    @Argument(help: "Widget ID or name")
    var identifier: String

    @Option(name: .long, help: "New display name")
    var name: String?

    @Option(name: .long, help: "New URL")
    var url: String?

    @Option(name: .long, help: "HTTP header (format: 'Key: Value'). Can be repeated.")
    var header: [String] = []

    @Option(name: .long, help: "Basic authentication (format: 'username:password')")
    var basicAuth: String?

    @Option(name: .long, help: "Query parameter (format: 'key=value'). Can be repeated.")
    var query: [String] = []

    @Option(name: .long, help: "New refresh interval in minutes")
    var interval: Int?

    @Flag(name: .long, help: "Remove authentication")
    var removeAuth: Bool = false

    mutating func run() async throws {
        // Find widget
        guard var widget = WidgetConfigStore.getWidget(id: identifier)
                ?? WidgetConfigStore.getWidget(name: identifier) else {
            Output.error("Widget not found: \(identifier)")
            throw ExitCode.failure
        }

        // Track changes
        var changes: [String] = []

        // Update name
        if let newName = name {
            widget.name = newName
            changes.append("name → \(newName)")
        }

        // Update URL
        if let newURL = url {
            widget.url = newURL
            changes.append("url → \(newURL)")
        }

        // Update interval
        if let newInterval = interval {
            widget.intervalMinutes = newInterval
            changes.append("interval → \(newInterval) min")
        }

        // Update auth
        if removeAuth {
            widget.auth = nil
            changes.append("auth → removed")
        } else {
            let newAuth = WidgetAuth.from(
                headers: header,
                basicAuth: basicAuth,
                queryParams: query
            )
            if newAuth != nil {
                widget.auth = newAuth
                changes.append("auth → updated")
            }
        }

        if changes.isEmpty {
            Output.warning("No changes specified")
            return
        }

        // Validate URL if changed
        if url != nil {
            Output.info("Validating new URL...")
            do {
                _ = try await WidgetFetcher.fetchRaw(url: widget.url, auth: widget.auth)
                Output.success("URL is valid")
            } catch {
                Output.error("Failed to validate URL: \(error.localizedDescription)")
                throw ExitCode.failure
            }
        }

        // Save
        do {
            try WidgetConfigStore.updateWidget(widget)
        } catch {
            Output.error("Failed to save: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        Output.success("Updated widget \"\(widget.name)\"")
        for change in changes {
            Output.info("  \(change)")
        }
    }
}

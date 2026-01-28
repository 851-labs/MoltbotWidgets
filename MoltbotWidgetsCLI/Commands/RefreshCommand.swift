import ArgumentParser
import Foundation
import WidgetKit

struct RefreshCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "refresh",
        abstract: "Force refresh widgets"
    )

    @Argument(help: "Widget ID to refresh (optional, refreshes all if omitted)")
    var identifier: String?

    func run() throws {
        if let identifier = identifier {
            // Verify widget exists
            guard let widget = WidgetConfigStore.getWidget(id: identifier)
                    ?? WidgetConfigStore.getWidget(name: identifier) else {
                Output.error("Widget not found: \(identifier)")
                throw ExitCode.failure
            }

            Output.info("Refreshing widget \"\(widget.name)\"...")
        } else {
            Output.info("Refreshing all widgets...")
        }

        // Reload all widget timelines
        // Note: WidgetKit doesn't support refreshing specific widgets by ID
        WidgetCenter.shared.reloadAllTimelines()

        Output.success("Refresh requested")
        Output.info("Widgets will update on their next refresh cycle.")
    }
}

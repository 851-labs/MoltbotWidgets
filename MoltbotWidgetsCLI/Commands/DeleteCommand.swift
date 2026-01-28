import ArgumentParser
import Foundation

struct DeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a widget",
        aliases: ["rm", "remove"]
    )

    @Argument(help: "Widget ID or name")
    var identifier: String

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var yes: Bool = false

    func run() throws {
        // Find widget
        guard let widget = WidgetConfigStore.getWidget(id: identifier)
                ?? WidgetConfigStore.getWidget(name: identifier) else {
            Output.error("Widget not found: \(identifier)")
            throw ExitCode.failure
        }

        // Confirm unless --yes
        if !yes {
            print("Delete widget \"\(widget.name)\" (\(widget.id))? [y/N] ", terminator: "")
            guard let response = readLine()?.lowercased(),
                  response == "y" || response == "yes" else {
                Output.info("Cancelled")
                return
            }
        }

        // Delete
        do {
            try WidgetConfigStore.deleteWidget(id: widget.id)
        } catch {
            Output.error("Failed to delete: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        Output.success("Deleted widget \"\(widget.name)\"")
    }
}

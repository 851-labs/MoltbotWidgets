import ArgumentParser
import Foundation

struct ValidateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate a URL returns valid widget JSON"
    )

    @Argument(help: "URL to validate")
    var url: String

    @Option(name: .long, help: "HTTP header (format: 'Key: Value'). Can be repeated.")
    var header: [String] = []

    @Option(name: .long, help: "Basic authentication (format: 'username:password')")
    var basicAuth: String?

    @Option(name: .long, help: "Query parameter (format: 'key=value'). Can be repeated.")
    var query: [String] = []

    @Flag(name: .long, help: "Show raw JSON response")
    var showJson: Bool = false

    mutating func run() async throws {
        Output.info("Fetching \(url)...")

        let auth = WidgetAuth.from(
            headers: header,
            basicAuth: basicAuth,
            queryParams: query
        )

        do {
            let (data, response) = try await WidgetFetcher.fetchRaw(url: url, auth: auth)

            Output.success("Valid \"\(response.type.rawValue)\" widget response")

            if showJson {
                print("")
                if let jsonString = String(data: data, encoding: .utf8) {
                    // Pretty print the JSON
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(
                           withJSONObject: jsonObject,
                           options: [.prettyPrinted, .sortedKeys]
                       ),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        print(prettyString)
                    } else {
                        print(jsonString)
                    }
                }
            }

            // Show summary
            print("")
            Output.info("Widget type: \(response.type.rawValue)")
            printDataSummary(response)

        } catch let error as WidgetFetchError {
            switch error {
            case .invalidJSON(let message):
                Output.error("Invalid widget response")
                print("")
                Output.error("JSON parsing error:")
                Output.error("  \(message)")
                print("")
                Output.info("Schema: https://raw.githubusercontent.com/851-labs/MoltbotWidgets/main/schema/widget.v1.json")

            case .httpError(let statusCode):
                Output.error("HTTP error: \(statusCode)")

            default:
                Output.error(error.localizedDescription)
            }
            throw ExitCode.failure

        } catch {
            Output.error("Failed to fetch: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    private func printDataSummary(_ response: WidgetResponse) {
        switch response.data {
        case .status(let data):
            if let title = data.title as String? {
                Output.info("  title: \(title)")
            }
            if let value = data.value {
                Output.info("  value: \(value)")
            }

        case .number(let data):
            Output.info("  value: \(data.value.displayString)")
            if let label = data.label {
                Output.info("  label: \(label)")
            }

        case .gauge(let data):
            Output.info("  value: \(data.value) / \(data.max)")
            if let label = data.label {
                Output.info("  label: \(label)")
            }

        case .list(let data):
            Output.info("  items: \(data.items.count)")
            if let title = data.title {
                Output.info("  title: \(title)")
            }

        case .text(let data):
            if let title = data.title {
                Output.info("  title: \(title)")
            }
            let truncatedBody = data.body.prefix(50)
            Output.info("  body: \(truncatedBody)\(data.body.count > 50 ? "..." : "")")
        }
    }
}

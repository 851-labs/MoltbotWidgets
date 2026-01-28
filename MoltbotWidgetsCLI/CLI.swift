import ArgumentParser
import Foundation

@main
struct MoltbotWidgetsCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "moltbot-widgets",
        abstract: "Create and manage dynamic macOS widgets",
        version: "0.2.2",
        subcommands: [
            CreateCommand.self,
            ListCommand.self,
            UpdateCommand.self,
            DeleteCommand.self,
            ValidateCommand.self,
            RefreshCommand.self,
            SchemaCommand.self,
            SkillCommand.self,
        ],
        defaultSubcommand: ListCommand.self
    )
}

// MARK: - Shared Utilities

enum CLIError: LocalizedError {
    case invalidURL(String)
    case fetchFailed(String)
    case validationFailed(String)
    case widgetNotFound(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .fetchFailed(let message):
            return "Failed to fetch: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .widgetNotFound(let id):
            return "Widget not found: \(id)"
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        }
    }
}

// MARK: - Output Helpers

enum Output {
    static func success(_ message: String) {
        print("✓ \(message)")
    }

    static func error(_ message: String) {
        fputs("✗ \(message)\n", stderr)
    }

    static func info(_ message: String) {
        print(message)
    }

    static func warning(_ message: String) {
        print("⚠ \(message)")
    }
}

// MARK: - Auth Parsing

extension WidgetAuth {
    /// Creates WidgetAuth from CLI options
    static func from(
        headers: [String],
        basicAuth: String?,
        queryParams: [String]
    ) -> WidgetAuth? {
        // Basic auth takes precedence
        if let basicAuth = basicAuth {
            let parts = basicAuth.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                return .basic(
                    username: String(parts[0]),
                    password: String(parts[1])
                )
            }
        }

        // Headers
        if !headers.isEmpty {
            var headerDict: [String: String] = [:]
            for header in headers {
                let parts = header.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    headerDict[key] = value
                }
            }
            if !headerDict.isEmpty {
                return .header(headers: headerDict)
            }
        }

        // Query params
        if !queryParams.isEmpty {
            var paramsDict: [String: String] = [:]
            for param in queryParams {
                let parts = param.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    paramsDict[String(parts[0])] = String(parts[1])
                }
            }
            if !paramsDict.isEmpty {
                return .query(params: paramsDict)
            }
        }

        return nil
    }
}

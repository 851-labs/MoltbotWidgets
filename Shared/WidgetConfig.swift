import Foundation

// MARK: - Widget Configuration Model

/// Represents the stored configuration for a custom widget
struct CustomWidgetConfig: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var url: String
    var auth: WidgetAuth?
    var intervalMinutes: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        url: String,
        auth: WidgetAuth? = nil,
        intervalMinutes: Int = 5,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.auth = auth
        self.intervalMinutes = intervalMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Authentication Types

/// Authentication configuration for widget API requests
enum WidgetAuth: Codable, Equatable {
    case header(headers: [String: String])
    case basic(username: String, password: String)
    case query(params: [String: String])

    private enum CodingKeys: String, CodingKey {
        case type
        case headers
        case username
        case password
        case params
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "header":
            let headers = try container.decode([String: String].self, forKey: .headers)
            self = .header(headers: headers)
        case "basic":
            let username = try container.decode(String.self, forKey: .username)
            let password = try container.decode(String.self, forKey: .password)
            self = .basic(username: username, password: password)
        case "query":
            let params = try container.decode([String: String].self, forKey: .params)
            self = .query(params: params)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown auth type: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .header(let headers):
            try container.encode("header", forKey: .type)
            try container.encode(headers, forKey: .headers)
        case .basic(let username, let password):
            try container.encode("basic", forKey: .type)
            try container.encode(username, forKey: .username)
            try container.encode(password, forKey: .password)
        case .query(let params):
            try container.encode("query", forKey: .type)
            try container.encode(params, forKey: .params)
        }
    }
}

// MARK: - Configuration File Model

/// Root model for the custom-widgets.json file
struct CustomWidgetsFile: Codable {
    var version: Int
    var widgets: [CustomWidgetConfig]

    init(version: Int = 1, widgets: [CustomWidgetConfig] = []) {
        self.version = version
        self.widgets = widgets
    }
}

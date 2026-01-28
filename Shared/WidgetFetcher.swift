import Foundation

// MARK: - Widget Fetcher

/// Fetches widget data from a URL with authentication support
enum WidgetFetcher {

    // MARK: - Fetch Widget Data

    /// Fetches and parses widget data from a URL
    static func fetch(config: CustomWidgetConfig) async throws -> WidgetResponse {
        guard let url = buildURL(from: config) else {
            throw WidgetFetchError.invalidURL(config.url)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        // Apply authentication
        applyAuth(to: &request, auth: config.auth)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WidgetFetchError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WidgetFetchError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WidgetResponse.self, from: data)
        } catch {
            throw WidgetFetchError.invalidJSON(error.localizedDescription)
        }
    }

    /// Fetches raw JSON data from a URL (for validation)
    static func fetchRaw(
        url urlString: String,
        auth: WidgetAuth? = nil
    ) async throws -> (Data, WidgetResponse) {
        guard let url = URL(string: urlString) else {
            throw WidgetFetchError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        // Apply authentication
        applyAuth(to: &request, auth: auth)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WidgetFetchError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WidgetFetchError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            let widgetResponse = try decoder.decode(WidgetResponse.self, from: data)
            return (data, widgetResponse)
        } catch {
            throw WidgetFetchError.invalidJSON(error.localizedDescription)
        }
    }

    // MARK: - URL Building

    private static func buildURL(from config: CustomWidgetConfig) -> URL? {
        guard var components = URLComponents(string: config.url) else {
            return nil
        }

        // Add query parameters if using query auth
        if case .query(let params) = config.auth {
            var queryItems = components.queryItems ?? []
            for (key, value) in params {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            components.queryItems = queryItems
        }

        return components.url
    }

    // MARK: - Authentication

    private static func applyAuth(to request: inout URLRequest, auth: WidgetAuth?) {
        guard let auth = auth else { return }

        switch auth {
        case .header(let headers):
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

        case .basic(let username, let password):
            let credentials = "\(username):\(password)"
            if let data = credentials.data(using: .utf8) {
                let base64 = data.base64EncodedString()
                request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
            }

        case .query:
            // Query params are added in buildURL
            break
        }
    }
}

// MARK: - Errors

enum WidgetFetchError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int)
    case invalidJSON(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

import Foundation

enum MoltbotAPIError: LocalizedError {
    case invalidURL
    case connectionFailed(String)
    case invalidResponse
    case apiError(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return message
        case .timeout:
            return "Connection timed out"
        }
    }
}

struct CronStatusResponse: Codable {
    let enabled: Bool
    let storePath: String
    let jobs: Int
    let nextWakeAtMs: Int?
}

struct RPCResponse<T: Codable>: Codable {
    let ok: Bool
    let payload: T?
    let error: RPCError?
}

struct RPCError: Codable {
    let code: String
    let message: String
}

struct RPCRequest: Codable {
    let id: String
    let method: String
    let params: [String: String]?

    init(method: String, params: [String: String]? = nil) {
        self.id = UUID().uuidString
        self.method = method
        self.params = params
    }
}

actor MoltbotAPI {
    private let host: String
    private let port: String
    private let token: String?
    private let useSecure: Bool

    init(host: String, port: String, token: String?, useSecure: Bool = false) {
        self.host = host
        self.port = port
        self.token = token
        self.useSecure = useSecure
    }

    func getCronStatus() async throws -> CronStatusResponse {
        let scheme = useSecure ? "wss" : "ws"
        guard let url = URL(string: "\(scheme)://\(host):\(port)") else {
            throw MoltbotAPIError.invalidURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: url)
            request.timeoutInterval = 10

            if let token = token, !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let session = URLSession(configuration: .default)
            let webSocketTask = session.webSocketTask(with: request)

            webSocketTask.resume()

            let rpcRequest = RPCRequest(method: "cron.status")

            Task {
                do {
                    let encoder = JSONEncoder()
                    let requestData = try encoder.encode(rpcRequest)
                    guard let requestString = String(data: requestData, encoding: .utf8) else {
                        webSocketTask.cancel(with: .normalClosure, reason: nil)
                        continuation.resume(throwing: MoltbotAPIError.invalidResponse)
                        return
                    }

                    try await webSocketTask.send(.string(requestString))

                    let message = try await webSocketTask.receive()

                    webSocketTask.cancel(with: .normalClosure, reason: nil)

                    switch message {
                    case .string(let text):
                        guard let data = text.data(using: .utf8) else {
                            continuation.resume(throwing: MoltbotAPIError.invalidResponse)
                            return
                        }

                        let decoder = JSONDecoder()
                        let response = try decoder.decode(RPCResponse<CronStatusResponse>.self, from: data)

                        if response.ok, let payload = response.payload {
                            continuation.resume(returning: payload)
                        } else if let error = response.error {
                            continuation.resume(throwing: MoltbotAPIError.apiError(error.message))
                        } else {
                            continuation.resume(throwing: MoltbotAPIError.invalidResponse)
                        }

                    case .data:
                        continuation.resume(throwing: MoltbotAPIError.invalidResponse)

                    @unknown default:
                        continuation.resume(throwing: MoltbotAPIError.invalidResponse)
                    }
                } catch let error as MoltbotAPIError {
                    webSocketTask.cancel(with: .normalClosure, reason: nil)
                    continuation.resume(throwing: error)
                } catch {
                    webSocketTask.cancel(with: .normalClosure, reason: nil)
                    continuation.resume(throwing: MoltbotAPIError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }
}

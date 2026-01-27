import Foundation

enum MoltbotAPIError: LocalizedError {
    case invalidURL
    case connectionFailed(String)
    case invalidResponse
    case apiError(String)
    case timeout
    case protocolError(String)
    case authenticationRequired

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
        case .protocolError(let message):
            return "Protocol error: \(message)"
        case .authenticationRequired:
            return "Authentication token required"
        }
    }
}

struct CronStatusResponse: Codable {
    let enabled: Bool
    let storePath: String
    let jobs: Int
    let nextWakeAtMs: Int?
}

actor MoltbotAPI {
    private let host: String
    private let port: String
    private let token: String?
    private let useSecure: Bool

    private static let protocolVersion = 3

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
            request.timeoutInterval = 15

            let session = URLSession(configuration: .default)
            let webSocketTask = session.webSocketTask(with: request)

            webSocketTask.resume()

            Task {
                do {
                    var connectRequestId: String?
                    var cronRequestId: String?
                    var connectSucceeded = false
                    var cronResponse: CronStatusResponse?
                    var attempts = 0
                    let maxAttempts = 20

                    while attempts < maxAttempts {
                        attempts += 1
                        let message = try await webSocketTask.receive()

                        switch message {
                        case .string(let text):
                            guard let data = text.data(using: .utf8),
                                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                                continue
                            }

                            let messageType = json["type"] as? String

                            // Handle events
                            if messageType == "event" {
                                let event = json["event"] as? String

                                if event == "connect.challenge" {
                                    // Send connect request with auth token
                                    connectRequestId = UUID().uuidString

                                    var connectParams: [String: Any] = [
                                        "minProtocol": Self.protocolVersion,
                                        "maxProtocol": Self.protocolVersion,
                                        "client": [
                                            "id": "gateway-client",
                                            "version": "1.0.0",
                                            "platform": "darwin",
                                            "mode": "backend"
                                        ],
                                        "caps": [],
                                        "role": "operator",
                                        "scopes": ["operator.read"]
                                    ]

                                    // Add auth token if provided
                                    if let token = self.token, !token.isEmpty {
                                        connectParams["auth"] = ["token": token]
                                    }

                                    let connectRequest: [String: Any] = [
                                        "type": "req",
                                        "id": connectRequestId!,
                                        "method": "connect",
                                        "params": connectParams
                                    ]

                                    let connectData = try JSONSerialization.data(withJSONObject: connectRequest)
                                    guard let connectString = String(data: connectData, encoding: .utf8) else {
                                        webSocketTask.cancel(with: .normalClosure, reason: nil)
                                        continuation.resume(throwing: MoltbotAPIError.invalidResponse)
                                        return
                                    }

                                    try await webSocketTask.send(.string(connectString))
                                }
                                continue
                            }

                            // Handle responses
                            if messageType == "res" {
                                let responseId = json["id"] as? String
                                let ok = json["ok"] as? Bool ?? false

                                // Connect response
                                if responseId == connectRequestId {
                                    if ok {
                                        connectSucceeded = true

                                        // Send cron.status request
                                        cronRequestId = UUID().uuidString
                                        let cronRequest: [String: Any] = [
                                            "type": "req",
                                            "id": cronRequestId!,
                                            "method": "cron.status",
                                            "params": [String: Any]()
                                        ]

                                        let cronData = try JSONSerialization.data(withJSONObject: cronRequest)
                                        guard let cronString = String(data: cronData, encoding: .utf8) else {
                                            webSocketTask.cancel(with: .normalClosure, reason: nil)
                                            continuation.resume(throwing: MoltbotAPIError.invalidResponse)
                                            return
                                        }

                                        try await webSocketTask.send(.string(cronString))
                                    } else {
                                        // Connect failed
                                        let error = json["error"] as? [String: Any]
                                        let code = error?["code"] as? String ?? ""
                                        let message = error?["message"] as? String ?? "Unknown error"

                                        webSocketTask.cancel(with: .normalClosure, reason: nil)

                                        if code == "NOT_PAIRED" || message.contains("device identity") || message.contains("unauthorized") {
                                            continuation.resume(throwing: MoltbotAPIError.authenticationRequired)
                                        } else {
                                            continuation.resume(throwing: MoltbotAPIError.apiError(message))
                                        }
                                        return
                                    }
                                }

                                // Cron status response
                                if responseId == cronRequestId {
                                    if ok, let payload = json["payload"] as? [String: Any] {
                                        let enabled = payload["enabled"] as? Bool ?? false
                                        let storePath = payload["storePath"] as? String ?? ""
                                        let jobs = payload["jobs"] as? Int ?? 0
                                        let nextWakeAtMs = payload["nextWakeAtMs"] as? Int

                                        cronResponse = CronStatusResponse(
                                            enabled: enabled,
                                            storePath: storePath,
                                            jobs: jobs,
                                            nextWakeAtMs: nextWakeAtMs
                                        )
                                    } else {
                                        let error = json["error"] as? [String: Any]
                                        let message = error?["message"] as? String ?? "Failed to get cron status"
                                        webSocketTask.cancel(with: .normalClosure, reason: nil)
                                        continuation.resume(throwing: MoltbotAPIError.apiError(message))
                                        return
                                    }
                                }
                            }

                            // Check if we have the response
                            if let response = cronResponse {
                                webSocketTask.cancel(with: .normalClosure, reason: nil)
                                continuation.resume(returning: response)
                                return
                            }

                        case .data:
                            continue
                        @unknown default:
                            continue
                        }
                    }

                    webSocketTask.cancel(with: .normalClosure, reason: nil)
                    continuation.resume(throwing: MoltbotAPIError.timeout)

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

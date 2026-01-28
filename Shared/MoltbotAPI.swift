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

// MARK: - Response Types

struct CronStatusResponse: Codable {
    let enabled: Bool
    let storePath: String
    let jobs: Int
    let nextWakeAtMs: Int?
}

struct CronJob: Codable {
    let id: String
    let label: String?
    let schedule: String
    let enabled: Bool
    let lastRunAt: Int?
    let lastResult: String?
}

struct CronListResponse: Codable {
    let jobs: [CronJob]
}

struct CronRunEntry: Codable {
    let id: String
    let jobId: String
    let startedAt: Int
    let finishedAt: Int?
    let status: String
    let error: String?
}

struct CronRunsResponse: Codable {
    let entries: [CronRunEntry]
}

struct HealthResponse: Codable {
    let ok: Bool
    let uptimeMs: Int?
    let version: String?
    let channelsTotal: Int?
    let channelsConnected: Int?
}

struct UsageCostResponse: Codable {
    let totalCost: Double
    let totalTokens: Int
    let input: Int
    let output: Int
    let cacheRead: Int
    let cacheWrite: Int
    let days: Int
}

// MARK: - API Client

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

    // MARK: - Public API Methods

    func getCronStatus() async throws -> CronStatusResponse {
        let payload = try await request(method: "cron.status", params: [:])

        let enabled = payload["enabled"] as? Bool ?? false
        let storePath = payload["storePath"] as? String ?? ""
        let jobs = payload["jobs"] as? Int ?? 0
        let nextWakeAtMs = payload["nextWakeAtMs"] as? Int

        return CronStatusResponse(
            enabled: enabled,
            storePath: storePath,
            jobs: jobs,
            nextWakeAtMs: nextWakeAtMs
        )
    }

    func getCronList(includeDisabled: Bool = true) async throws -> CronListResponse {
        let payload = try await request(method: "cron.list", params: ["includeDisabled": includeDisabled])

        var jobs: [CronJob] = []
        if let jobsArray = payload["jobs"] as? [[String: Any]] {
            for jobData in jobsArray {
                let job = CronJob(
                    id: jobData["id"] as? String ?? "",
                    label: jobData["label"] as? String,
                    schedule: jobData["schedule"] as? String ?? "",
                    enabled: jobData["enabled"] as? Bool ?? true,
                    lastRunAt: jobData["lastRunAt"] as? Int,
                    lastResult: jobData["lastResult"] as? String
                )
                jobs.append(job)
            }
        }

        return CronListResponse(jobs: jobs)
    }

    func getCronRuns(jobId: String, limit: Int = 10) async throws -> CronRunsResponse {
        let payload = try await request(method: "cron.runs", params: ["id": jobId, "limit": limit])

        var entries: [CronRunEntry] = []
        if let entriesArray = payload["entries"] as? [[String: Any]] {
            for entryData in entriesArray {
                let entry = CronRunEntry(
                    id: entryData["id"] as? String ?? "",
                    jobId: entryData["jobId"] as? String ?? jobId,
                    startedAt: entryData["startedAt"] as? Int ?? 0,
                    finishedAt: entryData["finishedAt"] as? Int,
                    status: entryData["status"] as? String ?? "unknown",
                    error: entryData["error"] as? String
                )
                entries.append(entry)
            }
        }

        return CronRunsResponse(entries: entries)
    }

    func getHealth(probe: Bool = false) async throws -> HealthResponse {
        let result = try await requestWithConnectInfo(method: "health", params: probe ? ["probe": true] : [:])
        let payload = result.payload

        let ok = payload["ok"] as? Bool ?? false

        // Count channels from the health response
        var channelsTotal = 0
        var channelsConnected = 0
        if let channels = payload["channels"] as? [String: Any] {
            channelsTotal = channels.count
            // Count channels that are linked/configured
            for (_, channelData) in channels {
                if let channel = channelData as? [String: Any] {
                    if channel["linked"] as? Bool == true || channel["configured"] as? Bool == true {
                        channelsConnected += 1
                    }
                }
            }
        }

        return HealthResponse(
            ok: ok,
            uptimeMs: result.uptimeMs,
            version: result.version,
            channelsTotal: channelsTotal > 0 ? channelsTotal : nil,
            channelsConnected: channelsConnected > 0 ? channelsConnected : nil
        )
    }

    func getUsageCost(days: Int = 30) async throws -> UsageCostResponse {
        let payload = try await request(method: "usage.cost", params: ["days": days])

        // Data is nested under "totals"
        let totals = payload["totals"] as? [String: Any] ?? [:]
        let responseDays = payload["days"] as? Int ?? days

        let totalCost = totals["totalCost"] as? Double ?? 0
        let totalTokens = totals["totalTokens"] as? Int ?? 0
        let input = totals["input"] as? Int ?? 0
        let output = totals["output"] as? Int ?? 0
        let cacheRead = totals["cacheRead"] as? Int ?? 0
        let cacheWrite = totals["cacheWrite"] as? Int ?? 0

        return UsageCostResponse(
            totalCost: totalCost,
            totalTokens: totalTokens,
            input: input,
            output: output,
            cacheRead: cacheRead,
            cacheWrite: cacheWrite,
            days: responseDays
        )
    }

    // MARK: - Private Request Handler

    private struct RequestResult {
        let payload: [String: Any]
        let version: String?
        let uptimeMs: Int?
    }

    private func request(method: String, params: [String: Any]) async throws -> [String: Any] {
        let result = try await requestWithConnectInfo(method: method, params: params)
        return result.payload
    }

    private func requestWithConnectInfo(method: String, params: [String: Any]) async throws -> RequestResult {
        let scheme = useSecure ? "wss" : "ws"
        guard let url = URL(string: "\(scheme)://\(host):\(port)") else {
            throw MoltbotAPIError.invalidURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            var urlRequest = URLRequest(url: url)
            urlRequest.timeoutInterval = 15

            let session = URLSession(configuration: .default)
            let webSocketTask = session.webSocketTask(with: urlRequest)

            webSocketTask.resume()

            Task {
                do {
                    var connectRequestId: String?
                    var methodRequestId: String?
                    var capturedVersion: String?
                    var capturedUptimeMs: Int?
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
                                        // Extract version and uptime from hello-ok response
                                        if let payload = json["payload"] as? [String: Any] {
                                            // Version is in server.version
                                            if let server = payload["server"] as? [String: Any] {
                                                capturedVersion = server["version"] as? String
                                            }
                                            // Uptime is in snapshot.uptimeMs
                                            if let snapshot = payload["snapshot"] as? [String: Any] {
                                                capturedUptimeMs = snapshot["uptimeMs"] as? Int
                                            }
                                        }

                                        // Send the actual method request
                                        methodRequestId = UUID().uuidString
                                        let methodRequest: [String: Any] = [
                                            "type": "req",
                                            "id": methodRequestId!,
                                            "method": method,
                                            "params": params
                                        ]

                                        let methodData = try JSONSerialization.data(withJSONObject: methodRequest)
                                        guard let methodString = String(data: methodData, encoding: .utf8) else {
                                            continuation.resume(throwing: MoltbotAPIError.invalidResponse)
                                            return
                                        }

                                        try await webSocketTask.send(.string(methodString))
                                    } else {
                                        let error = json["error"] as? [String: Any]
                                        let code = error?["code"] as? String ?? ""
                                        let message = error?["message"] as? String ?? "Unknown error"

                                        if code == "NOT_PAIRED" || message.contains("device identity") || message.contains("unauthorized") {
                                            continuation.resume(throwing: MoltbotAPIError.authenticationRequired)
                                        } else {
                                            continuation.resume(throwing: MoltbotAPIError.apiError(message))
                                        }
                                        return
                                    }
                                }

                                // Method response
                                if responseId == methodRequestId {
                                    if ok, let payload = json["payload"] as? [String: Any] {
                                        // Send close frame and wait briefly for clean shutdown
                                        webSocketTask.cancel(with: .normalClosure, reason: nil)
                                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

                                        let result = RequestResult(
                                            payload: payload,
                                            version: capturedVersion,
                                            uptimeMs: capturedUptimeMs
                                        )
                                        continuation.resume(returning: result)
                                        return
                                    } else {
                                        let error = json["error"] as? [String: Any]
                                        let message = error?["message"] as? String ?? "Request failed"
                                        webSocketTask.cancel(with: .normalClosure, reason: nil)
                                        continuation.resume(throwing: MoltbotAPIError.apiError(message))
                                        return
                                    }
                                }
                            }

                        case .data:
                            continue
                        @unknown default:
                            continue
                        }
                    }

                    continuation.resume(throwing: MoltbotAPIError.timeout)

                } catch let error as MoltbotAPIError {
                    continuation.resume(throwing: error)
                } catch {
                    continuation.resume(throwing: MoltbotAPIError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }
}

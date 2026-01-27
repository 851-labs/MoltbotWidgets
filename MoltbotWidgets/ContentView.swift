import SwiftUI

struct ContentView: View {
    @AppStorage("moltbotHost") private var host = "127.0.0.1"
    @AppStorage("moltbotPort") private var port = "18789"
    @AppStorage("moltbotToken") private var token = ""
    @AppStorage("useSecureConnection") private var useSecureConnection = false

    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var cronStatus: CronStatusResponse?
    @State private var isLoading = false

    enum ConnectionStatus {
        case unknown
        case connected
        case disconnected
        case authRequired
        case error(String)

        var color: Color {
            switch self {
            case .unknown: return .gray
            case .connected: return .green
            case .disconnected: return .orange
            case .authRequired: return .yellow
            case .error: return .red
            }
        }

        var text: String {
            switch self {
            case .unknown: return "Unknown"
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .authRequired: return "Token Required"
            case .error(let msg): return "Error: \(msg)"
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Moltbot Widgets")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Configure your Moltbot connection in Settings")
                .foregroundStyle(.secondary)

            Divider()

            GroupBox("Connection Status") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(connectionStatus.color)
                            .frame(width: 10, height: 10)
                        Text(connectionStatus.text)
                            .foregroundStyle(connectionStatus.color)
                    }

                    Text("Host: \(host):\(port)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if case .authRequired = connectionStatus {
                        Text("Enter your gateway token in Settings (Cmd+,)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let status = cronStatus {
                        Divider()
                        HStack {
                            Label("\(status.jobs) Cron Jobs", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            if status.enabled {
                                Text("Enabled")
                                    .foregroundStyle(.green)
                            } else {
                                Text("Disabled")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Button(action: testConnection) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Test Connection", systemImage: "network")
                }
            }
            .disabled(isLoading)

            Spacer()

            Text("Add Moltbot widgets to your desktop from Notification Center")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(width: 400, height: 450)
        .onAppear {
            testConnection()
        }
    }

    private func testConnection() {
        isLoading = true
        connectionStatus = .unknown
        cronStatus = nil

        Task {
            do {
                let api = MoltbotAPI(host: host, port: port, token: token.isEmpty ? nil : token, useSecure: useSecureConnection)
                let status = try await api.getCronStatus()
                await MainActor.run {
                    cronStatus = status
                    connectionStatus = .connected
                    isLoading = false
                }
            } catch MoltbotAPIError.authenticationRequired {
                await MainActor.run {
                    connectionStatus = .authRequired
                    isLoading = false
                }
            } catch let error as MoltbotAPIError {
                await MainActor.run {
                    connectionStatus = .error(error.localizedDescription)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .error(error.localizedDescription)
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

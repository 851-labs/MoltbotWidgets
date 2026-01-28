import SwiftUI
import WidgetKit

// MARK: - Connection State

enum ConnectionState: Equatable {
    case idle
    case connecting
    case connected(CronStatusResponse)
    case authRequired
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

extension CronStatusResponse: Equatable {
    static func == (lhs: CronStatusResponse, rhs: CronStatusResponse) -> Bool {
        lhs.jobs == rhs.jobs && lhs.enabled == rhs.enabled
    }
}

// MARK: - Sidebar Item

enum SidebarItem: String, CaseIterable, Identifiable {
    case connection = "Connection"
    case cronJobs = "Cron Jobs"
    case health = "Health"
    case usage = "Usage"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .connection: return "network"
        case .cronJobs: return "clock.arrow.circlepath"
        case .health: return "checkmark.shield"
        case .usage: return "chart.bar"
        case .about: return "info.circle"
        }
    }

    var color: Color {
        switch self {
        case .connection: return .blue
        case .cronJobs: return .orange
        case .health: return .green
        case .usage: return .purple
        case .about: return .gray
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @AppStorage("moltbotHost") private var host = "127.0.0.1"
    @AppStorage("moltbotPort") private var port = "18789"
    @AppStorage("moltbotToken") private var token = ""
    @AppStorage("useSecureConnection") private var useSecureConnection = false
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false

    @State private var connectionState: ConnectionState = .idle
    @State private var selectedItem: SidebarItem? = .connection

    var body: some View {
        Group {
            if !hasCompletedSetup {
                OnboardingView(
                    host: $host,
                    port: $port,
                    token: $token,
                    useSecureConnection: $useSecureConnection,
                    connectionState: $connectionState,
                    onConnected: {
                        hasCompletedSetup = true
                    }
                )
            } else {
                mainView
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    private var mainView: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem, connectionState: connectionState)
        } detail: {
            detailView
        }
        .task {
            await testConnection()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .connection:
            ConnectionDetailView(
                host: $host,
                port: $port,
                token: $token,
                useSecureConnection: $useSecureConnection,
                connectionState: $connectionState,
                onTestConnection: testConnection
            )
        case .cronJobs:
            CronJobsDetailView(connectionState: connectionState)
        case .health:
            HealthDetailView(
                host: host,
                port: port,
                token: token,
                useSecureConnection: useSecureConnection
            )
        case .usage:
            UsageDetailView(
                host: host,
                port: port,
                token: token,
                useSecureConnection: useSecureConnection
            )
        case .about:
            AboutDetailView()
        case .none:
            Text("Select an item")
                .foregroundStyle(.secondary)
        }
    }

    private func testConnection() async {
        connectionState = .connecting

        let api = MoltbotAPI(
            host: host,
            port: port,
            token: token.isEmpty ? nil : token,
            useSecure: useSecureConnection
        )

        do {
            let status = try await api.getCronStatus()
            connectionState = .connected(status)
            // Sync settings to shared storage for widget access
            SharedSettings.syncFromAppStorage(host: host, port: port, token: token, useSecure: useSecureConnection)
            // Refresh widgets to pick up new settings
            WidgetCenter.shared.reloadAllTimelines()
        } catch MoltbotAPIError.authenticationRequired {
            connectionState = .authRequired
        } catch {
            connectionState = .error(error.localizedDescription)
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    let connectionState: ConnectionState

    var body: some View {
        List(selection: $selectedItem) {
            Section {
                ForEach(SidebarItem.allCases) { item in
                    SidebarRow(item: item, connectionState: connectionState)
                        .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220)
    }
}

struct SidebarRow: View {
    let item: SidebarItem
    let connectionState: ConnectionState

    var body: some View {
        Label {
            HStack {
                Text(item.rawValue)
                Spacer()
                if item == .connection {
                    connectionIndicator
                }
            }
        } icon: {
            Image(systemName: item.icon)
                .foregroundStyle(item.color)
        }
    }

    @ViewBuilder
    private var connectionIndicator: some View {
        switch connectionState {
        case .connected:
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
        case .connecting:
            ProgressView()
                .controlSize(.mini)
        case .authRequired, .error:
            Circle()
                .fill(.orange)
                .frame(width: 8, height: 8)
        case .idle:
            EmptyView()
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var host: String
    @Binding var port: String
    @Binding var token: String
    @Binding var useSecureConnection: Bool
    @Binding var connectionState: ConnectionState

    let onConnected: () -> Void

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connect to Moltbot")
                            .font(.headline)
                        Text("Enter your gateway details to get started.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }


            Section {
                LabeledContent("Host") {
                    TextField("127.0.0.1", text: $host)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }

                LabeledContent("Port") {
                    TextField("18789", text: $port)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                Toggle("Use secure connection (wss://)", isOn: $useSecureConnection)
            } header: {
                Text("Connection")
            }

            Section {
                LabeledContent("Gateway Token") {
                    SecureField("Enter token", text: $token)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                }

                Text("Find your token in ~/.clawdbot/clawdbot.json under gateway.auth.token")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Authentication")
            }

            Section {
                HStack {
                    Spacer()
                    connectionButton
                    Spacer()
                }
                .padding(.vertical, 8)

                if case .error(let message) = connectionState {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                            .foregroundStyle(.secondary)
                    }
                }

                if case .authRequired = connectionState {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.yellow)
                        Text("Authentication required. Please enter your gateway token.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var connectionButton: some View {
        Button {
            Task {
                await testConnection()
            }
        } label: {
            HStack {
                if case .connecting = connectionState {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(connectionState == .connecting ? "Connecting..." : "Connect to Moltbot")
            }
            .frame(minWidth: 150)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(connectionState == .connecting)
    }

    private func testConnection() async {
        connectionState = .connecting

        let api = MoltbotAPI(
            host: host,
            port: port,
            token: token.isEmpty ? nil : token,
            useSecure: useSecureConnection
        )

        do {
            let status = try await api.getCronStatus()
            connectionState = .connected(status)
            // Sync settings to shared storage for widget access
            SharedSettings.syncFromAppStorage(host: host, port: port, token: token, useSecure: useSecureConnection)
            // Refresh widgets to pick up new settings
            WidgetCenter.shared.reloadAllTimelines()
            onConnected()
        } catch MoltbotAPIError.authenticationRequired {
            connectionState = .authRequired
        } catch {
            connectionState = .error(error.localizedDescription)
        }
    }
}

// MARK: - Connection Detail View

struct ConnectionDetailView: View {
    @Binding var host: String
    @Binding var port: String
    @Binding var token: String
    @Binding var useSecureConnection: Bool
    @Binding var connectionState: ConnectionState

    let onTestConnection: () async -> Void

    var body: some View {
        Form {
            Section {
                statusRow
            } header: {
                Text("Status")
            }

            Section {
                LabeledContent("Host") {
                    TextField("127.0.0.1", text: $host)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }

                LabeledContent("Port") {
                    TextField("18789", text: $port)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                Toggle("Use secure connection (wss://)", isOn: $useSecureConnection)
            } header: {
                Text("Server")
            }

            Section {
                LabeledContent("Gateway Token") {
                    SecureField("Enter token", text: $token)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                }

                Text("Find your token in ~/.clawdbot/clawdbot.json under gateway.auth.token")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Authentication")
            }

            Section {
                Button {
                    Task {
                        await onTestConnection()
                    }
                } label: {
                    HStack {
                        if case .connecting = connectionState {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Test Connection")
                    }
                }
                .disabled(connectionState == .connecting)
            }
        }
        .formStyle(.grouped)
    }

    private var statusRow: some View {
        HStack {
            statusIndicator
            VStack(alignment: .leading) {
                Text(statusTitle)
                    .fontWeight(.medium)
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var statusIndicator: some View {
        Group {
            switch connectionState {
            case .connected:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            case .connecting:
                ProgressView()
                    .controlSize(.small)
            case .authRequired:
                Image(systemName: "key.fill")
                    .foregroundStyle(.yellow)
                    .font(.title2)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
            case .idle:
                Image(systemName: "circle")
                    .foregroundStyle(.gray)
                    .font(.title2)
            }
        }
    }

    private var statusTitle: String {
        switch connectionState {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .authRequired: return "Authentication Required"
        case .error: return "Connection Error"
        case .idle: return "Not Connected"
        }
    }

    private var statusSubtitle: String {
        switch connectionState {
        case .connected(let status):
            return "Moltbot is running with \(status.jobs) cron jobs"
        case .connecting:
            return "Establishing connection to \(host):\(port)"
        case .authRequired:
            return "Please enter your gateway token"
        case .error(let message):
            return message
        case .idle:
            return "Click Test Connection to connect"
        }
    }
}

// MARK: - Cron Jobs Detail View

struct CronJobsDetailView: View {
    let connectionState: ConnectionState

    var body: some View {
        if case .connected(let status) = connectionState {
            Form {
                Section {
                    LabeledContent("Total Jobs") {
                        Text("\(status.jobs)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    LabeledContent("Scheduler") {
                        HStack {
                            Circle()
                                .fill(status.enabled ? .green : .orange)
                                .frame(width: 8, height: 8)
                            Text(status.enabled ? "Active" : "Paused")
                        }
                    }

                    if let nextWakeMs = status.nextWakeAtMs {
                        LabeledContent("Next Run") {
                            Text(Date(timeIntervalSince1970: TimeInterval(nextWakeMs) / 1000), style: .relative)
                        }
                    }
                } header: {
                    Text("Overview")
                }

                Section {
                    Text("Add the Moltbot Cron Jobs widget to your desktop to monitor job counts at a glance.")
                        .foregroundStyle(.secondary)

                    Link(destination: URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")!) {
                        Label("Open Notification Center", systemImage: "square.grid.2x2")
                    }
                } header: {
                    Text("Widget")
                }
            }
            .formStyle(.grouped)
        } else {
            ContentUnavailableView {
                Label("Not Connected", systemImage: "network.slash")
            } description: {
                Text("Connect to Moltbot to view cron job statistics.")
            }
        }
    }
}

// MARK: - About Detail View

struct AboutDetailView: View {
    var body: some View {
        Form {
            Section {
                LabeledContent("Version") {
                    Text("1.0.0")
                }

                LabeledContent("Build") {
                    Text("1")
                }
            } header: {
                Text("App Info")
            }

            Section {
                Link(destination: URL(string: "https://github.com/851-labs/MoltbotWidgets")!) {
                    Label("View on GitHub", systemImage: "link")
                }

                Link(destination: URL(string: "https://molt.bot")!) {
                    Label("Moltbot Website", systemImage: "globe")
                }
            } header: {
                Text("Links")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Health Detail View

struct HealthDetailView: View {
    let host: String
    let port: String
    let token: String
    let useSecureConnection: Bool

    @State private var health: HealthResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                if isLoading {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                } else if let error = errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } else if let health = health {
                    LabeledContent("Status") {
                        HStack {
                            Circle()
                                .fill(health.ok ? .green : .orange)
                                .frame(width: 8, height: 8)
                            Text(health.ok ? "Healthy" : "Issues Detected")
                        }
                    }

                    if let uptimeMs = health.uptimeMs {
                        LabeledContent("Uptime") {
                            Text(formatUptime(uptimeMs))
                        }
                    }

                    if let version = health.version {
                        LabeledContent("Version") {
                            Text(version)
                        }
                    }

                    if let connected = health.channelsConnected, let total = health.channelsTotal {
                        LabeledContent("Channels") {
                            Text("\(connected)/\(total) connected")
                        }
                    }
                } else {
                    Text("No data available")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Status")
            }

            Section {
                Button("Refresh") {
                    Task {
                        await fetchHealth()
                    }
                }
                .disabled(isLoading)
            }
        }
        .formStyle(.grouped)
        .task {
            await fetchHealth()
        }
    }

    private func fetchHealth() async {
        isLoading = true
        errorMessage = nil

        let api = MoltbotAPI(
            host: host,
            port: port,
            token: token.isEmpty ? nil : token,
            useSecure: useSecureConnection
        )

        do {
            health = try await api.getHealth(probe: true)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func formatUptime(_ milliseconds: Int) -> String {
        // Convert milliseconds to seconds
        let totalSeconds = milliseconds / 1000
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Usage Detail View

struct UsageDetailView: View {
    let host: String
    let port: String
    let token: String
    let useSecureConnection: Bool

    @State private var usage: UsageCostResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                if isLoading {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                } else if let error = errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } else if let usage = usage {
                    LabeledContent("Total Cost") {
                        Text(String(format: "$%.2f", usage.totalCost))
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    LabeledContent("Total Tokens") {
                        Text(formatTokens(usage.totalTokens))
                    }

                    LabeledContent("Input Tokens") {
                        Text(formatTokens(usage.input))
                    }

                    LabeledContent("Output Tokens") {
                        Text(formatTokens(usage.output))
                    }

                    if usage.cacheRead > 0 || usage.cacheWrite > 0 {
                        LabeledContent("Cache Read") {
                            Text(formatTokens(usage.cacheRead))
                        }
                        LabeledContent("Cache Write") {
                            Text(formatTokens(usage.cacheWrite))
                        }
                    }

                    LabeledContent("Period") {
                        Text("\(usage.days) days")
                    }
                } else {
                    Text("No data available")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Summary")
            }

            Section {
                Button("Refresh") {
                    Task {
                        await fetchUsage()
                    }
                }
                .disabled(isLoading)
            }
        }
        .formStyle(.grouped)
        .task {
            await fetchUsage()
        }
    }

    private func fetchUsage() async {
        isLoading = true
        errorMessage = nil

        let api = MoltbotAPI(
            host: host,
            port: port,
            token: token.isEmpty ? nil : token,
            useSecure: useSecureConnection
        )

        do {
            usage = try await api.getUsageCost(days: 30)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.1fK", Double(tokens) / 1_000)
        }
        return "\(tokens)"
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

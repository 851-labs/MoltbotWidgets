import WidgetKit
import SwiftUI

struct HealthEntry: TimelineEntry {
    let date: Date
    let isHealthy: Bool
    let uptime: String?
    let version: String?
    let channelsConnected: Int?
    let channelsTotal: Int?
    let error: String?

    static var placeholder: HealthEntry {
        HealthEntry(
            date: .now,
            isHealthy: true,
            uptime: "2d 5h",
            version: "1.2.3",
            channelsConnected: 2,
            channelsTotal: 3,
            error: nil
        )
    }

    static var error: HealthEntry {
        HealthEntry(
            date: .now,
            isHealthy: false,
            uptime: nil,
            version: nil,
            channelsConnected: nil,
            channelsTotal: nil,
            error: "Unable to connect"
        )
    }
}

struct HealthProvider: TimelineProvider {
    func placeholder(in context: Context) -> HealthEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HealthEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        Task {
            let entry = await fetchHealth()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthEntry>) -> Void) {
        Task {
            let entry = await fetchHealth()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: entry.date) ?? entry.date.addingTimeInterval(300)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchHealth() async -> HealthEntry {
        let host = SharedSettings.host
        let port = SharedSettings.port
        let token = SharedSettings.token
        let useSecure = SharedSettings.useSecureConnection

        let api = MoltbotAPI(host: host, port: port, token: token, useSecure: useSecure)

        do {
            let health = try await api.getHealth(probe: true)

            var uptimeString: String? = nil
            if let uptimeMs = health.uptimeMs {
                // Convert milliseconds to seconds for calculation
                let uptimeSeconds = uptimeMs / 1000
                let days = uptimeSeconds / 86400
                let hours = (uptimeSeconds % 86400) / 3600
                let minutes = (uptimeSeconds % 3600) / 60

                if days > 0 {
                    uptimeString = "\(days)d \(hours)h"
                } else if hours > 0 {
                    uptimeString = "\(hours)h \(minutes)m"
                } else {
                    uptimeString = "\(minutes)m"
                }
            }

            return HealthEntry(
                date: .now,
                isHealthy: health.ok,
                uptime: uptimeString,
                version: health.version,
                channelsConnected: health.channelsConnected,
                channelsTotal: health.channelsTotal,
                error: nil
            )
        } catch MoltbotAPIError.authenticationRequired {
            return HealthEntry(
                date: .now,
                isHealthy: false,
                uptime: nil,
                version: nil,
                channelsConnected: nil,
                channelsTotal: nil,
                error: "Auth required"
            )
        } catch {
            return HealthEntry(
                date: .now,
                isHealthy: false,
                uptime: nil,
                version: nil,
                channelsConnected: nil,
                channelsTotal: nil,
                error: "Connection failed"
            )
        }
    }
}

struct HealthWidgetEntryView: View {
    var entry: HealthEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            if entry.error != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
                Text("Offline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: entry.isHealthy ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(entry.isHealthy ? .green : .orange)

                Text(entry.isHealthy ? "Healthy" : "Issues")
                    .font(.headline)

                if let uptime = entry.uptime {
                    Text("Up \(uptime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let version = entry.version {
                    Text("v\(version)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumView: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: entry.isHealthy ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(entry.isHealthy ? .green : .orange)

                Text(entry.isHealthy ? "Healthy" : "Issues")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)

            if entry.error == nil {
                VStack(alignment: .leading, spacing: 12) {
                    if let uptime = entry.uptime {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Uptime")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(uptime)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    if let connected = entry.channelsConnected, let total = entry.channelsTotal {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Channels")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(connected == total ? .green : .orange)
                                    .frame(width: 6, height: 6)
                                Text("\(connected)/\(total)")
                                    .font(.subheadline)
                            }
                        }
                    }

                    if let version = entry.version {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Version")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(version)
                                .font(.subheadline)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Connection Error", systemImage: "wifi.slash")
                        .foregroundStyle(.orange)
                    Text("Check Moltbot is running")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct HealthWidget: Widget {
    let kind: String = "HealthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthProvider()) { entry in
            HealthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Moltbot Health")
        .description("Shows the health status of your Moltbot instance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    HealthWidget()
} timeline: {
    HealthEntry.placeholder
}

#Preview(as: .systemMedium) {
    HealthWidget()
} timeline: {
    HealthEntry.placeholder
}

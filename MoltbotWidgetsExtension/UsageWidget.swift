import WidgetKit
import SwiftUI

struct UsageEntry: TimelineEntry {
    let date: Date
    let totalCost: Double
    let totalTokens: Int
    let inputTokens: Int
    let outputTokens: Int
    let days: Int
    let error: String?

    static var placeholder: UsageEntry {
        UsageEntry(
            date: .now,
            totalCost: 12.45,
            totalTokens: 1_234_567,
            inputTokens: 800_000,
            outputTokens: 434_567,
            days: 30,
            error: nil
        )
    }

    static var error: UsageEntry {
        UsageEntry(
            date: .now,
            totalCost: 0,
            totalTokens: 0,
            inputTokens: 0,
            outputTokens: 0,
            days: 30,
            error: "Unable to connect"
        )
    }

    var formattedCost: String {
        String(format: "$%.2f", totalCost)
    }

    var formattedTokens: String {
        if totalTokens >= 1_000_000 {
            return String(format: "%.1fM", Double(totalTokens) / 1_000_000)
        } else if totalTokens >= 1_000 {
            return String(format: "%.1fK", Double(totalTokens) / 1_000)
        }
        return "\(totalTokens)"
    }
}

struct UsageProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        Task {
            let entry = await fetchUsage()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        Task {
            let entry = await fetchUsage()
            // Update every 15 minutes for usage data
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date.addingTimeInterval(900)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchUsage() async -> UsageEntry {
        let host = SharedSettings.host
        let port = SharedSettings.port
        let token = SharedSettings.token
        let useSecure = SharedSettings.useSecureConnection

        let api = MoltbotAPI(host: host, port: port, token: token, useSecure: useSecure)

        do {
            let usage = try await api.getUsageCost(days: 30)

            return UsageEntry(
                date: .now,
                totalCost: usage.totalCost,
                totalTokens: usage.totalTokens,
                inputTokens: usage.input,
                outputTokens: usage.output,
                days: usage.days,
                error: nil
            )
        } catch MoltbotAPIError.authenticationRequired {
            return UsageEntry(
                date: .now,
                totalCost: 0,
                totalTokens: 0,
                inputTokens: 0,
                outputTokens: 0,
                days: 30,
                error: "Auth required"
            )
        } catch {
            return UsageEntry(
                date: .now,
                totalCost: 0,
                totalTokens: 0,
                inputTokens: 0,
                outputTokens: 0,
                days: 30,
                error: "Connection failed"
            )
        }
    }
}

struct UsageWidgetEntryView: View {
    var entry: UsageEntry
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
            if let error = entry.error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
                Text(error.contains("Auth") ? "Auth Required" : "Error")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.purple)

                Text(entry.formattedCost)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("\(entry.days) Day Cost")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(entry.formattedTokens) tokens")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumView: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.purple)

                Text(entry.formattedCost)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("\(entry.days) Day Cost")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            if entry.error == nil {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Tokens")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(entry.formattedTokens)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Input / Output")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(formatTokens(entry.inputTokens)) / \(formatTokens(entry.outputTokens))")
                            .font(.subheadline)
                    }

                    Text("Updated \(entry.date, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label(entry.error?.contains("Auth") == true ? "Auth Required" : "Connection Error",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Configure in app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
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

struct UsageWidget: Widget {
    let kind: String = "UsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UsageProvider()) { entry in
            UsageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Moltbot Usage")
        .description("Shows API usage and costs for the last 30 days.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    UsageWidget()
} timeline: {
    UsageEntry.placeholder
}

#Preview(as: .systemMedium) {
    UsageWidget()
} timeline: {
    UsageEntry.placeholder
}

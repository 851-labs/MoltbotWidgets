import WidgetKit
import SwiftUI

struct CronJobsEntry: TimelineEntry {
    let date: Date
    let jobCount: Int
    let isEnabled: Bool
    let nextWakeAt: Date?
    let error: String?

    static var placeholder: CronJobsEntry {
        CronJobsEntry(date: .now, jobCount: 5, isEnabled: true, nextWakeAt: Date().addingTimeInterval(3600), error: nil)
    }

    static var error: CronJobsEntry {
        CronJobsEntry(date: .now, jobCount: 0, isEnabled: false, nextWakeAt: nil, error: "Unable to connect")
    }
}

struct CronJobsProvider: TimelineProvider {
    func placeholder(in context: Context) -> CronJobsEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CronJobsEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        Task {
            let entry = await fetchCronStatus()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CronJobsEntry>) -> Void) {
        Task {
            let entry = await fetchCronStatus()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: entry.date) ?? entry.date.addingTimeInterval(300)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchCronStatus() async -> CronJobsEntry {
        let host = SharedSettings.host
        let port = SharedSettings.port
        let token = SharedSettings.token
        let useSecure = SharedSettings.useSecureConnection

        let api = MoltbotAPI(host: host, port: port, token: token, useSecure: useSecure)

        do {
            let status = try await api.getCronStatus()
            let nextWake: Date? = status.nextWakeAtMs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            return CronJobsEntry(
                date: .now,
                jobCount: status.jobs,
                isEnabled: status.enabled,
                nextWakeAt: nextWake,
                error: nil
            )
        } catch MoltbotAPIError.authenticationRequired {
            return CronJobsEntry(
                date: .now,
                jobCount: 0,
                isEnabled: false,
                nextWakeAt: nil,
                error: "Token required - configure in app"
            )
        } catch {
            return CronJobsEntry(
                date: .now,
                jobCount: 0,
                isEnabled: false,
                nextWakeAt: nil,
                error: error.localizedDescription
            )
        }
    }

}

struct CronJobsWidgetEntryView: View {
    var entry: CronJobsEntry
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
                Text(error.contains("Token") ? "Auth Required" : "Error")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)

                Text("\(entry.jobCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text("Cron Jobs")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if entry.isEnabled {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Label("Paused", systemImage: "pause.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumView: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)

                Text("\(entry.jobCount)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))

                Text("Cron Jobs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            if entry.error == nil {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(entry.isEnabled ? .green : .orange)
                            .frame(width: 8, height: 8)
                        Text(entry.isEnabled ? "Scheduler Active" : "Scheduler Paused")
                            .font(.subheadline)
                    }

                    if let nextWake = entry.nextWakeAt {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next Run")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(nextWake, style: .relative)
                                .font(.subheadline)
                        }
                    }

                    Text("Updated \(entry.date, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label(entry.error?.contains("Token") == true ? "Auth Required" : "Connection Error",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(entry.error?.contains("Token") == true ? "Set token in app" : "Check Moltbot is running")
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

struct CronJobsWidget: Widget {
    let kind: String = "CronJobsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CronJobsProvider()) { entry in
            CronJobsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Moltbot Cron Jobs")
        .description("Shows the number of cron jobs in your Moltbot instance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    CronJobsWidget()
} timeline: {
    CronJobsEntry.placeholder
}

#Preview(as: .systemMedium) {
    CronJobsWidget()
} timeline: {
    CronJobsEntry.placeholder
}

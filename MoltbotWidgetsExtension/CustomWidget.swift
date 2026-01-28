import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry

struct CustomWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: SelectCustomWidgetIntent
    let state: WidgetState

    enum WidgetState {
        case loading
        case notConfigured
        case success(WidgetResponse)
        case error(String)
    }

    static func placeholder() -> CustomWidgetEntry {
        CustomWidgetEntry(
            date: .now,
            configuration: SelectCustomWidgetIntent(),
            state: .loading
        )
    }

    static func notConfigured() -> CustomWidgetEntry {
        CustomWidgetEntry(
            date: .now,
            configuration: SelectCustomWidgetIntent(),
            state: .notConfigured
        )
    }

    static func error(_ message: String) -> CustomWidgetEntry {
        CustomWidgetEntry(
            date: .now,
            configuration: SelectCustomWidgetIntent(),
            state: .error(message)
        )
    }
}

// MARK: - Timeline Provider

struct CustomWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = CustomWidgetEntry
    typealias Intent = SelectCustomWidgetIntent

    func placeholder(in context: Context) -> CustomWidgetEntry {
        .placeholder()
    }

    func snapshot(for configuration: SelectCustomWidgetIntent, in context: Context) async -> CustomWidgetEntry {
        if context.isPreview {
            return .placeholder()
        }

        return await fetchEntry(for: configuration)
    }

    func timeline(for configuration: SelectCustomWidgetIntent, in context: Context) async -> Timeline<CustomWidgetEntry> {
        let entry = await fetchEntry(for: configuration)

        // Get refresh interval from config
        let intervalMinutes: Int
        if let widgetId = configuration.widget?.id,
           let config = WidgetConfigStore.getWidget(id: widgetId) {
            intervalMinutes = config.intervalMinutes
        } else {
            intervalMinutes = 5 // Default
        }

        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: intervalMinutes,
            to: entry.date
        ) ?? entry.date.addingTimeInterval(Double(intervalMinutes * 60))

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for configuration: SelectCustomWidgetIntent) async -> CustomWidgetEntry {
        // Check if widget is selected
        guard let widgetEntity = configuration.widget else {
            return .notConfigured()
        }

        // Get widget config
        guard let config = WidgetConfigStore.getWidget(id: widgetEntity.id) else {
            return CustomWidgetEntry(
                date: .now,
                configuration: configuration,
                state: .error("Widget not found")
            )
        }

        // Fetch data from URL
        do {
            let response = try await WidgetFetcher.fetch(config: config)
            return CustomWidgetEntry(
                date: .now,
                configuration: configuration,
                state: .success(response)
            )
        } catch let error as WidgetFetchError {
            return CustomWidgetEntry(
                date: .now,
                configuration: configuration,
                state: .error(error.localizedDescription)
            )
        } catch {
            return CustomWidgetEntry(
                date: .now,
                configuration: configuration,
                state: .error("Connection failed")
            )
        }
    }
}

// MARK: - Widget View

struct CustomWidgetEntryView: View {
    var entry: CustomWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch entry.state {
        case .loading:
            WidgetLoadingView(family: family)

        case .notConfigured:
            notConfiguredView

        case .success(let response):
            TemplateRenderer(response: response, family: family)

        case .error(let message):
            WidgetErrorView(message: message, family: family)
        }
    }

    private var notConfiguredView: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: family == .systemSmall ? 28 : 36))
                .foregroundStyle(.secondary)

            Text("Select Widget")
                .font(family == .systemSmall ? .caption : .subheadline)
                .foregroundStyle(.secondary)

            if family != .systemSmall {
                Text("Tap to configure")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Definition

struct CustomWidget: Widget {
    let kind: String = "CustomWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCustomWidgetIntent.self,
            provider: CustomWidgetProvider()
        ) { entry in
            CustomWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Custom Widget")
        .description("Display data from any API endpoint.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    CustomWidget()
} timeline: {
    CustomWidgetEntry.placeholder()
    CustomWidgetEntry.notConfigured()
}

#Preview(as: .systemMedium) {
    CustomWidget()
} timeline: {
    CustomWidgetEntry.placeholder()
    CustomWidgetEntry.notConfigured()
}

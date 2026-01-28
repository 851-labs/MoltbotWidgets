import SwiftUI
import WidgetKit

// MARK: - Template Renderer

/// Routes widget response to appropriate template view
struct TemplateRenderer: View {
    let response: WidgetResponse
    let family: WidgetFamily

    var body: some View {
        switch response.data {
        case .status(let data):
            StatusTemplateView(data: data, family: family)
        case .number(let data):
            NumberTemplateView(data: data, family: family)
        case .gauge(let data):
            GaugeTemplateView(data: data, family: family)
        case .list(let data):
            ListTemplateView(data: data, family: family)
        case .text(let data):
            TextTemplateView(data: data, family: family)
        }
    }
}

// MARK: - Error View

struct WidgetErrorView: View {
    let message: String
    let family: WidgetFamily

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: family == .systemSmall ? 28 : 36))
                .foregroundStyle(.orange)

            Text(message)
                .font(family == .systemSmall ? .caption : .subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Loading View

struct WidgetLoadingView: View {
    let family: WidgetFamily

    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(family == .systemSmall ? 1.0 : 1.2)

            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Placeholder View

struct WidgetPlaceholderView: View {
    let family: WidgetFamily

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.dashed")
                .font(.system(size: family == .systemSmall ? 28 : 36))
                .foregroundStyle(.secondary)

            Text("Custom Widget")
                .font(family == .systemSmall ? .caption : .subheadline)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

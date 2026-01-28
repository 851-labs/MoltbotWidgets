import SwiftUI
import WidgetKit

struct ListTemplateView: View {
    let data: ListWidgetData
    let family: WidgetFamily

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

    // MARK: - Small Layout

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = data.title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            ForEach(Array(data.items.prefix(3).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 6) {
                    if let icon = item.icon {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(item.iconColor?.toColor() ?? .secondary)
                            .frame(width: 14)
                    }

                    Text(item.title)
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()

                    if let value = item.value {
                        Text(value)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if data.items.count > 3 {
                Text("+\(data.items.count - 3) more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Medium Layout

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title = data.title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            ForEach(Array(data.items.prefix(5).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 10) {
                    if let icon = item.icon {
                        Image(systemName: icon)
                            .font(.subheadline)
                            .foregroundStyle(item.iconColor?.toColor() ?? .secondary)
                            .frame(width: 20)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                            .font(.subheadline)
                            .lineLimit(1)

                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    if let value = item.value {
                        Text(value)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

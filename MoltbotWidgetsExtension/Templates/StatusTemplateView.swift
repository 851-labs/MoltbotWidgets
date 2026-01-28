import SwiftUI
import WidgetKit

struct StatusTemplateView: View {
    let data: StatusWidgetData
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
        VStack(spacing: 6) {
            if let icon = data.icon {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(iconColor)
            }

            Text(data.title)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let value = data.value {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(iconColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if let subtitle = data.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Medium Layout

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left side - Icon and Title
            VStack(spacing: 8) {
                if let icon = data.icon {
                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundStyle(iconColor)
                }

                Text(data.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Right side - Value and Details
            VStack(alignment: .leading, spacing: 8) {
                if let value = data.value {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(iconColor)
                        .lineLimit(1)
                }

                if let subtitle = data.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if let footer = data.footer {
                    Text(footer)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Helpers

    private var iconColor: Color {
        data.iconColor?.toColor() ?? .primary
    }
}

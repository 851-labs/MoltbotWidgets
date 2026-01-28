import SwiftUI
import WidgetKit

struct NumberTemplateView: View {
    let data: NumberWidgetData
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
                    .font(.system(size: 24))
                    .foregroundStyle(iconColor)
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(data.value.displayString)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                if let unit = data.unit {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            if let label = data.label {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            if let trend = data.trend, let trendValue = data.trendValue {
                HStack(spacing: 2) {
                    Image(systemName: trendIcon(trend))
                        .font(.caption2)
                    Text(trendValue)
                        .font(.caption2)
                }
                .foregroundStyle(trendColor(trend))
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Medium Layout

    private var mediumView: some View {
        HStack(spacing: 20) {
            // Left side - Number
            VStack(spacing: 4) {
                if let icon = data.icon {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundStyle(iconColor)
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(data.value.displayString)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    if let unit = data.unit {
                        Text(unit)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Right side - Details
            VStack(alignment: .leading, spacing: 8) {
                if let label = data.label {
                    Text(label)
                        .font(.headline)
                        .lineLimit(2)
                }

                if let trend = data.trend, let trendValue = data.trendValue {
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon(trend))
                            .font(.subheadline)
                        Text(trendValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(trendColor(trend))
                }

                Spacer()
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

    private func trendIcon(_ trend: TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }

    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .neutral: return .secondary
        }
    }
}

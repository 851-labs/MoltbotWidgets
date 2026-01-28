import SwiftUI
import WidgetKit

struct GaugeTemplateView: View {
    let data: GaugeWidgetData
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
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(gaugeColor.opacity(0.2), lineWidth: 10)

                // Progress ring
                Circle()
                    .trim(from: 0, to: min(1.0, data.value / data.max))
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Center content
                if data.showPercentage ?? true {
                    Text("\(Int(data.percentage))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                } else {
                    Text(formatValue(data.value))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
            }
            .frame(width: 80, height: 80)

            if let label = data.label {
                Text(label)
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
        HStack(spacing: 20) {
            // Gauge
            ZStack {
                Circle()
                    .stroke(gaugeColor.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: min(1.0, data.value / data.max))
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    if data.showPercentage ?? true {
                        Text("\(Int(data.percentage))%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                    } else {
                        Text(formatValue(data.value))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                }
            }
            .frame(width: 100, height: 100)

            // Details
            VStack(alignment: .leading, spacing: 8) {
                if let label = data.label {
                    Text(label)
                        .font(.headline)
                }

                Text("\(formatValue(data.value)) / \(formatValue(data.max))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(gaugeColor.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(gaugeColor)
                            .frame(
                                width: geometry.size.width * min(1.0, data.value / data.max),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Helpers

    private var gaugeColor: Color {
        data.color?.toColor() ?? .blue
    }

    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}

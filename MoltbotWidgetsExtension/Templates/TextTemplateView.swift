import SwiftUI
import WidgetKit

struct TextTemplateView: View {
    let data: TextWidgetData
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
        VStack(alignment: .leading, spacing: 6) {
            if let title = data.title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(data.body)
                .font(.caption)
                .lineLimit(6)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            if let footer = data.footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Medium Layout

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = data.title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(data.body)
                .font(.subheadline)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            if let footer = data.footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

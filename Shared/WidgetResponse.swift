import Foundation
import SwiftUI

// MARK: - Widget Response Models

/// The root response from a widget API endpoint
struct WidgetResponse: Codable {
    let type: WidgetType
    let data: WidgetData

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(WidgetType.self, forKey: .type)

        // Decode data based on type
        switch type {
        case .status:
            data = .status(try container.decode(StatusWidgetData.self, forKey: .data))
        case .number:
            data = .number(try container.decode(NumberWidgetData.self, forKey: .data))
        case .gauge:
            data = .gauge(try container.decode(GaugeWidgetData.self, forKey: .data))
        case .list:
            data = .list(try container.decode(ListWidgetData.self, forKey: .data))
        case .text:
            data = .text(try container.decode(TextWidgetData.self, forKey: .data))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)

        switch data {
        case .status(let data):
            try container.encode(data, forKey: .data)
        case .number(let data):
            try container.encode(data, forKey: .data)
        case .gauge(let data):
            try container.encode(data, forKey: .data)
        case .list(let data):
            try container.encode(data, forKey: .data)
        case .text(let data):
            try container.encode(data, forKey: .data)
        }
    }
}

// MARK: - Widget Types

enum WidgetType: String, Codable, CaseIterable {
    case status
    case number
    case gauge
    case list
    case text
}

enum WidgetData {
    case status(StatusWidgetData)
    case number(NumberWidgetData)
    case gauge(GaugeWidgetData)
    case list(ListWidgetData)
    case text(TextWidgetData)
}

// MARK: - Status Widget

struct StatusWidgetData: Codable {
    let icon: String?
    let iconColor: String?
    let title: String
    let subtitle: String?
    let value: String?
    let footer: String?
}

// MARK: - Number Widget

struct NumberWidgetData: Codable {
    let icon: String?
    let iconColor: String?
    let value: NumberValue
    let unit: String?
    let label: String?
    let trend: TrendDirection?
    let trendValue: String?
}

enum NumberValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Value must be a string or number"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        }
    }

    var displayString: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return "\(value)"
        case .double(let value):
            // Format double nicely (remove trailing zeros)
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(value))"
            } else {
                return String(format: "%.2f", value)
            }
        }
    }
}

enum TrendDirection: String, Codable {
    case up
    case down
    case neutral
}

// MARK: - Gauge Widget

struct GaugeWidgetData: Codable {
    let value: Double
    let max: Double
    let label: String?
    let color: String?
    let showPercentage: Bool?

    var percentage: Double {
        guard self.max > 0 else { return 0 }
        return Swift.min(100, Swift.max(0, (value / self.max) * 100))
    }
}

// MARK: - List Widget

struct ListWidgetData: Codable {
    let title: String?
    let items: [ListWidgetItem]
}

struct ListWidgetItem: Codable, Identifiable {
    let icon: String?
    let iconColor: String?
    let title: String
    let subtitle: String?
    let value: String?

    var id: String { title + (subtitle ?? "") + (value ?? "") }
}

// MARK: - Text Widget

struct TextWidgetData: Codable {
    let title: String?
    let body: String
    let footer: String?
}

// MARK: - Color Parsing

extension String {
    /// Converts a color string to a SwiftUI Color
    func toColor() -> Color {
        // Handle hex colors
        if hasPrefix("#") {
            var hexSanitized = String(dropFirst())
            if hexSanitized.count == 3 {
                hexSanitized = hexSanitized.map { "\($0)\($0)" }.joined()
            }
            guard hexSanitized.count == 6,
                  let hex = UInt64(hexSanitized, radix: 16) else {
                return .primary
            }
            let red = Double((hex & 0xFF0000) >> 16) / 255.0
            let green = Double((hex & 0x00FF00) >> 8) / 255.0
            let blue = Double(hex & 0x0000FF) / 255.0
            return Color(red: red, green: green, blue: blue)
        }

        // Handle named colors
        switch lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        case "gray", "grey": return .gray
        case "primary": return .primary
        case "secondary": return .secondary
        default: return .primary
        }
    }
}

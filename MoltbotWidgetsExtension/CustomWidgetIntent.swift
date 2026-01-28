import AppIntents
import WidgetKit

// MARK: - Widget Entity

/// Represents a configured widget for selection
struct CustomWidgetEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Widget"
    }

    static var defaultQuery = CustomWidgetQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

// MARK: - Widget Query

/// Provides the list of configured widgets
struct CustomWidgetQuery: EntityQuery {
    func entities(for identifiers: [CustomWidgetEntity.ID]) async throws -> [CustomWidgetEntity] {
        let widgets = WidgetConfigStore.loadWidgets()
        return identifiers.compactMap { id in
            guard let widget = widgets.first(where: { $0.id == id }) else { return nil }
            return CustomWidgetEntity(id: widget.id, name: widget.name)
        }
    }

    func suggestedEntities() async throws -> [CustomWidgetEntity] {
        let widgets = WidgetConfigStore.loadWidgets()
        return widgets.map { CustomWidgetEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> CustomWidgetEntity? {
        let widgets = WidgetConfigStore.loadWidgets()
        guard let first = widgets.first else { return nil }
        return CustomWidgetEntity(id: first.id, name: first.name)
    }
}

// MARK: - Widget Configuration Intent

/// Intent for configuring which widget to display
struct SelectCustomWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Widget"
    static var description = IntentDescription("Choose which custom widget to display")

    @Parameter(title: "Widget")
    var widget: CustomWidgetEntity?

    init() {}

    init(widget: CustomWidgetEntity) {
        self.widget = widget
    }
}

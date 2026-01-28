import Foundation

// MARK: - Widget Configuration Store

/// Manages reading and writing widget configurations to the shared App Group container
enum WidgetConfigStore {
    private static let appGroupID = "group.com.moltbot.widgets"
    private static let configFileName = "custom-widgets.json"

    // MARK: - File Location

    /// Returns the path to the config file in the App Group container
    static var configFileURL: URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            return nil
        }
        return containerURL.appendingPathComponent(configFileName)
    }

    /// Returns the path as a string (useful for CLI which may not have App Group access)
    static var configFilePath: String {
        // For CLI, we need to construct the path manually since it may not have App Group entitlements
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let groupContainerPath = homeDir
            .appendingPathComponent("Library/Group Containers")
            .appendingPathComponent(appGroupID)
            .appendingPathComponent(configFileName)
        return groupContainerPath.path
    }

    // MARK: - Read Operations

    /// Loads the widget configuration file
    static func load() -> CustomWidgetsFile {
        // Try App Group container first
        if let url = configFileURL, FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(CustomWidgetsFile.self, from: data)
            } catch {
                print("Warning: Failed to load config from App Group: \(error)")
            }
        }

        // Fall back to manual path (for CLI)
        let manualPath = configFilePath
        if FileManager.default.fileExists(atPath: manualPath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: manualPath))
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(CustomWidgetsFile.self, from: data)
            } catch {
                print("Warning: Failed to load config from manual path: \(error)")
            }
        }

        // Return empty config if no file exists
        return CustomWidgetsFile()
    }

    /// Returns all configured widgets
    static func loadWidgets() -> [CustomWidgetConfig] {
        load().widgets
    }

    /// Returns a specific widget by ID
    static func getWidget(id: String) -> CustomWidgetConfig? {
        loadWidgets().first { $0.id == id }
    }

    /// Returns a widget by name
    static func getWidget(name: String) -> CustomWidgetConfig? {
        loadWidgets().first { $0.name.lowercased() == name.lowercased() }
    }

    // MARK: - Write Operations

    /// Saves the widget configuration file
    static func save(_ config: CustomWidgetsFile) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(config)

        // Try to save to both locations
        var savedToAppGroup = false
        var savedToManualPath = false

        // Save to App Group container
        if let url = configFileURL {
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url)
            savedToAppGroup = true
        }

        // Also save to manual path (for CLI access)
        let manualPath = configFilePath
        let manualURL = URL(fileURLWithPath: manualPath)
        let directory = manualURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: manualURL)
        savedToManualPath = true

        if !savedToAppGroup && !savedToManualPath {
            throw WidgetConfigError.failedToSave
        }
    }

    /// Adds a new widget configuration
    static func addWidget(_ widget: CustomWidgetConfig) throws {
        var config = load()

        // Check for duplicate names
        if config.widgets.contains(where: { $0.name.lowercased() == widget.name.lowercased() }) {
            throw WidgetConfigError.duplicateName(widget.name)
        }

        config.widgets.append(widget)
        try save(config)
    }

    /// Updates an existing widget configuration
    static func updateWidget(_ widget: CustomWidgetConfig) throws {
        var config = load()

        guard let index = config.widgets.firstIndex(where: { $0.id == widget.id }) else {
            throw WidgetConfigError.notFound(widget.id)
        }

        // Check for duplicate names (excluding current widget)
        if config.widgets.contains(where: {
            $0.id != widget.id && $0.name.lowercased() == widget.name.lowercased()
        }) {
            throw WidgetConfigError.duplicateName(widget.name)
        }

        var updatedWidget = widget
        updatedWidget.updatedAt = Date()
        config.widgets[index] = updatedWidget
        try save(config)
    }

    /// Deletes a widget by ID
    static func deleteWidget(id: String) throws {
        var config = load()

        guard config.widgets.contains(where: { $0.id == id }) else {
            throw WidgetConfigError.notFound(id)
        }

        config.widgets.removeAll { $0.id == id }
        try save(config)
    }
}

// MARK: - Errors

enum WidgetConfigError: LocalizedError {
    case notFound(String)
    case duplicateName(String)
    case failedToSave

    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Widget not found: \(id)"
        case .duplicateName(let name):
            return "A widget named '\(name)' already exists"
        case .failedToSave:
            return "Failed to save configuration"
        }
    }
}

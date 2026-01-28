import Foundation

enum SharedSettings {
    private static let appGroupID = "group.com.moltbot.widgets"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: - Keys
    private enum Keys {
        static let host = "moltbotHost"
        static let port = "moltbotPort"
        static let token = "moltbotToken"
        static let useSecureConnection = "useSecureConnection"
    }

    // MARK: - Getters
    static var host: String {
        sharedDefaults.string(forKey: Keys.host) ?? "127.0.0.1"
    }

    static var port: String {
        sharedDefaults.string(forKey: Keys.port) ?? "18789"
    }

    static var token: String? {
        // First try shared settings
        if let token = sharedDefaults.string(forKey: Keys.token), !token.isEmpty {
            return token
        }
        // Fall back to reading from config file
        return readGatewayTokenFromConfig()
    }

    static var useSecureConnection: Bool {
        sharedDefaults.bool(forKey: Keys.useSecureConnection)
    }

    // MARK: - Setters
    static func setHost(_ value: String) {
        sharedDefaults.set(value, forKey: Keys.host)
    }

    static func setPort(_ value: String) {
        sharedDefaults.set(value, forKey: Keys.port)
    }

    static func setToken(_ value: String) {
        sharedDefaults.set(value, forKey: Keys.token)
    }

    static func setUseSecureConnection(_ value: Bool) {
        sharedDefaults.set(value, forKey: Keys.useSecureConnection)
    }

    // MARK: - Sync all settings from @AppStorage
    static func syncFromAppStorage(host: String, port: String, token: String, useSecure: Bool) {
        setHost(host)
        setPort(port)
        setToken(token)
        setUseSecureConnection(useSecure)
        // Force write to disk
        sharedDefaults.synchronize()
    }

    // MARK: - Config file fallback
    private static func readGatewayTokenFromConfig() -> String? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configPath = homeDir.appendingPathComponent(".clawdbot/clawdbot.json")

        guard let data = try? Data(contentsOf: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let gateway = json["gateway"] as? [String: Any],
              let auth = gateway["auth"] as? [String: Any],
              let token = auth["token"] as? String else {
            return nil
        }

        return token
    }
}

import SwiftUI

@main
struct MoltbotWidgetsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}

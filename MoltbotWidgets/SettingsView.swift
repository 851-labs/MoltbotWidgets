import SwiftUI

struct SettingsView: View {
    @AppStorage("moltbotHost") private var host = "127.0.0.1"
    @AppStorage("moltbotPort") private var port = "18789"
    @AppStorage("moltbotToken") private var token = ""
    @AppStorage("useSecureConnection") private var useSecureConnection = false

    var body: some View {
        Form {
            Section {
                TextField("Host", text: $host)
                    .textFieldStyle(.roundedBorder)

                TextField("Port", text: $port)
                    .textFieldStyle(.roundedBorder)

                Toggle("Use Secure Connection (wss://)", isOn: $useSecureConnection)
            } header: {
                Text("Connection")
            }

            Section {
                SecureField("Bearer Token (optional for localhost)", text: $token)
                    .textFieldStyle(.roundedBorder)

                Text("Leave empty when connecting to localhost")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Authentication")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The widget connects directly to your Moltbot instance using WebSocket RPC to fetch cron job statistics.")

                    Text("Default Moltbot gateway runs on ws://127.0.0.1:18789")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Note: Widget uses the same default settings. For custom configurations, the widget will use localhost:18789.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 350)
        .padding()
    }
}

#Preview {
    SettingsView()
}

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
                SecureField("Gateway Token", text: $token)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Find your gateway token in:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("~/.clawdbot/clawdbot.json → gateway.auth.token")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            } header: {
                Text("Authentication")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The widget connects to your Moltbot instance using WebSocket RPC to fetch cron job statistics.")

                    Text("Default Moltbot gateway runs on ws://127.0.0.1:18789")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
        .padding()
    }
}

#Preview {
    SettingsView()
}

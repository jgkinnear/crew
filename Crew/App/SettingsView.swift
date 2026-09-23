import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: CrewSession

    var body: some View {
        TabView {
            Form {
                Section("Huddle") {
                    TextField("Display name", text: $session.displayName)
                    LabeledContent("Room", value: session.config.room)
                    LabeledContent("LiveKit", value: session.config.url)
                }
                Section("About") {
                    Text("System voice follows the mic mode already set in macOS. All sound turns that processing off.")
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("General", systemImage: "gear") }

            IsolationInspector()
                .tabItem { Label("Isolation", systemImage: "waveform.and.mic") }
        }
        .frame(width: 560, height: 640)
        .preferredColorScheme(.dark)
    }
}

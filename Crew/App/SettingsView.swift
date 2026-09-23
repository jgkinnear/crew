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
                    Text("Native Mac Crew uses Apple Mic Modes through Voice Processing I/O, plus optional Krisp on LiveKit Cloud.")
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

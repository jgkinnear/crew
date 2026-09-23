import SwiftUI

@main
struct CrewApp: App {
    @StateObject private var session = CrewSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .defaultSize(width: 1240, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Huddle") {
                Button(session.isMicEnabled ? "Mute" : "Unmute") {
                    Task { await session.toggleMic() }
                }
                .keyboardShortcut("m", modifiers: [.command])
                .disabled(!session.isConnected)

                Button(session.isSharing ? "Stop Sharing" : "Share Screen…") {
                    Task { await session.presentSharePicker() }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(!session.isConnected)

                Divider()

                Button(session.capture.mode == .system ? "System Voice ✓" : "System Voice") {
                    Task { await session.setMicMode(.system) }
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                Button(session.capture.mode == .open ? "All Sound ✓" : "All Sound") {
                    Task { await session.setMicMode(.open) }
                }

                Divider()

                Button("Leave") {
                    Task { await session.leave() }
                }
                .disabled(!session.isConnected)
            }
            CommandMenu("Annotate") {
                Button("Pointer") { session.toolMode = session.toolMode == .pointer ? .none : .pointer }
                    .keyboardShortcut("p", modifiers: [.command])
                Button("Draw") { session.toolMode = session.toolMode == .draw ? .none : .draw }
                    .keyboardShortcut("d", modifiers: [.command])
                Divider()
                Button("Clear Mine") { Task { await session.clearMine() } }
                Button("Clear All") { Task { await session.clearAll() } }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var session: CrewSession

    var body: some View {
        Group {
            if session.isConnected {
                RoomView()
            } else {
                JoinView()
            }
        }
        .frame(minWidth: 960, minHeight: 660)
        .background(CrewTheme.bg)
    }
}

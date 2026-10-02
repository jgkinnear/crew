import AppKit
import SwiftUI

final class CrewAppDelegate: NSObject, NSApplicationDelegate {
    var onQuit: (() async -> Void)?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let onQuit = onQuit
        Task { @MainActor in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await onQuit?() }
                group.addTask {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                }
                await group.next()
                group.cancelAll()
            }
            NSApplication.shared.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}

@main
struct CrewApp: App {
    @NSApplicationDelegateAdaptor(CrewAppDelegate.self) private var appDelegate
    @StateObject private var session = CrewSession()
    @StateObject private var updater = CrewUpdater()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(updater)
                .preferredColorScheme(.dark)
                .onAppear { appDelegate.onQuit = { await session.leave() } }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .defaultSize(width: 1240, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updater.check()
                }
                .disabled(!updater.canCheck)
            }
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

                Button(session.capture.mode == .isolation ? "Voice Isolation ✓" : "Voice Isolation") {
                    Task { await session.setMicMode(.isolation) }
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                Button(session.capture.mode == .open ? "All Sounds ✓" : "All Sounds") {
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

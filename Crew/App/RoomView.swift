import SwiftUI

struct RoomView: View {
    @EnvironmentObject private var session: CrewSession
    @State private var inspectorOpen = true

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(spacing: 0) {
                header
                HStack(spacing: 0) {
                    ParticipantList()
                        .frame(width: 232)
                    StageView()
                    if inspectorOpen {
                        IsolationInspector()
                            .frame(width: 312)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: inspectorOpen)
        .sheet(isPresented: $session.isSharePickerPresented) {
            SharePickerSheet()
        }
        .alert(
            "Crew",
            isPresented: Binding(
                get: { session.connectionError != nil && session.isConnected },
                set: { if !$0 { session.connectionError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { session.connectionError = nil }
        } message: {
            Text(session.connectionError ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(CrewTheme.accentGradient)
                        .frame(width: 22, height: 22)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("Crew")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text("·")
                    .foregroundStyle(CrewTheme.faint)
                Text(session.config.room)
                    .foregroundStyle(CrewTheme.dim)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }

            Spacer()

            UpdateAvailableButton()
            LivePill()
            if !session.activeSpeakers.isEmpty {
                SpeakingChip(speakers: session.activeSpeakers)
            }
            Text(peopleLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(CrewTheme.dim)

            Button {
                inspectorOpen.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(inspectorOpen ? CrewTheme.accent2 : CrewTheme.dim)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(inspectorOpen ? 0.1 : 0.04), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Sound")
        }
        .foregroundStyle(CrewTheme.text)
        .padding(.leading, 86)
        .padding(.trailing, 18)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var peopleLabel: String {
        let count = session.participants.count
        return count == 1 ? "1 person" : "\(count) people"
    }
}

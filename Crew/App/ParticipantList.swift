import LiveKit
import SwiftUI

struct ParticipantList: View {
    @EnvironmentObject private var session: CrewSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "People")
                .padding(.horizontal, 6)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(session.participants, id: \.idForList) { participant in
                        ParticipantRow(
                            participant: participant,
                            isLocal: participant.identity == session.room.localParticipant.identity,
                            isSharing: session.activeShare?.participant.identity == participant.identity
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color.black.opacity(0.18))
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(CrewTheme.stroke)
                .frame(width: 1)
        }
    }
}

private struct ParticipantRow: View {
    @EnvironmentObject private var session: CrewSession
    @ObservedObject var participant: Participant
    let isLocal: Bool
    let isSharing: Bool

    var body: some View {
        HStack(spacing: 10) {
            CrewAvatar(
                name: displayName,
                identity: identity,
                size: 34,
                speaking: talking,
                sharing: isSharing
            )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CrewTheme.text)
                        .lineLimit(1)
                    if isLocal {
                        Text("you")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .foregroundStyle(CrewTheme.accent2)
                            .background(CrewTheme.accent2.opacity(0.14), in: Capsule())
                    }
                }
                HStack(spacing: 5) {
                    Image(systemName: microphoneOn ? "mic.fill" : "mic.slash.fill")
                        .foregroundStyle(microphoneOn ? (talking ? CrewTheme.accent2 : CrewTheme.success) : CrewTheme.faint)
                    if talking {
                        SpeakingBars()
                        Text(isLocal ? "you’re talking" : "talking")
                            .foregroundStyle(CrewTheme.accent2)
                    } else if !microphoneOn {
                        Text("muted")
                            .foregroundStyle(CrewTheme.faint)
                    }
                    if isSharing {
                        Text("sharing")
                            .foregroundStyle(CrewTheme.accent)
                    }
                }
                .font(.system(size: 10, weight: .medium))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(talking ? CrewTheme.accent2.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(talking ? CrewTheme.accent2.opacity(0.35) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.18), value: talking)
        .animation(.easeInOut(duration: 0.18), value: microphoneOn)
    }

    private var identity: String {
        participant.identity?.stringValue ?? "guest"
    }

    private var displayName: String {
        participant.name?.isEmpty == false ? participant.name! : identity
    }

    private var microphoneOn: Bool {
        if isLocal {
            return session.isMicEnabled
        }
        return participant.isMicrophoneEnabled()
    }

    private var talking: Bool {
        microphoneOn && (participant.isSpeaking || session.isSpeaking(identity))
    }
}

extension Participant {
    var idForList: String {
        identity?.stringValue ?? sid?.stringValue ?? UUID().uuidString
    }
}

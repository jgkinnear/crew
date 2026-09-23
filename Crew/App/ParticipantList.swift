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
                            isSharing: session.activeShare?.participant.identity == participant.identity,
                            speaking: session.isSpeaking(participant.identity?.stringValue ?? "")
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
    let participant: Participant
    let isLocal: Bool
    let isSharing: Bool
    let speaking: Bool

    var body: some View {
        HStack(spacing: 10) {
            CrewAvatar(
                name: displayName,
                identity: identity,
                size: 34,
                speaking: speaking,
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
                    Image(systemName: micMuted ? "mic.slash" : "mic.fill")
                        .foregroundStyle(micMuted ? CrewTheme.faint : CrewTheme.success)
                    if speaking {
                        SpeakingBars()
                        Text(isLocal ? "you’re talking" : "talking")
                            .foregroundStyle(CrewTheme.accent2)
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
                .fill(speaking ? CrewTheme.accent2.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(speaking ? CrewTheme.accent2.opacity(0.35) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.18), value: speaking)
    }

    private var identity: String {
        participant.identity?.stringValue ?? "guest"
    }

    private var displayName: String {
        participant.name?.isEmpty == false ? participant.name! : identity
    }

    private var micMuted: Bool {
        if let pub = participant.trackPublications.values.first(where: { $0.source == .microphone }) {
            return pub.isMuted
        }
        return true
    }
}

extension Participant {
    var idForList: String {
        identity?.stringValue ?? sid?.stringValue ?? UUID().uuidString
    }
}

import SwiftUI

struct JoinView: View {
    @EnvironmentObject private var session: CrewSession
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(spacing: 0) {
                HStack {
                    wordmark
                    Spacer()
                    UpdateAvailableButton()
                }
                .padding(.leading, 86)
                .padding(.trailing, 24)
                .padding(.top, 18)
                .padding(.bottom, 8)

                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Step into the huddle")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(CrewTheme.text)
                        Text("Persistent voice, screen share, and annotations. The mic follows the macOS voice mode, or you can let all sound through.")
                            .font(.system(size: 14.5))
                            .foregroundStyle(CrewTheme.dim)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display name")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CrewTheme.faint)
                        TextField("Your name", text: $session.displayName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 17, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.08))
                            )
                            .focused($nameFocused)
                            .onSubmit { Task { await session.join() } }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundStyle(CrewTheme.accent2)
                        Text(session.config.room)
                            .foregroundStyle(CrewTheme.dim)
                        Spacer()
                        if !session.config.isConfigured {
                            Text("Local LiveKit")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption.weight(.medium))

                    if let error = session.connectionError {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(CrewTheme.danger)
                    }

                    Button {
                        Task { await session.join() }
                    } label: {
                        HStack {
                            Spacer()
                            if session.isJoining {
                                ProgressView().controlSize(.small)
                            }
                            Text(session.isJoining ? "Joining" : "Join")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .frame(height: 44)
                        .background(CrewTheme.accentGradient, in: Capsule())
                        .shadow(color: CrewTheme.accent.opacity(0.4), radius: 18, y: 8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                    .disabled(session.isJoining || session.displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(session.displayName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1)
                }
                .padding(28)
                .frame(maxWidth: 440)
                .crewGlass(corner: 22)

                Spacer(minLength: 48)
            }
        }
        .onAppear { nameFocused = true }
    }

    private var wordmark: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(CrewTheme.accentGradient)
                    .frame(width: 26, height: 26)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("Crew")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(CrewTheme.text)
        }
    }
}

import SwiftUI

struct IsolationInspector: View {
    @EnvironmentObject private var session: CrewSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                modes
                sounds
            }
            .padding(16)
        }
        .background(Color.black.opacity(0.22))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(CrewTheme.stroke)
                .frame(width: 1)
        }
    }

    private var modes: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Sound")

            ForEach(MicProcessingMode.allCases) { mode in
                Button {
                    Task { await session.setMicMode(mode) }
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: mode.symbolName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isActive(mode) ? CrewTheme.accent2 : CrewTheme.dim)
                            .frame(width: 22)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(mode.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(CrewTheme.text)
                                if isActive(mode) {
                                    Text("ON")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(CrewTheme.bg)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(CrewTheme.accent2, in: Capsule())
                                }
                            }
                            Text(detail(for: mode))
                                .font(.system(size: 11))
                                .foregroundStyle(CrewTheme.faint)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isActive(mode) ? CrewTheme.accent2.opacity(0.10) : Color.white.opacity(0.035))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isActive(mode) ? CrewTheme.accent2.opacity(0.45) : CrewTheme.stroke)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sounds: some View {
        toggleRow(isOn: $session.soundsEnabled, title: "Join and leave sounds", subtitle: "Chime when someone enters or exits.")
    }

    private func isActive(_ mode: MicProcessingMode) -> Bool {
        session.capture.mode == mode
    }

    private func detail(for mode: MicProcessingMode) -> String {
        switch mode {
        case .system:
            return "macOS is set to \(session.systemMicMode). \(mode.subtitle)"
        case .open:
            return mode.subtitle
        }
    }

    private func toggleRow(isOn: Binding<Bool>, title: String, subtitle: String) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CrewTheme.text)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(CrewTheme.faint)
            }
        }
        .toggleStyle(.switch)
        .padding(.vertical, 4)
    }
}

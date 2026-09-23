import AVFoundation
import SwiftUI

struct IsolationInspector: View {
    @EnvironmentObject private var session: CrewSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                appleModes
                krisp
                capture
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

    private var appleModes: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Mic Mode")
            Text("Apple’s Neural Engine filter. Crew opens Control Center — macOS keeps the switch.")
                .font(.system(size: 12))
                .foregroundStyle(CrewTheme.dim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(AVCaptureDevice.MicrophoneMode.huddleModes, id: \.self) { mode in
                Button {
                    session.isolation.openSystemPicker()
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: mode.symbolName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(session.isolation.active == mode ? CrewTheme.accent2 : CrewTheme.dim)
                            .frame(width: 22)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(mode.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(CrewTheme.text)
                                if session.isolation.active == mode {
                                    Text("ON")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(CrewTheme.bg)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(CrewTheme.accent2, in: Capsule())
                                }
                            }
                            Text(mode.subtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(CrewTheme.faint)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(session.isolation.active == mode ? CrewTheme.accent2.opacity(0.10) : Color.white.opacity(0.035))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(session.isolation.active == mode ? CrewTheme.accent2.opacity(0.45) : CrewTheme.stroke)
                    )
                }
                .buttonStyle(.plain)
            }

            if session.isolation.preferred != session.isolation.active {
                Text("Preferred \(session.isolation.preferredTitle), active \(session.isolation.activeTitle). Some headphones skip Voice Isolation.")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
            }
        }
    }

    private var krisp: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Enhanced")
            toggleRow(isOn: krispBinding, title: "Krisp", subtitle: "LiveKit Cloud speech model, on top of Mic Mode.")
        }
    }

    private var capture: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Capture")
            Text("Voice Processing I/O. Echo cancellation must stay on or Mic Mode will not apply.")
                .font(.system(size: 11))
                .foregroundStyle(CrewTheme.faint)
            toggleRow(keyPath: \.echoCancellation, title: "Echo cancellation", subtitle: "Required for Voice Isolation.")
            toggleRow(keyPath: \.autoGainControl, title: "Auto level", subtitle: "Evens out loud and quiet talking.")
            toggleRow(keyPath: \.noiseSuppression, title: "WebRTC suppression", subtitle: "Leave off when Isolation is active.")
            toggleRow(keyPath: \.typingNoiseDetection, title: "Typing detection", subtitle: "WebRTC keyboard-click suppressor.")
            toggleRow(keyPath: \.highpassFilter, title: "High-pass filter", subtitle: "Drops rumble and low hum.")
        }
    }

    private var sounds: some View {
        toggleRow(isOn: $session.soundsEnabled, title: "Join and leave sounds", subtitle: "Chime when someone enters or exits.")
    }

    private var krispBinding: Binding<Bool> {
        Binding(
            get: { session.capture.krispEnabled },
            set: { value in
                session.capture.krispEnabled = value
                Task { await session.applyCaptureSettings() }
            }
        )
    }

    private func toggleRow(keyPath: WritableKeyPath<CaptureSettings, Bool>, title: String, subtitle: String) -> some View {
        toggleRow(isOn: binding(keyPath), title: title, subtitle: subtitle)
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

    private func binding(_ keyPath: WritableKeyPath<CaptureSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { session.capture[keyPath: keyPath] },
            set: { value in
                session.capture[keyPath: keyPath] = value
                Task { await session.applyCaptureSettings() }
            }
        )
    }
}

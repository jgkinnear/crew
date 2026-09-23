import AVFoundation
import Combine
import Foundation

/// Apple's system microphone modes. These only apply when the capture path
/// uses Voice Processing I/O (LiveKit's default with echo cancellation on).
/// The app cannot set the mode itself — macOS keeps the user in control —
/// but we can show the current mode and open Control Center to change it.
@MainActor
final class MicIsolation: ObservableObject {
    @Published private(set) var preferred: AVCaptureDevice.MicrophoneMode
    @Published private(set) var active: AVCaptureDevice.MicrophoneMode

    private var pollTimer: Timer?

    init() {
        preferred = AVCaptureDevice.preferredMicrophoneMode
        active = AVCaptureDevice.activeMicrophoneMode
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    deinit {
        pollTimer?.invalidate()
    }

    func refresh() {
        preferred = AVCaptureDevice.preferredMicrophoneMode
        active = AVCaptureDevice.activeMicrophoneMode
    }

    /// Opens the system Mic Mode picker. Call this when the user taps a mode.
    func openSystemPicker() {
        AVCaptureDevice.showSystemUserInterface(.microphoneModes)
        // Control Center is not a blocking UI; poll briefly after it closes.
        Task {
            for _ in 0 ..< 20 {
                try? await Task.sleep(for: .milliseconds(400))
                refresh()
            }
        }
    }

    var preferredTitle: String { preferred.displayName }
    var activeTitle: String { active.displayName }
    var isVoiceIsolationActive: Bool { active == .voiceIsolation }
}

extension AVCaptureDevice.MicrophoneMode {
    var displayName: String {
        switch self {
        case .voiceIsolation: return "Voice Isolation"
        case .wideSpectrum: return "Wide Spectrum"
        case .standard: return "Standard"
        @unknown default: return "Unknown"
        }
    }

    var subtitle: String {
        switch self {
        case .voiceIsolation:
            return "Keeps your voice and drops keyboards, fans, whistles, and other non-speech."
        case .wideSpectrum:
            return "Captures the room as-is. Echo cancellation stays on, isolation does not."
        case .standard:
            return "Apple’s balanced processing. Softer than Voice Isolation."
        @unknown default:
            return ""
        }
    }

    var symbolName: String {
        switch self {
        case .voiceIsolation: return "waveform.and.mic"
        case .wideSpectrum: return "dot.radiowaves.left.and.right"
        case .standard: return "mic"
        @unknown default: return "mic"
        }
    }

    static var huddleModes: [AVCaptureDevice.MicrophoneMode] {
        [.voiceIsolation, .standard, .wideSpectrum]
    }
}

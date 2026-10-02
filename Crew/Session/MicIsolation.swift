import LiveKit

/// Voice isolation keeps the speaker and drops the room. All sounds leaves the mic open.
enum MicProcessingMode: String, CaseIterable, Identifiable {
    case isolation
    case open

    var id: String { rawValue }

    var title: String {
        switch self {
        case .isolation: return "Voice isolation"
        case .open: return "All sounds"
        }
    }

    var subtitle: String {
        switch self {
        case .isolation:
            return "Keeps your voice and removes room noise, keyboards, and the other person's audio."
        case .open:
            return "Everything in the room comes through. The other person's audio is still removed so it does not echo."
        }
    }

    var symbolName: String {
        switch self {
        case .isolation: return "waveform.and.mic"
        case .open: return "mic"
        }
    }
}

struct CaptureSettings: Equatable {
    var mode: MicProcessingMode

    static func preset(_ mode: MicProcessingMode) -> CaptureSettings {
        CaptureSettings(mode: mode)
    }

    var krispEnabled: Bool { mode == .isolation }

    func makeCaptureOptions() -> AudioCaptureOptions {
        switch mode {
        case .isolation:
            return AudioCaptureOptions(
                echoCancellation: true,
                autoGainControl: true,
                noiseSuppression: true,
                highpassFilter: true,
                typingNoiseDetection: true,
                echoCancellationMode: .software,
                autoGainControlMode: .software,
                noiseSuppressionMode: .software
            )
        case .open:
            return AudioCaptureOptions(
                echoCancellation: true,
                autoGainControl: false,
                noiseSuppression: false,
                highpassFilter: false,
                typingNoiseDetection: false,
                echoCancellationMode: .software
            )
        }
    }
}

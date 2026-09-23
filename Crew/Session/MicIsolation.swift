import AVFoundation
import LiveKit

/// Two mic paths. System follows the macOS mic mode already chosen in Control Center.
/// Open turns voice processing off so isolation does not apply.
enum MicProcessingMode: String, CaseIterable, Identifiable {
    case system
    case open

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System voice"
        case .open: return "All sound"
        }
    }

    var subtitle: String {
        switch self {
        case .system:
            return "Uses the mic mode macOS already has. Crew does not open Control Center."
        case .open:
            return "Isolation off. Keyboards, room noise, and everything else come through."
        }
    }

    var symbolName: String {
        switch self {
        case .system: return "waveform.and.mic"
        case .open: return "mic"
        }
    }
}

struct CaptureSettings: Equatable {
    var mode: MicProcessingMode

    static func preset(_ mode: MicProcessingMode) -> CaptureSettings {
        CaptureSettings(mode: mode)
    }

    /// Krisp is not part of either mode. The filter stays installed and disabled.
    var krispEnabled: Bool { false }

    func makeCaptureOptions() -> AudioCaptureOptions {
        switch mode {
        case .system:
            return AudioCaptureOptions(
                echoCancellation: true,
                autoGainControl: true,
                noiseSuppression: false,
                highpassFilter: false,
                typingNoiseDetection: false,
                echoCancellationMode: .platform,
                autoGainControlMode: .platform
            )
        case .open:
            return .noProcessing
        }
    }
}

enum SystemMic {
    static var activeTitle: String {
        AVCaptureDevice.activeMicrophoneMode.crewTitle
    }
}

extension AVCaptureDevice.MicrophoneMode {
    var crewTitle: String {
        switch self {
        case .standard: return "Standard"
        case .voiceIsolation: return "Voice Isolation"
        case .wideSpectrum: return "Wide Spectrum"
        @unknown default: return "System"
        }
    }
}

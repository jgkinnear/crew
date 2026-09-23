import Combine
import Foundation
import LiveKit
import LiveKitKrispNoiseFilter

/// Krisp must outlive the room. The Cloud SDK also requires a module-level instance.
let krispFilter = LiveKitKrispNoiseFilter()

enum ToolMode: String, CaseIterable, Identifiable {
    case none, pointer, draw
    var id: String { rawValue }
}

@MainActor
final class CrewSession: ObservableObject {
    let room = Room()
    let collab = CollabStore()

    @Published var config = CrewConfig.load()
    @Published var displayName = UserDefaults.standard.string(forKey: "crew.displayName") ?? ""
    @Published var connectionError: String?
    @Published var isJoining = false
    @Published var isMicEnabled = true
    @Published var isSharing = false
    @Published var shareBlockedReason: String?
    @Published var toolMode: ToolMode = .none
    @Published var capture = CaptureSettings.preset(.system)
    @Published var systemMicMode = SystemMic.activeTitle
    @Published var soundsEnabled = true
    @Published var shareSources: [ShareSourceItem] = []
    @Published var isSharePickerPresented = false
    @Published var isLoadingSources = false
    @Published var speakingIds: Set<String> = []

    private var screenPublication: LocalTrackPublication?
    private var cancellables = Set<AnyCancellable>()
    private var rpcRegistered = false
    private var micModeTimer: Timer?

    var isLocalSharing: Bool {
        activeShare?.participant.identity == room.localParticipant.identity
    }

    var isConnected: Bool {
        room.connectionState == .connected
    }

    var localIdentity: String {
        room.localParticipant.identity?.stringValue ?? ""
    }

    var participants: [Participant] {
        [room.localParticipant] + Array(room.remoteParticipants.values)
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var activeShare: (participant: Participant, track: VideoTrack)? {
        for participant in participants {
            for publication in participant.trackPublications.values where publication.source == .screenShareVideo {
                if !publication.isMuted, let track = publication.track as? VideoTrack {
                    return (participant, track)
                }
            }
        }
        return nil
    }

    var activeSpeakers: [(identity: String, name: String, isLocal: Bool)] {
        participants.compactMap { participant in
            let id = participant.identity?.stringValue ?? ""
            guard speakingIds.contains(id) else { return nil }
            let name = participant.name?.isEmpty == false
                ? participant.name!
                : id
            return (id, name, participant.identity == room.localParticipant.identity)
        }
    }

    func isSpeaking(_ identity: String) -> Bool {
        speakingIds.contains(identity)
    }

    init() {
        AudioManager.shared.capturePostProcessingDelegate = krispFilter
        room.add(delegate: krispFilter)
        room.add(delegate: self)
        krispFilter.isEnabled = false
        refreshSystemMicMode()
        micModeTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshSystemMicMode()
            }
        }

        room.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        collab.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func join() async {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            connectionError = "Enter a display name."
            return
        }
        guard !config.url.isEmpty, !config.apiKey.isEmpty, !config.apiSecret.isEmpty else {
            connectionError = "Missing LiveKit credentials. Add them to the repo .env, then rebuild."
            return
        }

        UserDefaults.standard.set(name, forKey: "crew.displayName")
        isJoining = true
        connectionError = nil
        krispFilter.isEnabled = capture.krispEnabled

        do {
            let identity = "\(slugify(name))-\(Self.shortId())"
            let token = try LiveKitToken.mint(
                apiKey: config.apiKey,
                apiSecret: config.apiSecret,
                identity: identity,
                name: name,
                room: config.room
            )
            try await room.connect(url: config.url, token: token)
            try await registerCollabRPC()
            try await room.localParticipant.setMicrophone(
                enabled: true,
                captureOptions: audioCaptureOptions()
            )
            isMicEnabled = true
            await requestAnnotationSnapshot()
        } catch {
            connectionError = error.localizedDescription
            try? await room.disconnect()
        }
        isJoining = false
    }

    func leave() async {
        toolMode = .none
        collab.reset()
        screenPublication = nil
        isSharing = false
        speakingIds = []
        try? await room.disconnect()
    }

    func setMicMode(_ mode: MicProcessingMode) async {
        capture = .preset(mode)
        await applyCaptureSettings()
    }

    func toggleMic() async {
        do {
            let next = !isMicEnabled
            try await room.localParticipant.setMicrophone(
                enabled: next,
                captureOptions: audioCaptureOptions()
            )
            isMicEnabled = next
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func applyCaptureSettings() async {
        krispFilter.isEnabled = capture.krispEnabled
        guard isConnected, isMicEnabled else { return }
        do {
            try await room.localParticipant.setMicrophone(
                enabled: true,
                captureOptions: audioCaptureOptions()
            )
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func presentSharePicker() async {
        if isLocalSharing {
            await stopShare()
            return
        }
        if let share = activeShare, share.participant.identity != room.localParticipant.identity {
            shareBlockedReason = "\(share.participant.name ?? "Someone") is already sharing"
            return
        }
        isLoadingSources = true
        isSharePickerPresented = true
        defer { isLoadingSources = false }
        do {
            let sources = try await MacOSScreenCapturer.sources(for: .any, includeCurrentApplication: false)
            shareSources = sources.compactMap(ShareSourceItem.init)
        } catch {
            connectionError = "Screen Recording permission is required. Enable Crew in System Settings → Privacy & Security → Screen Recording."
            isSharePickerPresented = false
        }
    }

    func share(_ item: ShareSourceItem) async {
        isSharePickerPresented = false
        do {
            if isSharing {
                await stopShare()
            }
            let options = ScreenShareCaptureOptions(
                dimensions: .h1080_169,
                fps: 12,
                showCursor: true,
                includeCurrentApplication: false
            )
            let track = await LocalVideoTrack.createMacOSScreenShareTrack(
                source: item.source,
                options: options
            )
            screenPublication = try await room.localParticipant.publish(videoTrack: track)
            isSharing = true
            shareBlockedReason = nil
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func stopShare() async {
        do {
            if let publication = screenPublication {
                try await room.localParticipant.unpublish(publication: publication)
            } else {
                try await room.localParticipant.setScreenShare(enabled: false)
            }
        } catch {
            connectionError = error.localizedDescription
        }
        screenPublication = nil
        isSharing = false
        toolMode = .none
        collab.reset()
    }

    func publishStroke(_ event: StrokeEvent) async {
        collab.handle(.stroke(event), ignoringLocalPointer: nil)
        await send(.stroke(event), reliable: true, topic: CollabTopic.stroke)
    }

    func publishPointer(_ event: PointerEvent) async {
        await send(.pointer(event), reliable: false, topic: CollabTopic.pointer)
    }

    func clearMine() async {
        let event = ClearEvent(scope: .self, identity: localIdentity)
        collab.handle(.clear(event), ignoringLocalPointer: nil)
        await send(.clear(event), reliable: true, topic: CollabTopic.clear)
    }

    func clearAll() async {
        let event = ClearEvent(scope: .all, identity: localIdentity)
        collab.handle(.clear(event), ignoringLocalPointer: nil)
        await send(.clear(event), reliable: true, topic: CollabTopic.clear)
    }

    private func send(_ event: CollabEvent, reliable: Bool, topic: String) async {
        guard let data = CollabCodec.encode(event) else { return }
        do {
            try await room.localParticipant.publish(
                data: data,
                options: DataPublishOptions(topic: topic, reliable: reliable)
            )
        } catch {
            connectionError = error.localizedDescription
        }
    }

    private func refreshSystemMicMode() {
        let title = SystemMic.activeTitle
        if title != systemMicMode {
            systemMicMode = title
        }
    }

    private func audioCaptureOptions() -> AudioCaptureOptions {
        capture.makeCaptureOptions()
    }

    private func registerCollabRPC() async throws {
        guard !rpcRegistered else { return }
        try await room.registerRpcMethod(CollabTopic.getAnnotations) { [weak self] _ in
            await MainActor.run {
                self?.collab.snapshotJSON() ?? "{}"
            }
        }
        rpcRegistered = true
    }

    private func requestAnnotationSnapshot() async {
        for participant in room.remoteParticipants.values {
            guard let identity = participant.identity else { continue }
            do {
                let raw = try await room.localParticipant.performRpc(
                    destinationIdentity: identity,
                    method: CollabTopic.getAnnotations,
                    payload: "",
                    responseTimeout: 5
                )
                if let data = raw.data(using: .utf8),
                   let snapshot = try? JSONDecoder().decode(AnnotationSnapshot.self, from: data)
                {
                    collab.replace(strokes: snapshot.strokes)
                    return
                }
            } catch {
                continue
            }
        }
    }

    private func slugify(_ name: String) -> String {
        let slug = name.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: "-")
        return slug.isEmpty ? "guest" : slug
    }

    private static func shortId() -> String {
        String(UUID().uuidString.prefix(6)).lowercased()
    }
}

extension CrewSession: RoomDelegate {
    nonisolated func room(_ room: Room, participant: RemoteParticipant?, didReceiveData data: Data, forTopic topic: String, encryptionType: EncryptionType) {
        guard topic == CollabTopic.stroke || topic == CollabTopic.pointer || topic == CollabTopic.clear else { return }
        guard let event = CollabCodec.decode(data) else { return }
        Task { @MainActor in
            self.collab.handle(event, ignoringLocalPointer: self.localIdentity)
        }
    }

    nonisolated func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        Task { @MainActor in
            if self.soundsEnabled { HuddleSounds.join() }
        }
    }

    nonisolated func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        let identity = participant.identity?.stringValue
        Task { @MainActor in
            if let identity {
                self.speakingIds.remove(identity)
            }
            if self.soundsEnabled { HuddleSounds.leave() }
        }
    }

    nonisolated func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) {
        let ids = Set(participants.compactMap { $0.identity?.stringValue })
        Task { @MainActor in
            self.speakingIds = ids
        }
    }

    nonisolated func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
        Task { @MainActor in
            self.isSharing = false
            self.screenPublication = nil
            self.toolMode = .none
            self.speakingIds = []
            if let error {
                self.connectionError = error.localizedDescription
            }
        }
    }
}

struct ShareSourceItem: Identifiable {
    let id: ObjectIdentifier
    let source: MacOSScreenCaptureSource
    let title: String
    let subtitle: String
    let kind: Kind

    enum Kind { case display, window }

    init?(_ source: MacOSScreenCaptureSource) {
        id = ObjectIdentifier(source as AnyObject)
        self.source = source
        if let display = source as? MacOSDisplay {
            title = "Display"
            subtitle = "\(display.width) × \(display.height)"
            kind = .display
        } else if let window = source as? MacOSWindow {
            title = window.title?.isEmpty == false ? (window.title ?? "Window") : "Window"
            subtitle = window.owningApplication?.applicationName ?? "App"
            kind = .window
        } else {
            return nil
        }
    }
}

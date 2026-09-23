import LiveKit
import SwiftUI

struct StageView: View {
    @EnvironmentObject private var session: CrewSession

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let share = session.activeShare {
                    ShareCanvas(
                        track: share.track,
                        sharerName: share.participant.name ?? share.participant.identity?.stringValue ?? "Screen",
                        isLocalShare: share.participant.identity == session.room.localParticipant.identity
                    )
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 78)

            VStack {
                if !session.activeSpeakers.isEmpty {
                    SpeakingBanner(speakers: session.activeSpeakers)
                        .padding(.top, 10)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .allowsHitTesting(false)

            HuddleDock()
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CrewTheme.accent.opacity(0.14))
                    .frame(width: 92, height: 92)
                    .blur(radius: 2)
                Image(systemName: "rectangle.dashed.badge.record")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(CrewTheme.accentGradient)
            }
            Text("Waiting for a screen")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(CrewTheme.text)
            Text("Share a display or window. Everyone else can point and draw on it in realtime.")
                .font(.system(size: 13.5))
                .foregroundStyle(CrewTheme.dim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button {
                Task { await session.presentSharePicker() }
            } label: {
                Text("Share screen")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(CrewTheme.accentGradient, in: Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.025))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                        .foregroundStyle(CrewTheme.strokeStrong)
                )
        )
    }
}

private struct HuddleDock: View {
    @EnvironmentObject private var session: CrewSession

    var body: some View {
        HStack(spacing: 6) {
            DockButton(
                icon: session.isMicEnabled ? "mic.fill" : "mic.slash.fill",
                title: session.isMicEnabled ? "Mic" : "Muted",
                tint: session.isMicEnabled ? CrewTheme.success : CrewTheme.danger,
                warning: !session.isMicEnabled
            ) {
                Task { await session.toggleMic() }
            }

            Menu {
                ForEach(MicProcessingMode.allCases) { mode in
                    Button {
                        Task { await session.setMicMode(mode) }
                    } label: {
                        if session.capture.mode == mode {
                            Label(mode.title, systemImage: "checkmark")
                        } else {
                            Text(mode.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: session.capture.mode.symbolName)
                        .font(.system(size: 14, weight: .semibold))
                    Text(session.capture.mode.title)
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .foregroundStyle(CrewTheme.text)
                .frame(height: 36)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.06), in: Capsule())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help(session.capture.mode == .system ? "System voice · \(session.systemMicMode)" : "All sound")

            DockButton(
                icon: session.isSharing ? "stop.fill" : "rectangle.dashed.badge.record",
                title: session.isSharing ? "Stop" : "Share",
                emphasized: session.isSharing,
                disabled: session.activeShare != nil && !session.isLocalSharing
            ) {
                Task { await session.presentSharePicker() }
            }

            capsuleDivider

            DockButton(
                icon: "cursorarrow.rays",
                emphasized: session.toolMode == .pointer,
                disabled: session.activeShare == nil
            ) {
                session.toolMode = session.toolMode == .pointer ? .none : .pointer
            }

            DockButton(
                icon: "pencil.tip",
                emphasized: session.toolMode == .draw,
                disabled: session.activeShare == nil
            ) {
                session.toolMode = session.toolMode == .draw ? .none : .draw
            }

            Menu {
                Button("Clear mine") { Task { await session.clearMine() } }
                Button("Clear all", role: .destructive) { Task { await session.clearAll() } }
            } label: {
                Image(systemName: "eraser")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CrewTheme.text)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.06), in: Capsule())
            }
            .menuStyle(.borderlessButton)
            .disabled(session.activeShare == nil)
            .opacity(session.activeShare == nil ? 0.35 : 1)

            capsuleDivider

            DockButton(icon: "rectangle.portrait.and.arrow.right", warning: true) {
                Task { await session.leave() }
            }
        }
        .padding(7)
        .crewGlass(corner: 28)
    }

    private var capsuleDivider: some View {
        Rectangle()
            .fill(CrewTheme.strokeStrong)
            .frame(width: 1, height: 18)
            .padding(.horizontal, 4)
    }
}

private struct ShareCanvas: View {
    @EnvironmentObject private var session: CrewSession
    let track: VideoTrack
    let sharerName: String
    let isLocalShare: Bool

    @State private var content = ContentRect(left: 0, top: 0, width: 0, height: 0)
    @State private var strokeId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.inset.filled")
                        .foregroundStyle(CrewTheme.accent2)
                    Text("\(sharerName)’s screen")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(CrewTheme.text)
                }
                Spacer()
                if session.toolMode != .none {
                    Text(session.toolMode == .draw ? "Drawing" : "Pointing")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CrewTheme.accent2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CrewTheme.accent2.opacity(0.12), in: Capsule())
                }
            }

            GeometryReader { geo in
                ZStack {
                    SwiftUIVideoView(track, layoutMode: .fit)
                    AnnotationOverlay(content: content)
                }
                .contentShape(Rectangle())
                .gesture(drawGesture)
                .onContinuousHover { phase in
                    handleHover(phase)
                }
                .onAppear { updateContent(in: geo.size) }
                .onChange(of: geo.size) { _, size in updateContent(in: size) }
                .onChange(of: track.dimensions) { _, _ in updateContent(in: geo.size) }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(CrewTheme.strokeStrong)
            )
            .shadow(color: .black.opacity(0.45), radius: 28, y: 16)
        }
    }

    private var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard session.toolMode == .draw else { return }
                guard let point = VideoLayout.normalize(point: value.location, content: content) else { return }
                Task {
                    if strokeId == nil {
                        let id = CollabMath.newStrokeId()
                        strokeId = id
                        await session.publishStroke(makeStroke(action: .start, id: id, points: [point]))
                    } else if let id = strokeId {
                        await session.publishStroke(makeStroke(action: .append, id: id, points: [point]))
                    }
                }
            }
            .onEnded { _ in
                if let id = strokeId {
                    Task { await session.publishStroke(makeStroke(action: .end, id: id, points: [])) }
                }
                strokeId = nil
                Task { await session.publishPointer(.ended(identity: session.localIdentity)) }
            }
    }

    private func makeStroke(action: StrokeAction, id: String, points: [Point]) -> StrokeEvent {
        StrokeEvent(
            action: action,
            strokeId: id,
            participantIdentity: session.localIdentity,
            participantName: session.displayName,
            color: CollabMath.color(for: session.localIdentity),
            points: points
        )
    }

    private func handleHover(_ phase: HoverPhase) {
        guard session.toolMode == .pointer else { return }
        switch phase {
        case .active(let location):
            guard let point = VideoLayout.normalize(point: location, content: content) else {
                Task { await session.publishPointer(.ended(identity: session.localIdentity)) }
                return
            }
            Task {
                await session.publishPointer(
                    .active(identity: session.localIdentity, name: session.displayName, x: point.x, y: point.y)
                )
            }
        case .ended:
            Task { await session.publishPointer(.ended(identity: session.localIdentity)) }
        }
    }

    private func updateContent(in size: CGSize) {
        let dims = track.dimensions ?? .h1080_169
        content = VideoLayout.contentRect(
            elementWidth: size.width,
            elementHeight: size.height,
            videoWidth: CGFloat(dims.width),
            videoHeight: CGFloat(dims.height)
        )
    }
}

private struct AnnotationOverlay: View {
    @EnvironmentObject private var session: CrewSession
    let content: ContentRect

    var body: some View {
        Canvas { context, _ in
            for stroke in session.collab.strokes {
                guard stroke.points.count >= 2 else { continue }
                var path = Path()
                let first = VideoLayout.denormalize(stroke.points[0], content: content)
                path.move(to: first)
                if stroke.points.count == 2 {
                    path.addLine(to: VideoLayout.denormalize(stroke.points[1], content: content))
                } else {
                    for i in 1 ..< stroke.points.count - 1 {
                        let current = VideoLayout.denormalize(stroke.points[i], content: content)
                        let next = VideoLayout.denormalize(stroke.points[i + 1], content: content)
                        let mid = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
                        path.addQuadCurve(to: mid, control: current)
                    }
                    path.addLine(to: VideoLayout.denormalize(stroke.points.last!, content: content))
                }
                let color = Color(hex: stroke.color) ?? .orange
                context.stroke(
                    path,
                    with: .color(color.opacity(0.95)),
                    style: StrokeStyle(lineWidth: 3.75, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .allowsHitTesting(false)
        .overlay {
            ForEach(Array(session.collab.pointers.values)) { pointer in
                let point = VideoLayout.denormalize(Point(x: pointer.x, y: pointer.y), content: content)
                pointerView(pointer)
                    .position(point)
            }
        }
    }

    private func pointerView(_ pointer: RemotePointer) -> some View {
        let color = Color(hex: CollabMath.color(for: pointer.identity)) ?? .orange
        return VStack(alignment: .leading, spacing: 3) {
            Image(systemName: "cursorarrow")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.7), radius: 8)
            Text(pointer.name)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(color.opacity(0.45)))
        }
        .offset(x: 8, y: 10)
        .allowsHitTesting(false)
    }
}

import Combine
import Foundation

struct RemotePointer: Equatable, Sendable, Identifiable {
    var identity: String
    var name: String
    var x: Double
    var y: Double
    var updatedAt: Date

    var id: String { identity }
}

@MainActor
final class CollabStore: ObservableObject {
    @Published var strokes: [Stroke] = []
    @Published var pointers: [String: RemotePointer] = [:]

    private var pointerTimer: Timer?

    init() {
        pointerTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.expirePointers()
            }
        }
    }

    deinit {
        pointerTimer?.invalidate()
    }

    func handle(_ event: CollabEvent, ignoringLocalPointer identity: String?) {
        switch event {
        case .stroke(let stroke):
            strokes = CollabMath.apply(stroke: stroke, to: strokes)
        case .clear(let clear):
            strokes = CollabMath.apply(clear: clear, to: strokes)
        case .pointer(let pointer):
            if pointer.identity == identity { return }
            switch pointer {
            case .ended(let id):
                pointers.removeValue(forKey: id)
            case .active(let id, let name, let x, let y):
                pointers[id] = RemotePointer(
                    identity: id,
                    name: name,
                    x: x,
                    y: y,
                    updatedAt: Date()
                )
            }
        }
    }

    func replace(strokes: [Stroke]) {
        self.strokes = strokes
    }

    func reset() {
        strokes = []
        pointers = [:]
    }

    func snapshotJSON() -> String {
        let data = (try? JSONEncoder().encode(AnnotationSnapshot(strokes: strokes))) ?? Data("{}".utf8)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func expirePointers() {
        let cutoff = Date().addingTimeInterval(-CollabTopic.pointerHideMs)
        let next = pointers.filter { $0.value.updatedAt >= cutoff }
        if next.count != pointers.count {
            pointers = next
        }
    }
}

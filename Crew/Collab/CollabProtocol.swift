import Foundation

struct Point: Codable, Hashable, Sendable {
    var x: Double
    var y: Double
}

struct Stroke: Codable, Hashable, Sendable, Identifiable {
    var strokeId: String
    var participantIdentity: String
    var participantName: String
    var color: String
    var points: [Point]

    var id: String { strokeId }
}

enum StrokeAction: String, Codable, Sendable {
    case start, append, end
}

struct StrokeEvent: Codable, Hashable, Sendable {
    var type: String = "stroke"
    var action: StrokeAction
    var strokeId: String
    var participantIdentity: String
    var participantName: String
    var color: String
    var points: [Point]
}

enum PointerEvent: Hashable, Sendable {
    case active(identity: String, name: String, x: Double, y: Double)
    case ended(identity: String)

    var identity: String {
        switch self {
        case .active(let identity, _, _, _): return identity
        case .ended(let identity): return identity
        }
    }
}

extension PointerEvent: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, identity, name, x, y, active
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let identity = try c.decode(String.self, forKey: .identity)
        if (try c.decodeIfPresent(Bool.self, forKey: .active)) == false {
            self = .ended(identity: identity)
            return
        }
        self = .active(
            identity: identity,
            name: try c.decode(String.self, forKey: .name),
            x: try c.decode(Double.self, forKey: .x),
            y: try c.decode(Double.self, forKey: .y)
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode("pointer", forKey: .type)
        try c.encode(identity, forKey: .identity)
        switch self {
        case .active(_, let name, let x, let y):
            try c.encode(true, forKey: .active)
            try c.encode(name, forKey: .name)
            try c.encode(x, forKey: .x)
            try c.encode(y, forKey: .y)
        case .ended:
            try c.encode(false, forKey: .active)
        }
    }
}

struct ClearEvent: Codable, Hashable, Sendable {
    var type: String = "clear"
    var scope: Scope
    var identity: String

    enum Scope: String, Codable, Sendable {
        case `self`, all
    }
}

enum CollabEvent: Sendable {
    case stroke(StrokeEvent)
    case pointer(PointerEvent)
    case clear(ClearEvent)
}

struct AnnotationSnapshot: Codable, Sendable {
    var strokes: [Stroke]
}

enum CollabTopic {
    static let stroke = "huddle.stroke"
    static let pointer = "huddle.pointer"
    static let clear = "huddle.clear"
    static let getAnnotations = "huddle.getAnnotations"
    static let pointerHideMs: TimeInterval = 1.5
}

enum CollabCodec {
    static func encode(_ event: CollabEvent) -> Data? {
        let encoder = JSONEncoder()
        switch event {
        case .stroke(let value): return try? encoder.encode(value)
        case .pointer(let value): return try? encoder.encode(value)
        case .clear(let value): return try? encoder.encode(value)
        }
    }

    static func decode(_ data: Data) -> CollabEvent? {
        let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        switch obj?["type"] as? String {
        case "stroke":
            return (try? JSONDecoder().decode(StrokeEvent.self, from: data)).map { .stroke($0) }
        case "pointer":
            return (try? JSONDecoder().decode(PointerEvent.self, from: data)).map { .pointer($0) }
        case "clear":
            return (try? JSONDecoder().decode(ClearEvent.self, from: data)).map { .clear($0) }
        default:
            return nil
        }
    }
}

enum CollabMath {
    static let palette = [
        "#f97316", "#22c55e", "#3b82f6", "#eab308",
        "#ec4899", "#a855f7", "#14b8a6", "#ef4444",
    ]

    static func color(for identity: String) -> String {
        var hash: UInt32 = 0
        for unit in identity.utf16 {
            hash = hash &* 31 &+ UInt32(unit)
        }
        return palette[Int(hash % UInt32(palette.count))]
    }

    static func apply(stroke event: StrokeEvent, to strokes: [Stroke]) -> [Stroke] {
        if event.action == .start {
            let next = strokes.filter { $0.strokeId != event.strokeId }
            return next + [Stroke(
                strokeId: event.strokeId,
                participantIdentity: event.participantIdentity,
                participantName: event.participantName,
                color: event.color,
                points: event.points
            )]
        }

        if let idx = strokes.firstIndex(where: { $0.strokeId == event.strokeId }) {
            var next = strokes
            next[idx].points.append(contentsOf: event.points)
            return next
        }

        return strokes + [Stroke(
            strokeId: event.strokeId,
            participantIdentity: event.participantIdentity,
            participantName: event.participantName,
            color: event.color,
            points: event.points
        )]
    }

    static func apply(clear event: ClearEvent, to strokes: [Stroke]) -> [Stroke] {
        if event.scope == .all { return [] }
        return strokes.filter { $0.participantIdentity != event.identity }
    }

    static func newStrokeId() -> String {
        "s-\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString.prefix(6).lowercased())"
    }
}

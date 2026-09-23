import XCTest
@testable import Crew

final class CollabCoordsTests: XCTestCase {
    func testPillarbox() {
        let rect = VideoLayout.contentRect(elementWidth: 200, elementHeight: 100, videoWidth: 50, videoHeight: 50)
        XCTAssertEqual(rect.width, 100, accuracy: 0.01)
        XCTAssertEqual(rect.height, 100, accuracy: 0.01)
        XCTAssertEqual(rect.left, 50, accuracy: 0.01)
        XCTAssertEqual(rect.top, 0, accuracy: 0.01)
    }

    func testLetterbox() {
        let rect = VideoLayout.contentRect(elementWidth: 100, elementHeight: 200, videoWidth: 50, videoHeight: 50)
        XCTAssertEqual(rect.width, 100, accuracy: 0.01)
        XCTAssertEqual(rect.height, 100, accuracy: 0.01)
        XCTAssertEqual(rect.left, 0, accuracy: 0.01)
        XCTAssertEqual(rect.top, 50, accuracy: 0.01)
    }

    func testNormalizeInside() {
        let content = ContentRect(left: 10, top: 20, width: 100, height: 50)
        let point = VideoLayout.normalize(point: CGPoint(x: 60, y: 45), content: content)
        XCTAssertEqual(point?.x ?? -1, 0.5, accuracy: 0.001)
        XCTAssertEqual(point?.y ?? -1, 0.5, accuracy: 0.001)
    }

    func testNormalizeOutsideIsNil() {
        let content = ContentRect(left: 10, top: 20, width: 100, height: 50)
        XCTAssertNil(VideoLayout.normalize(point: CGPoint(x: 5, y: 45), content: content))
    }

    func testRoundTrip() {
        let content = ContentRect(left: 8, top: 4, width: 80, height: 40)
        let original = Point(x: 0.25, y: 0.75)
        let pixel = VideoLayout.denormalize(original, content: content)
        let back = VideoLayout.normalize(point: pixel, content: content)
        XCTAssertEqual(back?.x ?? -1, original.x, accuracy: 0.0001)
        XCTAssertEqual(back?.y ?? -1, original.y, accuracy: 0.0001)
    }
}

final class CollabProtocolTests: XCTestCase {
    func testStrokeStartAndAppend() {
        let start = StrokeEvent(
            action: .start,
            strokeId: "s1",
            participantIdentity: "a",
            participantName: "Ann",
            color: "#fff",
            points: [Point(x: 0.1, y: 0.1)]
        )
        let append = StrokeEvent(
            action: .append,
            strokeId: "s1",
            participantIdentity: "a",
            participantName: "Ann",
            color: "#fff",
            points: [Point(x: 0.2, y: 0.2)]
        )
        let strokes = CollabMath.apply(stroke: append, to: CollabMath.apply(stroke: start, to: []))
        XCTAssertEqual(strokes.count, 1)
        XCTAssertEqual(strokes[0].points.count, 2)
    }

    func testClearSelf() {
        let a = Stroke(strokeId: "1", participantIdentity: "a", participantName: "A", color: "#0", points: [])
        let b = Stroke(strokeId: "2", participantIdentity: "b", participantName: "B", color: "#0", points: [])
        let next = CollabMath.apply(clear: ClearEvent(scope: .self, identity: "a"), to: [a, b])
        XCTAssertEqual(next.map(\.strokeId), ["2"])
    }

    func testClearAll() {
        let a = Stroke(strokeId: "1", participantIdentity: "a", participantName: "A", color: "#0", points: [])
        XCTAssertTrue(CollabMath.apply(clear: ClearEvent(scope: .all, identity: "a"), to: [a]).isEmpty)
    }

    func testPointerRoundTrip() {
        let event = PointerEvent.active(identity: "j", name: "Jackson", x: 0.3, y: 0.7)
        let data = try! JSONEncoder().encode(event)
        let decoded = try! JSONDecoder().decode(PointerEvent.self, from: data)
        XCTAssertEqual(decoded, event)
    }
}

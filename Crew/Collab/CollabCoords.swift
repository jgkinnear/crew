import CoreGraphics
import Foundation

struct ContentRect: Equatable, Sendable {
    var left: CGFloat
    var top: CGFloat
    var width: CGFloat
    var height: CGFloat

    var cgRect: CGRect {
        CGRect(x: left, y: top, width: width, height: height)
    }
}

enum VideoLayout {
    static func contentRect(
        elementWidth: CGFloat,
        elementHeight: CGFloat,
        videoWidth: CGFloat,
        videoHeight: CGFloat
    ) -> ContentRect {
        guard elementWidth > 0, elementHeight > 0, videoWidth > 0, videoHeight > 0 else {
            return ContentRect(left: 0, top: 0, width: elementWidth, height: elementHeight)
        }

        let elementRatio = elementWidth / elementHeight
        let videoRatio = videoWidth / videoHeight

        if elementRatio > videoRatio {
            let height = elementHeight
            let width = height * videoRatio
            let left = (elementWidth - width) / 2
            return ContentRect(left: left, top: 0, width: width, height: height)
        }

        let width = elementWidth
        let height = width / videoRatio
        let top = (elementHeight - height) / 2
        return ContentRect(left: 0, top: top, width: width, height: height)
    }

    static func normalize(point: CGPoint, content: ContentRect) -> Point? {
        guard content.width > 0, content.height > 0 else { return nil }
        let x = (point.x - content.left) / content.width
        let y = (point.y - content.top) / content.height
        guard (0 ... 1).contains(x), (0 ... 1).contains(y) else { return nil }
        return Point(x: Double(x), y: Double(y))
    }

    static func denormalize(_ point: Point, content: ContentRect) -> CGPoint {
        CGPoint(
            x: content.left + CGFloat(point.x) * content.width,
            y: content.top + CGFloat(point.y) * content.height
        )
    }

    static func clamp01(_ n: Double) -> Double {
        min(1, max(0, n))
    }
}

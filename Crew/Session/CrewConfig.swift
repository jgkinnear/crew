import Foundation

struct CrewConfig: Equatable, Sendable {
    var url: String
    var apiKey: String
    var apiSecret: String
    var room: String

    var isConfigured: Bool {
        !url.isEmpty && !apiKey.isEmpty && !apiSecret.isEmpty && !room.isEmpty
            && apiSecret != "secret"
    }

    static func load() -> CrewConfig {
        var values = [
            "LIVEKIT_URL": "ws://127.0.0.1:7880",
            "LIVEKIT_API_KEY": "devkey",
            "LIVEKIT_API_SECRET": "secret",
            "LIVEKIT_ROOM": "deckee-huddle",
        ]

        for (key, value) in ProcessInfo.processInfo.environment {
            if values[key] != nil, !value.isEmpty {
                values[key] = value
            }
        }

        for candidate in envFileCandidates() {
            guard let text = try? String(contentsOf: candidate, encoding: .utf8) else { continue }
            for (key, value) in parseEnv(text) {
                values[key] = value
            }
        }

        return CrewConfig(
            url: values["LIVEKIT_URL"] ?? "",
            apiKey: values["LIVEKIT_API_KEY"] ?? "",
            apiSecret: values["LIVEKIT_API_SECRET"] ?? "",
            room: values["LIVEKIT_ROOM"] ?? "deckee-huddle"
        )
    }

    private static func envFileCandidates() -> [URL] {
        var urls: [URL] = []
        if let bundled = Bundle.main.url(forResource: ".env", withExtension: nil) {
            urls.append(bundled)
        }
        // Debug: repo-root .env. Packaged builds use the copy in the app bundle.
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0 ..< 6 {
            urls.append(dir.appendingPathComponent(".env"))
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            dir = parent
        }
        return urls
    }

    private static func parseEnv(_ text: String) -> [String: String] {
        var result: [String: String] = [:]
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
            if (value.hasPrefix("\"") && value.hasSuffix("\""))
                || (value.hasPrefix("'") && value.hasSuffix("'"))
            {
                value = String(value.dropFirst().dropLast())
            }
            result[key] = value
        }
        return result
    }
}

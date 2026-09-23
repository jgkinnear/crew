import Foundation

enum GitHubRelease {
    static let repo = "jgkinnear/crew"
    static let updatesTag = "updates"
    static let appcastName = "appcast.xml"
    static let zipName = "Crew-mac-arm64.zip"

    static var updatesAPI: URL {
        URL(string: "https://api.github.com/repos/\(repo)/releases/tags/\(updatesTag)")!
    }

    static func assetAPIURL(named name: String, in releaseJSON: Data) -> URL? {
        guard
            let json = try? JSONSerialization.jsonObject(with: releaseJSON) as? [String: Any],
            let assets = json["assets"] as? [[String: Any]]
        else { return nil }
        guard let raw = assets.first(where: { $0["name"] as? String == name })?["url"] as? String else {
            return nil
        }
        return URL(string: raw)
    }
}

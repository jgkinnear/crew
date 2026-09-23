import Foundation
import Sparkle

/// Checks the private `updates` GitHub release and lets Sparkle prompt, install, and relaunch.
/// The feed is downloaded with CREW_UPDATE_TOKEN because the repository is private.
final class CrewUpdater: NSObject, SPUUpdaterDelegate, ObservableObject {
    private var controller: SPUStandardUpdaterController?
    private let session: URLSession
    let canCheck: Bool

    override init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        session = URLSession(configuration: configuration, delegate: nil, delegateQueue: queue)
        canCheck = !Self.isRunningTests && !CrewConfig.load().updateToken.isEmpty
        super.init()
        guard canCheck else { return }
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        controller?.updater.checkForUpdatesInBackground()
    }

    func check() {
        controller?.checkForUpdates(nil)
    }

    func feedURLString(for updater: SPUUpdater) -> String? {
        refreshAppcast()?.absoluteString
    }

    func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, with request: NSMutableURLRequest) {
        authorize(request)
    }

    private func refreshAppcast() -> URL? {
        let token = CrewConfig.load().updateToken
        guard !token.isEmpty else { return nil }
        guard
            let release = fetch(GitHubRelease.updatesAPI, token: token, accept: "application/vnd.github+json"),
            let appcastAPI = GitHubRelease.assetAPIURL(named: GitHubRelease.appcastName, in: release),
            let appcast = fetch(appcastAPI, token: token, accept: "application/octet-stream")
        else { return nil }

        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Crew", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent(GitHubRelease.appcastName)
        do {
            try appcast.write(to: file, options: .atomic)
            return file
        } catch {
            return nil
        }
    }

    private func fetch(_ url: URL, token: String, accept: String) -> Data? {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue("Crew", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let semaphore = DispatchSemaphore(value: 0)
        var body: Data?
        let task = session.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) {
                body = data
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 25)
        return body
    }

    private func authorize(_ request: NSMutableURLRequest) {
        let token = CrewConfig.load().updateToken
        guard !token.isEmpty else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        request.setValue("Crew", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

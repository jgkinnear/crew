import Foundation
import Sparkle

/// Checks the private `updates` GitHub release and lets Sparkle prompt, install, and relaunch.
/// The feed is downloaded with CREW_UPDATE_TOKEN because the repository is private.
final class CrewUpdater: NSObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate, ObservableObject {
    private var controller: SPUStandardUpdaterController?
    private let session: URLSession
    let canCheck: Bool
    /// Short version of a build newer than this one, when a background check has found one.
    @Published private(set) var availableUpdate: String?

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
            userDriverDelegate: self
        )
        let token = CrewConfig.load().updateToken
        controller?.updater.httpHeaders = [
            "Authorization": "Bearer \(token)",
            "User-Agent": "Crew",
            "X-GitHub-Api-Version": "2022-11-28",
        ]
        controller?.updater.automaticallyChecksForUpdates = true
        controller?.updater.updateCheckInterval = 10 * 60
        controller?.updater.checkForUpdatesInBackground()
    }

    func check() {
        controller?.checkForUpdates(nil)
    }

    /// Brings the already-found update forward so Sparkle can download, install, and relaunch.
    func install() {
        controller?.checkForUpdates(nil)
    }

    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        false
    }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        publish(update)
    }

    func standardUserDriverWillFinishUpdateSession() {
        DispatchQueue.main.async {
            self.availableUpdate = nil
        }
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        publish(item)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        DispatchQueue.main.async {
            self.availableUpdate = nil
        }
    }

    private func publish(_ item: SUAppcastItem) {
        let version = item.displayVersionString
        DispatchQueue.main.async {
            self.availableUpdate = version
        }
    }

    func feedURLString(for updater: SPUUpdater) -> String? {
        let token = CrewConfig.load().updateToken
        guard !token.isEmpty else { return nil }
        guard
            let release = fetch(GitHubRelease.updatesAPI, token: token, accept: "application/vnd.github+json"),
            let appcast = GitHubRelease.browserDownloadURL(named: GitHubRelease.appcastName, in: release)
        else { return nil }
        return appcast.absoluteString
    }

    func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, with request: NSMutableURLRequest) {
        authorize(request)
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

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarController = MenuBarController()
    private var fileWatcher: StatusFileWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController.setup()

        // Watch status.json
        let statusPath = (NSHomeDirectory() as NSString)
            .appendingPathComponent(".claude/hook-hero/status.json")

        fileWatcher = StatusFileWatcher(filePath: statusPath) { [weak self] status in
            self?.menuBarController.update(with: status)
        }
        fileWatcher?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        fileWatcher?.stop()
    }
}

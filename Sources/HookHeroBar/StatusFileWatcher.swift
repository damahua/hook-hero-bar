import Foundation

/// Watches ~/.claude/hook-hero/status.json for changes using GCD/DispatchSource.
final class StatusFileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var directorySource: DispatchSourceFileSystemObject?
    private let filePath: String
    private let onChange: (StatusData) -> Void
    private var fileDescriptor: Int32 = -1
    private var dirDescriptor: Int32 = -1

    init(filePath: String, onChange: @escaping (StatusData) -> Void) {
        self.filePath = filePath
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    /// Start watching the status file. Reads immediately if file exists.
    func start() {
        // Read current state
        if let data = readStatus() {
            onChange(data)
        }

        // Watch the directory for file creation/deletion
        let directory = (filePath as NSString).deletingLastPathComponent
        startDirectoryWatch(directory)

        // Watch the file itself if it exists
        startFileWatch()
    }

    func stop() {
        source?.cancel()
        source = nil
        directorySource?.cancel()
        directorySource = nil
        if fileDescriptor >= 0 { close(fileDescriptor); fileDescriptor = -1 }
        if dirDescriptor >= 0 { close(dirDescriptor); dirDescriptor = -1 }
    }

    // MARK: - Private

    private func startFileWatch() {
        // Cancel existing file watch
        source?.cancel()
        source = nil
        if fileDescriptor >= 0 { close(fileDescriptor); fileDescriptor = -1 }

        fileDescriptor = open(filePath, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            // Small delay to let the atomic rename complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let data = self.readStatus() {
                    self.onChange(data)
                }
                // Re-establish watch (file may have been replaced by rename)
                let flags = source.data
                if flags.contains(.delete) || flags.contains(.rename) {
                    self.startFileWatch()
                }
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self, self.fileDescriptor >= 0 else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }

        source.resume()
        self.source = source
    }

    private func startDirectoryWatch(_ directory: String) {
        dirDescriptor = open(directory, O_EVTONLY)
        guard dirDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: dirDescriptor,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            // File may have been created — try to start watching it
            if self.source == nil || self.fileDescriptor < 0 {
                self.startFileWatch()
            }
            if let data = self.readStatus() {
                self.onChange(data)
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self, self.dirDescriptor >= 0 else { return }
            close(self.dirDescriptor)
            self.dirDescriptor = -1
        }

        source.resume()
        self.directorySource = source
    }

    private func readStatus() -> StatusData? {
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            return nil
        }
        return try? JSONDecoder().decode(StatusData.self, from: jsonData)
    }
}

import AppKit

// Mark as a background app (no dock icon)
let info = ProcessInfo.processInfo
if let bundlePath = Bundle.main.bundlePath as NSString? {
    // LSUIElement equivalent for non-bundled executables
    NSApplication.shared.setActivationPolicy(.accessory)
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()

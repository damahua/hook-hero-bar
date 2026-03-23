import AppKit

// Mark as a background app (no dock icon)
NSApplication.shared.setActivationPolicy(.accessory)

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()

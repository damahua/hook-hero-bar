import AppKit
import SwiftUI

/// Manages the NSStatusItem and popover.
final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var currentStatus: StatusData = .empty
    private var midnightTimer: Timer?

    func setup() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem

        // Configure the button
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateButton(button, with: .empty)
        }

        // Set up popover
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: DropdownView(status: .empty))
        self.popover = popover

        // Schedule midnight reset
        scheduleMidnightReset()
    }

    func update(with status: StatusData) {
        // Check if data is from today — if not, show empty state
        let effectiveStatus = status.isFromToday ? status : .empty
        currentStatus = effectiveStatus

        if let button = statusItem?.button {
            updateButton(button, with: effectiveStatus)
        }

        // Update popover content
        popover?.contentViewController = NSHostingController(rootView: DropdownView(status: effectiveStatus))
    }

    // MARK: - Private

    private func updateButton(_ button: NSStatusBarButton, with status: StatusData) {
        let title = NSMutableAttributedString()

        // Green or gray dot
        let dotColor: NSColor = status.activeSessions > 0 ? .systemGreen : .systemGray
        let dot = NSAttributedString(string: "● ", attributes: [
            .foregroundColor: dotColor,
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
        ])
        title.append(dot)

        // Metrics text
        let time = formatDurationCompact(status.today.interactionTimeSec)
        let cost = formatCostCompact(status.today.costUsd)
        let text = NSAttributedString(string: "\(status.activeSessions) | \(time) | \(cost)", attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
        ])
        title.append(text)

        button.attributedTitle = title
    }

    @objc private func togglePopover() {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Ensure popover window is key so it dismisses on click-away
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func scheduleMidnightReset() {
        midnightTimer?.invalidate()

        // Calculate time until next midnight
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else { return }
        let interval = tomorrow.timeIntervalSinceNow

        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.update(with: .empty)
            self?.scheduleMidnightReset() // Schedule next midnight
        }
    }
}

// MARK: - Compact formatters for menu bar

private func formatDurationCompact(_ seconds: Double) -> String {
    let totalMinutes = Int(seconds) / 60
    if totalMinutes < 60 {
        return "\(totalMinutes)m"
    }
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return "\(hours)h\(String(format: "%02d", minutes))m"
}

private func formatCostCompact(_ usd: Double) -> String {
    if usd < 10 {
        return String(format: "$%.2f", usd)
    }
    return String(format: "$%.1f", usd)
}

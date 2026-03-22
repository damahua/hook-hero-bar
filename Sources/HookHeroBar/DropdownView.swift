import SwiftUI

/// The popover view shown when clicking the menu bar item.
struct DropdownView: View {
    let status: StatusData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Hook Hero")
                    .font(.system(.headline, design: .monospaced))
                Spacer()
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Summary metrics
            VStack(spacing: 6) {
                metricRow("Sessions", "\(status.today.sessionsTotal)", icon: "circle.fill",
                          iconColor: status.activeSessions > 0 ? .green : .gray,
                          detail: status.activeSessions > 0 ? "\(status.activeSessions) active" : nil)
                metricRow("Time", formatDuration(status.today.interactionTimeSec), icon: "clock")
                metricRow("Cost", formatCost(status.today.costUsd), icon: "dollarsign.circle")
                metricRow("Prompts", "\(status.today.prompts)", icon: "text.bubble")
                metricRow("Tool Calls", "\(status.today.toolCalls)", icon: "wrench")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Tokens section
            if status.today.tokens.input + status.today.tokens.output > 0 {
                Divider()
                VStack(spacing: 4) {
                    HStack {
                        Text("Tokens")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    HStack(spacing: 12) {
                        tokenPill("In", status.today.tokens.input)
                        tokenPill("Out", status.today.tokens.output)
                        tokenPill("Cache", status.today.tokens.cacheRead)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Git section
            if status.today.git.commits > 0 || status.today.git.filesChanged > 0 {
                Divider()
                HStack(spacing: 16) {
                    Label("\(status.today.git.commits) commits", systemImage: "arrow.triangle.branch")
                    Label("\(status.today.git.filesChanged) files", systemImage: "doc")
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Active sessions
            if !status.active.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Sessions")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    ForEach(status.active, id: \.sessionId) { session in
                        HStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            Text(session.project ?? "unknown")
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            Text(formatDuration(Double(session.durationSec)))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text(formatCost(session.costUsd))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()

            // Footer
            Button("Quit Hook Hero Bar") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(.caption))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }

    // MARK: - Components

    private func metricRow(_ label: String, _ value: String, icon: String,
                           iconColor: Color = .secondary, detail: String? = nil) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 16)
            Text(label)
                .font(.system(.body, design: .monospaced))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.green)
                    .padding(.trailing, 4)
            }
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }

    private func tokenPill(_ label: String, _ count: Int) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(formatTokenCount(count))
                .font(.system(.caption, design: .monospaced))
        }
    }
}

// MARK: - Formatters

private func formatDuration(_ seconds: Double) -> String {
    let totalMinutes = Int(seconds) / 60
    if totalMinutes < 60 {
        return "\(totalMinutes)m"
    }
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return "\(hours)h\(String(format: "%02d", minutes))m"
}

private func formatCost(_ usd: Double) -> String {
    if usd < 10 {
        return String(format: "$%.2f", usd)
    }
    return String(format: "$%.1f", usd)
}

private func formatTokenCount(_ count: Int) -> String {
    if count >= 1_000_000 {
        return String(format: "%.1fM", Double(count) / 1_000_000)
    }
    if count >= 1_000 {
        return String(format: "%.1fk", Double(count) / 1_000)
    }
    return "\(count)"
}

import Foundation

/// Matches the status.json schema written by Hook Hero.
struct StatusData: Codable {
    let schemaVersion: String
    let activeSessions: Int
    let today: TodayData
    let active: [ActiveSession]
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case activeSessions = "active_sessions"
        case today
        case active
        case updatedAt = "updated_at"
    }
}

struct TodayData: Codable {
    let sessionsTotal: Int
    let interactionTimeSec: Double
    let costUsd: Double
    let tokens: TokenData
    let toolCalls: Int
    let prompts: Int
    let git: GitData

    enum CodingKeys: String, CodingKey {
        case sessionsTotal = "sessions_total"
        case interactionTimeSec = "interaction_time_sec"
        case costUsd = "cost_usd"
        case tokens
        case toolCalls = "tool_calls"
        case prompts
        case git
    }
}

struct TokenData: Codable {
    let input: Int
    let output: Int
    let cacheRead: Int
    let cacheWrite: Int

    enum CodingKeys: String, CodingKey {
        case input, output
        case cacheRead = "cache_read"
        case cacheWrite = "cache_write"
    }
}

struct GitData: Codable {
    let commits: Int
    let filesChanged: Int

    enum CodingKeys: String, CodingKey {
        case commits
        case filesChanged = "files_changed"
    }
}

struct ActiveSession: Codable {
    let sessionId: String
    let project: String?
    let durationSec: Int
    let costUsd: Double
    let prompts: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case project
        case durationSec = "duration_sec"
        case costUsd = "cost_usd"
        case prompts
    }
}

// MARK: - Formatting Helpers

extension StatusData {
    /// Format for menu bar: "● 2 | 1h23m | $4.57"
    var menuBarTitle: String {
        let dot = activeSessions > 0 ? "●" : "●"
        let time = formatDuration(today.interactionTimeSec)
        let cost = formatCost(today.costUsd)
        return "\(dot) \(activeSessions) | \(time) | \(cost)"
    }

    /// Whether this data is from today (not stale from yesterday).
    var isFromToday: Bool {
        guard let date = ISO8601DateFormatter().date(from: updatedAt) else { return false }
        return Calendar.current.isDateInToday(date)
    }

    static var empty: StatusData {
        StatusData(
            schemaVersion: "1.0",
            activeSessions: 0,
            today: TodayData(
                sessionsTotal: 0,
                interactionTimeSec: 0,
                costUsd: 0,
                tokens: TokenData(input: 0, output: 0, cacheRead: 0, cacheWrite: 0),
                toolCalls: 0,
                prompts: 0,
                git: GitData(commits: 0, filesChanged: 0)
            ),
            active: [],
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}

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

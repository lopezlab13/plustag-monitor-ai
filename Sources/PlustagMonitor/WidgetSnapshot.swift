import Foundation

/// Contains only quota display data. No account identifiers or credentials.
struct WidgetQuota: Codable {
    let remaining: Double
    let durationMinutes: Int?
    let resetsAt: Date?
    var durationLabel: String {
        guard let minutes = durationMinutes else { return "Límite" }
        if minutes > 0 && minutes % 1440 == 0 { return "\(minutes / 1440) días" }
        if minutes > 0 && minutes % 60 == 0 { return "\(minutes / 60) h" }
        return "\(minutes) min"
    }
}
struct WidgetSnapshot: Codable {
    let updatedAt: Date?
    let bucketName: String
    let quotas: [WidgetQuota]
    let additionalBuckets: Int
    let readFailed: Bool
    static let empty = WidgetSnapshot(updatedAt: nil, bucketName: "Codex", quotas: [], additionalBuckets: 0, readFailed: false)
    func isStale(at date: Date) -> Bool {
        readFailed || updatedAt.map { date.timeIntervalSince($0) > 900 } ?? true
    }
}

enum WidgetSnapshotFile {
    static let kind = "PlustagUsageWidget"
    /// Set by the signed Xcode build, not used by the standalone Swift package.
    static var sharedURL: URL? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "PlustagAppGroup") as? String,
              !group.isEmpty, !group.contains("$("), !group.hasPrefix(".") else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appendingPathComponent("usage-snapshot.json")
    }
    static func write(_ snapshot: WidgetSnapshot, to url: URL) throws {
        try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
    }
    static func read(from url: URL?) -> WidgetSnapshot {
        guard let url, let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return .empty }
        return snapshot
    }
}

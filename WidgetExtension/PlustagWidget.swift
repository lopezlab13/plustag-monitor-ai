import SwiftUI
import WidgetKit

struct UsageEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}
struct UsageTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry { UsageEntry(date: Date(), snapshot: .empty) }
    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(UsageEntry(date: Date(), snapshot: WidgetSnapshotFile.read(from: WidgetSnapshotFile.sharedURL)))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSnapshotFile.read(from: WidgetSnapshotFile.sharedURL)
        var entries = [UsageEntry(date: now, snapshot: snapshot)]
        // Mark cached values as stale even if the host app stops updating.
        if let updated = snapshot.updatedAt, updated.addingTimeInterval(901) > now {
            entries.append(UsageEntry(date: updated.addingTimeInterval(901), snapshot: snapshot))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(900))))
    }
}
struct UsageWidgetView: View {
    let entry: UsageEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        QuotaGlanceView(snapshot: entry.snapshot, date: entry.date, small: family == .systemSmall)
            .containerBackground(Color(red: 0.09, green: 0.055, blue: 0.16), for: .widget)
            .widgetURL(URL(string: "plustagmonitor://monitor"))
    }
}
@main struct PlustagUsageWidget: Widget {
    let kind = WidgetSnapshotFile.kind
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UsageTimelineProvider()) { entry in UsageWidgetView(entry: entry) }
            .configurationDisplayName("Plustag Monitor AI")
            .description("Tus límites de Codex, con la última lectura del monitor.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

import Foundation
@main struct Check {
    static func main() throws {
        let decoder = JSONDecoder()
        let multiple = try decoder.decode(UsageResponse.self, from: Data(#"{"rateLimits":{"primary":{"usedPercent":99}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":25,"windowDurationMins":300,"resetsAt":1800000000}},"other":{"secondary":null}}}"#.utf8))
        precondition(multiple.buckets.count == 2)
        precondition(multiple.buckets.first?.1.primary?.remaining == 75)
        precondition(multiple.buckets.last?.1.primary == nil)
        let legacy = try decoder.decode(UsageResponse.self, from: Data(#"{"rateLimits":{"primary":{"usedPercent":110}}}"#.utf8))
        precondition(legacy.buckets.first?.1.primary?.remaining == 0)
        let empty = try decoder.decode(UsageResponse.self, from: Data("{}".utf8))
        precondition(empty.buckets.isEmpty)
        print("OK: múltiples cuotas, compatibilidad, datos ausentes y porcentaje disponible.")
        let now = Date()
        let snapshot = WidgetSnapshot(updatedAt: now, bucketName: "codex", quotas: [WidgetQuota(remaining: 75, durationMinutes: 300, resetsAt: now)], additionalBuckets: 1, readFailed: false)
        precondition(snapshot.quotas[0].durationLabel == "5 h")
        precondition(!snapshot.isStale(at: now))
        precondition(snapshot.isStale(at: now.addingTimeInterval(901)))
        precondition(WidgetSnapshot.empty.isStale(at: now))
        let cache = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: cache) }
        try WidgetSnapshotFile.write(snapshot, to: cache)
        precondition(WidgetSnapshotFile.read(from: cache).quotas[0].remaining == 75)
        try Data("invalid".utf8).write(to: cache)
        precondition(WidgetSnapshotFile.read(from: cache).quotas.isEmpty)
        print("OK: caché compartida, antigüedad, duraciones y recuperación de archivo inválido.")
        let claude = try ClaudeDesktopParser.parse(values: [
            ClaudeAccessibleValue(label: "Current session", percentage: 7),
            ClaudeAccessibleValue(label: "This week", percentage: 10),
            ClaudeAccessibleValue(label: "Claude Code", percentage: 0),
            ClaudeAccessibleValue(label: "Chats", percentage: 19),
            ClaudeAccessibleValue(label: "Cowork", percentage: 48),
            ClaudeAccessibleValue(label: "Other", percentage: 33),
            ClaudeAccessibleValue(label: "Unrelated", percentage: 80)
        ], texts: ["Your usage", "Current session", "Resets at 7:40 PM", "7% used", "This week", "Resets Sunday 2:00 AM", "33% Last updated: 37 minutes ago"], now: now)
        precondition(claude.sessionUsed == 7 && claude.weekUsed == 10)
        precondition(claude.products.count == 4 && claude.products[0].percentage == 0)
        precondition(claude.products.reduce(0) { $0 + $1.percentage } == 100)
        precondition(claude.sessionResetLabel == "Resets at 7:40 PM")
        let noReset = try ClaudeDesktopParser.parse(values: [ClaudeAccessibleValue(label: "Current session", percentage: 7)], texts: ["Your usage", "Current session", "Limit resets", "No resets right now"])
        precondition(noReset.sessionResetLabel == nil)
        precondition(claude.pageUpdatedLabel == "Last updated: 37 minutes ago")
        do {
            _ = try ClaudeDesktopParser.parse(values: [ClaudeAccessibleValue(label: "Chats", percentage: 50)], texts: ["Chat messages"])
            preconditionFailure("Never parse chat content as quota data")
        } catch {}
        do {
            _ = try ClaudeDesktopParser.parse(values: [ClaudeAccessibleValue(label: "Current session", percentage: 101)], texts: ["Your usage"])
            preconditionFailure("Reject invalid percentages")
        } catch {}
        let textOnly = try ClaudeDesktopParser.parse(values: [ClaudeAccessibleValue(label: "Chats", percentage: 19)], texts: ["Your usage", "Current session", "Resets at 7:40 PM", "14% used", "This week", "Resets Sunday 2:00 AM", "11% used", "Chats", "19%"])
        precondition(textOnly.sessionUsed == 14 && textOnly.weekUsed == 11)
        let noSession = try ClaudeDesktopParser.parse(values: [ClaudeAccessibleValue(label: "Chats", percentage: 19)], texts: ["Your usage", "Current session", "Resets at 7:40 PM", "This week", "11% used", "Chats", "19%"])
        precondition(noSession.sessionUsed == nil && noSession.weekUsed == 11)
        let zeroText = try ClaudeDesktopParser.parse(values: [], texts: ["Your usage", "Current session", "0% used", "This week", "12,5% used"])
        precondition(zeroText.sessionUsed == 0 && zeroText.weekUsed == 12.5)
        print("OK: sesión y semana desde texto explícito cuando Claude omite indicadores; no mezcla porcentajes entre secciones.")
        print("OK: Claude distingue cuotas, reparto, ceros reales y datos ausentes; rechaza otras pantallas.")
        if CommandLine.arguments.contains("--live") {
            let result = try CodexProvider().fetch()
            precondition(!result.buckets.isEmpty)
            print("OK: lectura real de límites Codex sin inferencia y sin imprimir datos de cuenta.")
        }
    }
}

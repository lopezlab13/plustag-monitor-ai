import Foundation

struct UsageWindow: Decodable {
    let usedPercent: Double
    let windowDurationMins: Int?
    let resetsAt: Double?
    var remaining: Double { max(0, min(100, 100 - usedPercent)) }
}
struct UsageBucket: Decodable {
    let limitName: String?
    let primary: UsageWindow?
    let secondary: UsageWindow?
}
struct UsageResponse: Decodable {
    let rateLimits: UsageBucket?
    let rateLimitsByLimitId: [String: UsageBucket]?
    var buckets: [(String, UsageBucket)] {
        if let all = rateLimitsByLimitId, !all.isEmpty { return all.sorted { $0.key < $1.key } }
        return rateLimits.map { [("codex", $0)] } ?? []
    }
}
protocol UsageProvider {
    func fetch() throws -> UsageResponse
}
enum MonitorError: LocalizedError {
    case unavailable(String)
    var errorDescription: String? { if case let .unavailable(message) = self { return message }; return nil }
}

/// Only initializes the documented local protocol and reads account limits.
/// Never opens an inference turn or reads credential files.
struct CodexProvider: UsageProvider {
    func fetch() throws -> UsageResponse {
        let userHome = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
            "/Applications/Codex.app/Contents/Resources/codex",
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "\(userHome)/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
            "\(userHome)/Applications/Codex.app/Contents/Resources/codex",
            "\(userHome)/.local/bin/codex",
            "/opt/homebrew/bin/codex", "/usr/local/bin/codex"
        ]
        guard let binary = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            throw MonitorError.unavailable("No se encontró Codex. Instala Codex e inicia sesión desde su aplicación o CLI.")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = ["app-server", "--listen", "stdio://"]
        let input = Pipe(), output = Pipe()
        process.standardInput = input; process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        let timeout = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + 20, execute: timeout)
        defer {
            timeout.cancel()
            try? input.fileHandleForWriting.close()
            if process.isRunning { process.terminate() }
            try? output.fileHandleForReading.close()
        }
        func send(_ object: [String: Any]) throws {
            var data = try JSONSerialization.data(withJSONObject: object)
            data.append(10)
            try input.fileHandleForWriting.write(contentsOf: data)
        }
        try send(["id": 1, "method": "initialize", "params": ["clientInfo": ["name": "plustag_monitor_ai", "title": "Plustag Monitor AI", "version": "0.1.0"]]])
        var pending = Data()
        while true {
            let data = output.fileHandleForReading.availableData
            if data.isEmpty { throw MonitorError.unavailable("Codex no respondió. Comprueba tu sesión y conexión; vuelve a actualizar.") }
            pending.append(data)
            guard pending.count < 4_000_000 else { throw MonitorError.unavailable("Respuesta de Codex demasiado grande.") }
            while let end = pending.firstIndex(of: 10) {
                let line = Data(pending[..<end]); pending.removeSubrange(...end)
                guard let json = try JSONSerialization.jsonObject(with: line) as? [String: Any], let id = json["id"] as? Int else { continue }
                if json["error"] != nil { throw MonitorError.unavailable("No fue posible leer los límites. Inicia sesión en Codex con tu cuenta de ChatGPT y vuelve a intentar.") }
                if id == 1 {
                    try send(["method": "initialized", "params": [:]])
                    try send(["id": 2, "method": "account/rateLimits/read"])
                } else if id == 2, let result = json["result"] {
                    return try JSONDecoder().decode(UsageResponse.self, from: JSONSerialization.data(withJSONObject: result))
                }
            }
        }
    }
}

// Claude Desktop publishes these values in Settings → Usage. This adapter reads
// that visible panel via macOS Accessibility; no tokens, cookies or private APIs.
import AppKit
import ApplicationServices

struct ClaudeAccessibleValue {
    let label: String
    let percentage: Double
}
struct ClaudeProductShare: Identifiable {
    let name: String
    let percentage: Double
    var id: String { name }
}
struct ClaudeDesktopSnapshot {
    let capturedAt: Date
    let sessionUsed: Double?
    let weekUsed: Double?
    let products: [ClaudeProductShare]
    let pageUpdatedLabel: String?
    let sessionResetLabel: String?
    let weekResetLabel: String?
    var hasQuotas: Bool { sessionUsed != nil || weekUsed != nil }
}
enum ClaudeDesktopParser {
    static func parse(values: [ClaudeAccessibleValue], texts: [String], now: Date = Date()) throws -> ClaudeDesktopSnapshot {
        guard texts.contains(where: { ["your usage", "tu uso", "uso de tu plan"].contains($0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) }) else {
            throw MonitorError.unavailable("En Claude, abre tu perfil → Usage (Uso) para leer los límites.")
        }
        var session: Double?, week: Double?
        var products: [ClaudeProductShare] = []
        for value in values {
            guard value.percentage.isFinite, (0...100).contains(value.percentage) else { continue }
            let label = value.label.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            switch label {
            case "current session", "sesión actual": session = value.percentage
            case "this week", "esta semana", "all models", "todos los modelos": week = value.percentage
            case "claude code", "chats", "cowork", "other", "otros":
                let name = label == "otros" ? "Other" : label == "claude code" ? "Claude Code" : label == "chats" ? "Chats" : label == "cowork" ? "Cowork" : "Other"
                if !products.contains(where: { $0.name == name }) { products.append(ClaudeProductShare(name: name, percentage: value.percentage)) }
            default: break
            }
        }
        // Claude can expose the product bars while omitting the numeric AX
        // value of the quota bars. Read the explicit “N% used” text within
        // the matching quota section; never borrow a product share percentage.
        func textQuota(after labels: [String]) -> Double? {
            guard let index = texts.firstIndex(where: { labels.contains($0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) }) else { return nil }
            let pattern = #"^\s*(\d+(?:[.,]\d+)?)\s*%\s*(?:used|usado|utilizado|consumido)(?:\s|$)"#
            guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
            for text in texts.dropFirst(index + 1).prefix(4) {
                let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if ["current session", "sesión actual", "this week", "esta semana", "claude code", "chats", "cowork", "other", "limit resets"].contains(normalized) { break }
                let range = NSRange(text.startIndex..., in: text)
                if let match = expression.firstMatch(in: text, range: range),
                   let numberRange = Range(match.range(at: 1), in: text),
                   let used = Double(text[numberRange].replacingOccurrences(of: ",", with: ".")), (0...100).contains(used) { return used }
            }
            return nil
        }
        if session == nil { session = textQuota(after: ["current session", "sesión actual"]) }
        if week == nil { week = textQuota(after: ["this week", "esta semana", "all models", "todos los modelos"]) }
        guard session != nil || week != nil || !products.isEmpty else {
            throw MonitorError.unavailable("Claude no expone porcentajes legibles en esta pantalla. No se han estimado valores.")
        }
        let pageUpdated = texts.compactMap { text -> String? in
            for prefix in ["Last updated:", "Última actualización:"] {
                if let range = text.range(of: prefix, options: .caseInsensitive) { return String(text[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            return nil
        }.first
        func resetLabel(after labels: [String]) -> String? {
            guard let index = texts.firstIndex(where: { labels.contains($0.lowercased()) }) else { return nil }
            return texts.dropFirst(index + 1).prefix(3).first(where: {
                let text = $0.lowercased()
                return text.hasPrefix("resets ") || text.hasPrefix("reinicia") || text.hasPrefix("restablece") || text.hasPrefix("se renueva")
            })
        }
        return ClaudeDesktopSnapshot(capturedAt: now, sessionUsed: session, weekUsed: week, products: products, pageUpdatedLabel: pageUpdated,
                                     sessionResetLabel: resetLabel(after: ["current session", "sesión actual"]),
                                     weekResetLabel: resetLabel(after: ["this week", "esta semana"]))
    }
}

struct ClaudeDesktopProvider {
    static var isAuthorized: Bool { AXIsProcessTrusted() }
    static func requestAuthorization() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
    private func label(_ element: AXUIElement) -> String {
        for key in [kAXDescriptionAttribute, kAXTitleAttribute] {
            if let value = attribute(element, key) as? String, !value.isEmpty { return value }
        }
        return ""
    }
    private func children(_ element: AXUIElement) -> [AXUIElement] {
        attribute(element, kAXChildrenAttribute) as? [AXUIElement] ?? []
    }
    func fetch() throws -> ClaudeDesktopSnapshot {
        guard Self.isAuthorized else { throw MonitorError.unavailable("Conecta Claude autorizando Accesibilidad para Plustag Monitor AI.") }
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.anthropic.claudefordesktop").first else {
            throw MonitorError.unavailable("Abre Claude y entra en tu perfil → Usage (Uso).")
        }
        let root = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 2)
        // Locate Settings by container metadata before reading values. Never read
        // chat text fields, clipboard contents, password fields or other apps.
        var queue: [(AXUIElement, Int)] = [(root, 0)]
        var cursor = 0
        var settings: AXUIElement?
        let deadline = Date().addingTimeInterval(6)
        while cursor < queue.count && cursor < 1800 && Date() < deadline {
            let (element, depth) = queue[cursor]; cursor += 1
            let role = attribute(element, kAXRoleAttribute) as? String ?? ""
            let name = label(element).lowercased()
            if ["settings", "configuración", "ajustes"].contains(name), [kAXGroupRole, kAXSheetRole, kAXWindowRole].contains(role) {
                settings = element; break
            }
            if depth < 22 && ![kAXTextAreaRole, kAXTextFieldRole].contains(role) {
                queue.append(contentsOf: children(element).map { ($0, depth + 1) })
            }
        }
        guard let settings else { throw MonitorError.unavailable("Para actualizar Claude, abre tu perfil → Usage (Uso). La última lectura se conserva.") }
        var texts: [String] = [], values: [ClaudeAccessibleValue] = []
        var stack: [(AXUIElement, Int)] = [(settings, 0)]
        cursor = 0
        // Depth-first traversal preserves the page's reading order so renewal
        // labels stay paired with their quota rather than a later heading.
        while let (element, depth) = stack.popLast(), cursor < 1200 && Date() < deadline {
            cursor += 1
            let role = attribute(element, kAXRoleAttribute) as? String ?? ""
            if role == kAXStaticTextRole, let text = attribute(element, kAXValueAttribute) as? String { texts.append(text) }
            if role == kAXLevelIndicatorRole || role == kAXProgressIndicatorRole {
                let value = attribute(element, kAXValueAttribute)
                if let number = value as? NSNumber { values.append(ClaudeAccessibleValue(label: label(element), percentage: number.doubleValue)) }
                else if let string = value as? String, let number = Double(string.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) {
                    values.append(ClaudeAccessibleValue(label: label(element), percentage: number))
                }
            }
            if depth < 20 && ![kAXTextAreaRole, kAXTextFieldRole].contains(role) {
                stack.append(contentsOf: children(element).reversed().map { ($0, depth + 1) })
            }
        }
        return try ClaudeDesktopParser.parse(values: values, texts: texts)
    }
}

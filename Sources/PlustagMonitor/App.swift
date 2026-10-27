import SwiftUI
import AppKit
import WidgetKit

@MainActor final class MonitorStore: ObservableObject {
    @Published var claude: ClaudeDesktopSnapshot?
    @Published var claudeError: String?
    @Published var claudeLoading = false
    @Published var claudeEnabled = UserDefaults.standard.bool(forKey: "claudeEnabled")
    @Published var claudeAuthorized = ClaudeDesktopProvider.isAuthorized
    @Published var usage: UsageResponse?
    @Published var error: String?
    @Published var loading = false
    @Published var updated: Date?
    var snapshot: WidgetSnapshot {
        guard let usage else { return .empty }
        let buckets = usage.buckets
        let selected = buckets.first(where: { $0.0 == "codex" }) ?? buckets.first
        let quotas = [selected?.1.primary, selected?.1.secondary].compactMap { $0 }.map {
            WidgetQuota(remaining: $0.remaining, durationMinutes: $0.windowDurationMins,
                        resetsAt: $0.resetsAt.map(Date.init(timeIntervalSince1970:)))
        }
        return WidgetSnapshot(updatedAt: updated, bucketName: selected?.1.limitName ?? selected?.0 ?? "Codex",
                              quotas: quotas, additionalBuckets: max(0, buckets.count - 1), readFailed: error != nil)
    }
    func connectClaude() {
        let alert = NSAlert()
        alert.messageText = "Conectar Claude de escritorio"
        alert.informativeText = "macOS requiere Accesibilidad. Este permiso permite técnicamente leer y controlar otras aplicaciones; Plustag usará solo la lectura de Configuración → Usage de Claude. No lee tus conversaciones ni credenciales. Puedes revocarlo en Configuración del Sistema."
        alert.addButton(withTitle: "Autorizar en macOS")
        alert.addButton(withTitle: "Cancelar")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        claudeEnabled = true
        UserDefaults.standard.set(true, forKey: "claudeEnabled")
        ClaudeDesktopProvider.requestAuthorization()
        refreshClaude()
    }
    func disconnectClaude() {
        claudeEnabled = false
        UserDefaults.standard.set(false, forKey: "claudeEnabled")
        claude = nil; claudeError = nil
        // OS permission is revoked by the user in System Settings.
    }
    func refreshClaude() {
        guard claudeEnabled, !claudeLoading else { return }
        claudeAuthorized = ClaudeDesktopProvider.isAuthorized
        guard claudeAuthorized else {
            claudeError = "Activa Plustag Monitor AI en Configuración del Sistema → Privacidad y seguridad → Accesibilidad."
            return
        }
        claudeLoading = true
        Task {
            do {
                let response = try await Task.detached(priority: .utility) { try ClaudeDesktopProvider().fetch() }.value
                if claudeEnabled { claude = response; claudeError = nil }
            } catch { if claudeEnabled { claudeError = error.localizedDescription } }
            claudeLoading = false
        }
    }
    private func publishWidgetSnapshot() {
        guard let url = WidgetSnapshotFile.sharedURL else { return }
        do {
            try WidgetSnapshotFile.write(snapshot, to: url)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshotFile.kind)
        } catch { NSLog("No se pudo actualizar el archivo compartido del widget.") }
    }
    func refresh() {
        refreshClaude()
        guard !loading else { return }
        loading = true
        Task {
            do {
                let response = try await Task.detached(priority: .utility) { try CodexProvider().fetch() }.value
                usage = response; updated = Date(); error = nil
            } catch { self.error = error.localizedDescription }
            publishWidgetSnapshot()
            loading = false
        }
    }
}

@main struct PlustagMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = MonitorStore()
    var panel: NSPanel!
    var compactPanel: NSPanel!
    var status: NSStatusItem!
    var timer: Timer?
    var claudeTimer: Timer?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 350, height: 510), styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        panel.title = "Plustag Monitor AI"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true; panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.setFrameAutosaveName("PlustagMonitorPanel")
        panel.contentView = NSHostingView(rootView: MonitorView(store: store, compact: { [weak self] in self?.showCompact() }))
        panel.center(); panel.orderFrontRegardless()
        compactPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 240), styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        compactPanel.title = "Plustag · Compacto"
        compactPanel.level = .floating
        compactPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        compactPanel.isFloatingPanel = true
        compactPanel.hidesOnDeactivate = false
        compactPanel.isReleasedWhenClosed = false
        compactPanel.setFrameAutosaveName("PlustagCompactPanel")
        compactPanel.center()
        compactPanel.contentView = NSHostingView(rootView: CompactMonitorView(store: store, expand: { [weak self] in self?.show() }))
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Plustag Monitor AI")
        let menu = NSMenu()
        menu.addItem(withTitle: "Mostrar monitor", action: #selector(show), keyEquivalent: "")
        menu.addItem(withTitle: "Mostrar vista compacta", action: #selector(showCompact), keyEquivalent: "")
        menu.addItem(withTitle: "Actualizar límites", action: #selector(refresh), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Salir", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        status.menu = menu
        if UserDefaults.standard.bool(forKey: "compactMode") { showCompact() }
        store.refresh()
        claudeTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.store.refreshClaude() }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.store.refresh() }
        }
    }
    @objc func show() {
        UserDefaults.standard.set(false, forKey: "compactMode")
        compactPanel.orderOut(nil)
        panel.orderFrontRegardless()
    }
    @objc func showCompact() {
        UserDefaults.standard.set(true, forKey: "compactMode")
        panel.orderOut(nil)
        compactPanel.orderFrontRegardless()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if UserDefaults.standard.bool(forKey: "compactMode") { showCompact() } else { show() }
        return false
    }
    func application(_ application: NSApplication, open urls: [URL]) { show() }
    @objc func refresh() { store.refresh() }
    @objc func quit() { NSApp.terminate(nil) }
}

struct MonitorView: View {
    @ObservedObject var store: MonitorStore
    let compact: () -> Void
    private let accent = Color(red: 0.46, green: 0.20, blue: 0.97)
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 7) {
                        PlustagLogo(width: 140)
                        Text("MONITOR AI").font(.caption).foregroundStyle(.secondary).tracking(2)
                    }
                    Spacer()
                    if store.loading { ProgressView().controlSize(.small) }
                }
                Text("Tus límites, a la vista.").font(.title3.bold())
                VStack(alignment: .leading, spacing: 12) {
                    Label("Codex + Work", systemImage: "terminal").font(.headline)
                    if let response = store.usage, !response.buckets.isEmpty {
                        ForEach(response.buckets, id: \.0) { key, bucket in
                            Text(bucket.limitName ?? key).font(.caption).foregroundStyle(.secondary)
                            if let window = bucket.primary { meter(window, label: "Ventana principal") }
                            if let window = bucket.secondary { meter(window, label: "Ventana secundaria") }
                            if bucket.primary == nil && bucket.secondary == nil { Text("Sin ventanas disponibles").font(.caption) }
                        }
                    } else { Text("Sin datos de límites").foregroundStyle(.secondary) }
                    if let error = store.error {
                        Text(error).font(.caption).foregroundStyle(.orange)
                        if store.usage != nil { Text("Se muestran datos anteriores.").font(.caption).foregroundStyle(.orange) }
                    }
                }.padding().background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                Text("Codex y ChatGPT Work comparten estos límites. Esta fuente no separa cuánto consumió cada producto.")
                    .font(.caption).foregroundStyle(.secondary)
                ClaudeUsageView(store: store)
                VStack(alignment: .leading, spacing: 6) {
                    Label("ChatGPT · Chats", systemImage: "bubble.left.and.bubble.right").font(.headline)
                    Text("Sin fuente de cuota conectada para los chats habituales. No se deduce su uso a partir de Codex ni Work.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding().background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                HStack {
                    Button(action: store.refresh) { Label("Actualizar ahora", systemImage: "arrow.clockwise") }
                        .disabled(store.loading)
                    Spacer()
                    Button("Vista compacta", action: compact)
                }
                VStack(alignment: .leading, spacing: 4) {
                    if let updated = store.updated { Text("Última lectura: \(updated.formatted(date: .omitted, time: .shortened))") }
                    Text("OpenAI: cada 5 min · Claude: lectura de Usage cada 30 s")
                    Link("Fuente: Codex app-server", destination: URL(string: "https://learn.chatgpt.com/docs/app-server")!)
                    Text("Plustag · Monitor local").opacity(0.7)
                }.font(.caption2).foregroundStyle(.secondary)
            }.padding(20)
        }.frame(width: 350).background(Color(red: 0.09, green: 0.055, blue: 0.16)).preferredColorScheme(.dark)
    }
    private func meter(_ window: UsageWindow, label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(window.windowDurationMins.map { "\($0) min" } ?? label)
                Spacer()
                Text("\(Int(window.remaining))% disponible").bold()
            }.font(.caption)
            ProgressView(value: window.remaining, total: 100).tint(window.remaining < 20 ? .orange : accent)
            if let reset = window.resetsAt {
                Text("Se renueva: \(Date(timeIntervalSince1970: reset).formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

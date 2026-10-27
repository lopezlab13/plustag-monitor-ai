import SwiftUI
import AppKit

struct PlustagLogo: View {
    var width: CGFloat = 100
    private var url: URL? {
        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: "PlustagLogo", withExtension: "png", subdirectory: "Assets")
        #else
        return Bundle.main.url(forResource: "PlustagLogo", withExtension: "png")
        #endif
    }
    var body: some View {
        if let url, let logo = NSImage(contentsOf: url) {
            Image(nsImage: logo).resizable().scaledToFit().frame(width: width, height: width * 0.35)
                .accessibilityLabel("Plustag")
        } else { Text("Plustag").font(.headline) }
    }
}

/// Same quota presentation for the floating compact panel and WidgetKit extension.
struct QuotaGlanceView: View {
    let snapshot: WidgetSnapshot
    var date = Date()
    var small = false
    private let purple = Color(red: 0.59, green: 0.39, blue: 1)
    var body: some View {
        VStack(alignment: .leading, spacing: small ? 6 : 10) {
            HStack {
                PlustagLogo(width: small ? 72 : 98)
                Spacer(minLength: 2)
                if !small { Text("MONITOR AI").font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary) }
            }
            Text(snapshot.bucketName).font(small ? .caption.bold() : .subheadline.bold()).lineLimit(1)
            if snapshot.quotas.isEmpty {
                Text("Abre el monitor para cargar tus límites.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(snapshot.quotas.prefix(2).enumerated()), id: \.offset) { _, quota in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(quota.durationLabel)
                            Spacer(minLength: 2)
                            Text("\(Int(quota.remaining))% libre").bold().monospacedDigit()
                        }.font(small ? .system(size: 10) : .caption)
                        ProgressView(value: quota.remaining, total: 100)
                            .tint(quota.remaining < 20 ? .orange : purple)
                    }
                }
            }
            if snapshot.isStale(at: date) {
                Text(snapshot.updatedAt == nil ? "Sin datos" : "Datos anteriores · abre el monitor")
                    .font(.system(size: small ? 9 : 10)).foregroundStyle(.orange).lineLimit(2)
            }
            if let updated = snapshot.updatedAt {
                HStack(spacing: 3) {
                    Text("Lectura")
                    Text(updated, style: .time)
                    if snapshot.additionalBuckets > 0 && !small { Text("· +\(snapshot.additionalBuckets) cuotas en monitor") }
                }.font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1)
            }
        }.foregroundStyle(.white)
    }
}

#if !WIDGET_EXTENSION
struct ClaudeUsageView: View {
    @ObservedObject var store: MonitorStore
    var compact = false
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 11) {
            HStack {
                Label("Claude", systemImage: "sparkle").font(.headline)
                Spacer()
                if store.claudeLoading { ProgressView().controlSize(.mini) }
            }
            if let data = store.claude {
                quota("Sesión actual", used: data.sessionUsed)
                if let label = data.sessionResetLabel { Text(label).font(.caption2).foregroundStyle(.secondary) }
                quota("Semana", used: data.weekUsed)
                if let label = data.weekResetLabel { Text(label).font(.caption2).foregroundStyle(.secondary) }
                if !data.products.isEmpty {
                    Divider()
                    Text("Reparto del uso semanal").font(.caption.bold())
                    ForEach(data.products) { product in
                        VStack(spacing: 2) {
                            HStack {
                                Text(product.name)
                                Spacer()
                                Text("\(Int(product.percentage))% del uso").monospacedDigit()
                            }.font(.caption)
                            ProgressView(value: product.percentage, total: 100).tint(.blue)
                        }
                    }
                    Text("Participación por producto, no cuota disponible.").font(.caption2).foregroundStyle(.secondary)
                }
                Text("Leído: \(data.capturedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2).foregroundStyle(.secondary)
                if let label = data.pageUpdatedLabel { Text(label).font(.caption2).foregroundStyle(.secondary) }
                if Date().timeIntervalSince(data.capturedAt) > 900 || store.claudeError != nil {
                    Text("Última lectura conservada · abre Usage para actualizar.").font(.caption2).foregroundStyle(.orange)
                }
            }
            if let error = store.claudeError { Text(error).font(.caption).foregroundStyle(.orange) }
            if !store.claudeEnabled {
                Text("Lee los límites y el reparto desde Claude → perfil → Usage.").font(.caption).foregroundStyle(.secondary)
                Button("Conectar Claude", action: store.connectClaude)
            } else {
                HStack {
                    Button("Leer Usage", action: store.refreshClaude).disabled(store.claudeLoading)
                    Spacer()
                    Button("Desconectar", action: store.disconnectClaude)
                }.font(.caption)
                Text("Solo se actualiza con Usage abierto en Claude.").font(.caption2).foregroundStyle(.secondary)
            }
        }.padding(compact ? 0 : 14)
            .background(.white.opacity(compact ? 0 : 0.05), in: RoundedRectangle(cornerRadius: 14))
    }
    private func quota(_ title: String, used: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                if let used { Text("\(Int(100 - used))% libre").bold().monospacedDigit() }
                else { Text("Sin lectura").foregroundStyle(.secondary) }
            }.font(.caption)
            if let used {
                ProgressView(value: 100 - used, total: 100).tint(used > 80 ? .orange : .purple)
            }
        }
    }
}

struct CompactMonitorView: View {
    @ObservedObject var store: MonitorStore
    let expand: () -> Void
    @AppStorage("compactProvider") private var provider = "OpenAI"
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Proveedor", selection: $provider) {
                Text("OpenAI").tag("OpenAI")
                Text("Claude").tag("Claude")
            }.pickerStyle(.segmented).labelsHidden()
            ScrollView {
                if provider == "Claude" { ClaudeUsageView(store: store, compact: true) }
                else {
                    VStack(alignment: .leading, spacing: 6) {
                        QuotaGlanceView(snapshot: store.snapshot)
                        Text("Codex + Work · límite compartido").font(.caption2).foregroundStyle(.secondary)
                        Text("ChatGPT Chats: sin cuota conectada").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            HStack {
                Button(action: store.refresh) {
                    Label(store.loading ? "Actualizando…" : "Actualizar", systemImage: "arrow.clockwise")
                }.disabled(store.loading)
                Spacer()
                Button("Ampliar", action: expand)
            }.font(.caption).buttonStyle(.borderless)
        }.padding(16).frame(width: 300, height: 240)
            .background(Color(red: 0.09, green: 0.055, blue: 0.16)).preferredColorScheme(.dark)
    }
}

#endif

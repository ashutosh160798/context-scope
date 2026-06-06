import SwiftUI
import ContextScopeCore
import ContextScopeVisualization

struct InspectorView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if let item = appState.selectedItem {
                ContextItemDetailView(item: item, totalTokens: appState.replayEngine.currentSnapshot?.totalTokens ?? 1)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Select a context item\nto inspect it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.background)
    }
}

struct ContextItemDetailView: View {
    let item: ContextItem
    let totalTokens: Int
    @State private var showCopied = false

    private var style: CategoryStyle? { CategoryStyle.styles[item.category] }
    private var pct: Double {
        guard totalTokens > 0 else { return 0 }
        return Double(item.tokenCount) / Double(totalTokens) * 100
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Category badge
                HStack {
                    if let color = style?.color {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: 12, height: 12)
                    }
                    Text(style?.label ?? item.category.rawValue)
                        .font(.headline)
                    Spacer()
                }

                Divider()

                // Metadata grid
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Label { Text("Tokens").foregroundStyle(.secondary) } icon: { }
                            .font(.caption)
                        HStack(spacing: 4) {
                            Text("\(item.tokenCount)")
                                .font(.body.monospacedDigit().bold())
                            if item.estimatedTokenCount {
                                Text("est.")
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                    }
                    GridRow {
                        Label { Text("% of input").foregroundStyle(.secondary) } icon: { }
                            .font(.caption)
                        Text(String(format: "%.1f%%", pct))
                            .font(.body.monospacedDigit())
                    }
                    GridRow {
                        Label { Text("Category").foregroundStyle(.secondary) } icon: { }
                            .font(.caption)
                        Text(item.category.rawValue)
                            .font(.body.monospacedDigit())
                    }
                    GridRow {
                        Label { Text("ID").foregroundStyle(.secondary) } icon: { }
                            .font(.caption)
                        Text(item.id.uuidString.prefix(8) + "…")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Proportion bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("Proportion of input")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(value: min(1.0, pct / 100))
                        .progressViewStyle(.linear)
                        .tint(style?.color ?? .accentColor)
                }

                Divider()

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Content")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.content, forType: .string)
                            showCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showCopied = false }
                        } label: {
                            Label(showCopied ? "Copied" : "Copy", systemImage: showCopied ? "checkmark" : "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    ScrollView {
                        Text(item.content)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 300)
                }
            }
            .padding()
        }
    }
}

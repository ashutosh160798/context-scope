import SwiftUI
import ContextScopeCore
import ContextScopeVisualization

struct RawRequestView: View {
    @EnvironmentObject var appState: AppState

    private var items: [ContextItem] {
        appState.replayEngine.currentSnapshot?.items ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Raw Context Items")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding()

                Divider()

                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    ItemRow(index: idx, item: item)
                }
            }
        }
        .background(.background)
    }
}

private struct ItemRow: View {
    let index: Int
    let item: ContextItem

    private var itemColor: Color {
        CategoryStyle.styles[item.category]?.color ?? Color.secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(index + 1)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .frame(width: 28, alignment: .trailing)
                Text(item.category.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(itemColor)
                Spacer()
                Text("\(item.tokenCount) tokens")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.03))

            Text(item.content)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 44)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            Divider()
        }
    }
}

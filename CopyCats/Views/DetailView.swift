import SwiftUI
import UniformTypeIdentifiers

struct DetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let item: ClipItem
    let onCopy: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                content
                VStack(spacing: 0) {
                    LabeledContent("Formats", value: formats)
                    Divider().padding(.vertical, 8)
                    LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: Int64(item.byteCount), countStyle: .file))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                ClipboardCapture.copy(item)
                onCopy()
            } label: {
                Text("Copy").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .navigationTitle(item.lastCopiedAt.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu("More", systemImage: "ellipsis.circle") {
                Button(item.isPinned ? "Unpin" : "Pin", systemImage: "pin") { item.isPinned.toggle() }
                if let shareURL {
                    ShareLink("Share…", item: shareURL)
                }
                Button("Delete", systemImage: "trash", role: .destructive) {
                    try? ClipStore(context: context).delete(item)
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .image:
            if let rep = item.firstRepresentation(conformingTo: .image), let image = UIImage(contentsOfFile: item.url(for: rep).path) {
                Image(uiImage: image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12))
            }
        case .richText:
            if let attributed = ClipText.attributed(from: pairs) {
                Text(AttributedString(attributed)).textSelection(.enabled)
            } else {
                plain
            }
        case .link:
            if let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                Link(text, destination: url)
            } else {
                plain
            }
        case .text:
            plain
        case .file:
            Label(item.previewText, systemImage: ClipRow.symbol(for: .file)).font(.title3)
        }
    }

    private var plain: some View {
        Text(text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pairs: [(UTType, Data)] {
        item.representations.compactMap { rep in
            guard let type = rep.type, let data = item.data(for: rep) else { return nil }
            return (type, data)
        }
    }

    private var text: String { ClipText.plainText(from: pairs) ?? item.previewText }

    private var formats: String {
        item.representations.map { $0.type?.preferredFilenameExtension ?? $0.typeIdentifier }.joined(separator: " · ")
    }

    private var shareURL: URL? {
        guard let rep = item.representations.first else { return nil }
        return item.url(for: rep)
    }
}

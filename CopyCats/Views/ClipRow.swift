import SwiftUI

struct ClipRow: View {
    let item: ClipItem

    var body: some View {
        HStack(spacing: 12) {
            leading
            VStack(alignment: .leading, spacing: 2) {
                Text(item.previewText.isEmpty ? "Untitled" : item.previewText)
                    .lineLimit(2)
                    .foregroundStyle(item.kind == .link ? Color.accentColor : .primary)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.lastCopiedAt, format: .dateTime.hour().minute())
                    .font(.caption).foregroundStyle(.secondary)
                if item.kind == .richText {
                    Text("Aa").font(.caption2.bold()).foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var leading: some View {
        if let url = item.thumbnailURL, let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Image(systemName: Self.symbol(for: item.kind))
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
        }
    }

    private var detail: String? {
        let size = ByteCountFormatter.string(fromByteCount: Int64(item.byteCount), countStyle: .file)
        switch item.kind {
        case .image: return item.pixelWidth > 0 ? "\(item.pixelWidth)×\(item.pixelHeight) · \(size)" : size
        case .file: return size
        default: return nil
        }
    }

    static func symbol(for kind: ClipKind) -> String {
        switch kind {
        case .text: "text.alignleft"
        case .richText: "textformat"
        case .image: "photo"
        case .link: "link"
        case .file: "doc"
        }
    }
}

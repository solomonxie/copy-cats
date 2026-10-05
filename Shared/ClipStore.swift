import CryptoKit
import Foundation
import ImageIO
import SwiftData
import UIKit
import UniformTypeIdentifiers

enum SaveResult {
    case saved, bumped, skipped
}

@MainActor
struct ClipStore {
    let context: ModelContext

    static var shared: ClipStore { ClipStore(context: ClipDatabase.shared.mainContext) }

    @discardableResult
    func save(_ clip: IncomingClip) throws -> SaveResult {
        let reps = normalized(clip.representations)
        guard !reps.isEmpty else { return .skipped }
        let hash = contentHash(reps)

        var existing = FetchDescriptor<ClipItem>(predicate: #Predicate { $0.contentHash == hash })
        existing.fetchLimit = 1
        if let item = try context.fetch(existing).first {
            item.lastCopiedAt = Date()
            try context.save()
            return .bumped
        }

        let id = UUID()
        let dir = ClipFiles.directory(for: id)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var stored: [Representation] = []
        for (i, rep) in reps.enumerated() {
            let name = "\(i).\(rep.type.preferredFilenameExtension ?? "bin")"
            try rep.data.write(to: dir.appendingPathComponent(name))
            stored.append(Representation(typeIdentifier: rep.type.identifier, fileName: name, byteCount: rep.data.count))
        }

        let kind = Self.kind(of: reps.map(\.type))
        let text = ClipText.plainText(from: reps.map { ($0.type, $0.data) }) ?? ""
        var image: (width: Int, height: Int)?
        if kind == .image, let data = reps.first(where: { $0.type.conforms(to: .image) })?.data {
            image = Thumbnail.write(from: data, to: dir.appendingPathComponent(ClipFiles.thumbnailName))
        }
        let preview = Self.preview(kind: kind, text: text, name: clip.suggestedName, types: reps.map(\.type))

        let item = ClipItem(id: id, kind: kind, previewText: String(preview.prefix(500)),
                            searchText: String((text.isEmpty ? preview : text).prefix(20_000)),
                            contentHash: hash, representations: stored,
                            hasThumbnail: image != nil, pixelWidth: image?.width ?? 0, pixelHeight: image?.height ?? 0)
        context.insert(item)
        try context.save()
        try Retention.enforce(in: context)
        return .saved
    }

    func delete(_ item: ClipItem) throws {
        try? FileManager.default.removeItem(at: item.directory)
        context.delete(item)
        try context.save()
    }

    // TIFF is a bulky duplicate whenever a compressed image format is present
    private func normalized(_ reps: [IncomingRepresentation]) -> [IncomingRepresentation] {
        let hasCompressedImage = reps.contains { $0.type.conforms(to: .image) && !$0.type.conforms(to: .tiff) }
        return reps.filter { !(hasCompressedImage && $0.type.conforms(to: .tiff)) }
    }

    private func contentHash(_ reps: [IncomingRepresentation]) -> String {
        var hasher = SHA256()
        for rep in reps.sorted(by: { $0.type.identifier < $1.type.identifier }) {
            hasher.update(data: Data(rep.type.identifier.utf8))
            hasher.update(data: rep.data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func kind(of types: [UTType]) -> ClipKind {
        if types.contains(where: { $0.conforms(to: .image) }) { return .image }
        if types.contains(where: { $0.conforms(to: .url) && !$0.conforms(to: .fileURL) }) { return .link }
        if types.contains(where: { ClipText.richTypes.contains($0) }) { return .richText }
        if types.contains(where: { $0.conforms(to: .text) }) { return .text }
        return .file
    }

    private static func preview(kind: ClipKind, text: String, name: String?, types: [UTType]) -> String {
        switch kind {
        case .text, .richText, .link:
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .image:
            return name ?? "Image"
        case .file:
            return name ?? types.first?.localizedDescription ?? "File"
        }
    }
}

enum ClipText {
    static let richTypes: [UTType] = [.rtf, .rtfd, .flatRTFD, .html]

    static func plainText(from reps: [(UTType, Data)]) -> String? {
        if let (_, data) = reps.first(where: { $0.0.conforms(to: .plainText) }),
           let s = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) {
            return s
        }
        if let (_, data) = reps.first(where: { $0.0.conforms(to: .url) && !$0.0.conforms(to: .fileURL) }) {
            if let s = String(data: data, encoding: .utf8), !s.hasPrefix("bplist") { return s }
            if let url = try? PropertyListDecoder().decode([String].self, from: data).first { return url }
        }
        return attributed(from: reps)?.string
    }

    static func attributed(from reps: [(UTType, Data)]) -> NSAttributedString? {
        for (type, data) in reps {
            let docType: NSAttributedString.DocumentType
            if type.conforms(to: .rtf) { docType = .rtf }
            else if type.conforms(to: .flatRTFD) { docType = .rtfd }
            else if type.conforms(to: .html) { docType = .html }
            else { continue }
            if let s = try? NSAttributedString(data: data, options: [.documentType: docType], documentAttributes: nil) {
                return s
            }
        }
        return nil
    }
}

enum Thumbnail {
    static func write(from data: Data, to url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let width = props?[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = props?[kCGImagePropertyPixelHeight] as? Int ?? 0
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 240,
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let jpeg = UIImage(cgImage: thumb).jpegData(compressionQuality: 0.8),
              (try? jpeg.write(to: url)) != nil else { return nil }
        return (width, height)
    }
}

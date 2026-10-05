import Foundation
import SwiftData
import UniformTypeIdentifiers

enum ClipKind: String, Codable, CaseIterable {
    case text, richText, image, link, file
}

struct Representation: Codable, Hashable {
    var typeIdentifier: String
    var fileName: String
    var byteCount: Int

    var type: UTType? { UTType(typeIdentifier) }
}

@Model
final class ClipItem {
    var id: UUID
    var createdAt: Date
    var lastCopiedAt: Date
    var kindRaw: String
    var previewText: String
    var searchText: String
    var contentHash: String
    var isPinned: Bool
    var byteCount: Int
    var representations: [Representation]
    var hasThumbnail: Bool
    var pixelWidth: Int
    var pixelHeight: Int

    init(id: UUID, kind: ClipKind, previewText: String, searchText: String, contentHash: String,
         representations: [Representation], hasThumbnail: Bool, pixelWidth: Int, pixelHeight: Int) {
        let now = Date()
        self.id = id
        self.createdAt = now
        self.lastCopiedAt = now
        self.kindRaw = kind.rawValue
        self.previewText = previewText
        self.searchText = searchText
        self.contentHash = contentHash
        self.isPinned = false
        self.byteCount = representations.reduce(0) { $0 + $1.byteCount }
        self.representations = representations
        self.hasThumbnail = hasThumbnail
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }

    var kind: ClipKind { ClipKind(rawValue: kindRaw) ?? .file }

    var directory: URL { ClipFiles.directory(for: id) }

    var thumbnailURL: URL? { hasThumbnail ? directory.appendingPathComponent(ClipFiles.thumbnailName) : nil }

    func url(for rep: Representation) -> URL { directory.appendingPathComponent(rep.fileName) }

    func data(for rep: Representation) -> Data? { try? Data(contentsOf: url(for: rep)) }

    func firstRepresentation(conformingTo type: UTType) -> Representation? {
        representations.first { $0.type?.conforms(to: type) == true }
    }
}

enum ClipFiles {
    static let thumbnailName = "thumbnail.jpg"

    static var root: URL { AppGroup.containerURL.appendingPathComponent("Clips", isDirectory: true) }

    static func directory(for id: UUID) -> URL { root.appendingPathComponent(id.uuidString, isDirectory: true) }
}

enum ClipDatabase {
    static let shared: ModelContainer = {
        let config = ModelConfiguration(schema: Schema([ClipItem.self]), groupContainer: .identifier(AppGroup.id))
        return try! ModelContainer(for: ClipItem.self, configurations: config)
    }()
}

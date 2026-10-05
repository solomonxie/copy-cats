import Foundation
import SwiftData

enum RetentionPolicy: Hashable, CaseIterable {
    case forever
    case items(Int)
    case days(Int)
    case bytes(Int)

    static let allCases: [RetentionPolicy] = [
        .forever, .items(100), .items(1_000), .days(30), .days(365), .bytes(1_000_000_000),
    ]

    var title: String {
        switch self {
        case .forever: "Forever"
        case .items(let n): "Last \(n.formatted()) items"
        case .days(let n): "Last \(n) days"
        case .bytes(let n): "Up to \(ByteCountFormatter.string(fromByteCount: Int64(n), countStyle: .file))"
        }
    }

    var storageKey: String {
        switch self {
        case .forever: "forever"
        case .items(let n): "items:\(n)"
        case .days(let n): "days:\(n)"
        case .bytes(let n): "bytes:\(n)"
        }
    }

    init(storageKey: String) {
        let parts = storageKey.split(separator: ":")
        let n = parts.count == 2 ? Int(parts[1]) : nil
        switch (parts.first, n) {
        case ("items", let n?): self = .items(n)
        case ("days", let n?): self = .days(n)
        case ("bytes", let n?): self = .bytes(n)
        default: self = .forever
        }
    }
}

enum Retention {
    static let defaultsKey = "retentionPolicy"

    static var policy: RetentionPolicy {
        get { RetentionPolicy(storageKey: AppGroup.defaults.string(forKey: defaultsKey) ?? "") }
        set { AppGroup.defaults.set(newValue.storageKey, forKey: defaultsKey) }
    }

    @MainActor
    static func enforce(in context: ModelContext) throws {
        let policy = policy
        guard policy != .forever else { return }
        let items = try context.fetch(FetchDescriptor<ClipItem>(
            predicate: #Predicate { !$0.isPinned },
            sortBy: [SortDescriptor(\.lastCopiedAt, order: .reverse)]))

        let victims: [ClipItem]
        switch policy {
        case .forever:
            victims = []
        case .items(let n):
            victims = Array(items.dropFirst(n))
        case .days(let n):
            let cutoff = Calendar.current.date(byAdding: .day, value: -n, to: Date())!
            victims = items.filter { $0.lastCopiedAt < cutoff }
        case .bytes(let cap):
            var total = 0
            victims = items.filter { total += $0.byteCount; return total > cap }
        }
        guard !victims.isEmpty else { return }
        for item in victims {
            try? FileManager.default.removeItem(at: item.directory)
            context.delete(item)
        }
        try context.save()
    }

    @MainActor
    static func clearUnpinned(in context: ModelContext) throws {
        let items = try context.fetch(FetchDescriptor<ClipItem>(predicate: #Predicate { !$0.isPinned }))
        for item in items {
            try? FileManager.default.removeItem(at: item.directory)
            context.delete(item)
        }
        try context.save()
    }

    @MainActor
    static func storageUsed(in context: ModelContext) -> Int {
        let items = (try? context.fetch(FetchDescriptor<ClipItem>())) ?? []
        return items.reduce(0) { $0 + $1.byteCount }
    }
}

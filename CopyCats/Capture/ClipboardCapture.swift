import UIKit

@MainActor
enum ClipboardCapture {
    private static let changeCountKey = "lastChangeCount"

    private static var lastChangeCount: Int {
        get { AppGroup.defaults.integer(forKey: changeCountKey) }
        set { AppGroup.defaults.set(newValue, forKey: changeCountKey) }
    }

    static var hasChanged: Bool { UIPasteboard.general.changeCount != lastChangeCount }

    /// Reading triggers the "Allow Paste" prompt unless the user allowed it in Settings.
    @discardableResult
    static func capture(force: Bool = false) async -> SaveResult {
        let pasteboard = UIPasteboard.general
        guard force || hasChanged, pasteboard.numberOfItems > 0 else { return .skipped }
        lastChangeCount = pasteboard.changeCount
        var result = SaveResult.skipped
        for provider in pasteboard.itemProviders {
            guard let clip = await ItemProviderLoader.load(provider),
                  let r = try? ClipStore.shared.save(clip) else { continue }
            if r == .saved || result == .skipped { result = r }
        }
        return result
    }

    static func copy(_ item: ClipItem) {
        var entry: [String: Any] = [:]
        for rep in item.representations {
            if let data = item.data(for: rep) { entry[rep.typeIdentifier] = data }
        }
        UIPasteboard.general.setItems([entry])
        lastChangeCount = UIPasteboard.general.changeCount
        item.lastCopiedAt = Date()
        try? ClipDatabase.shared.mainContext.save()
    }
}

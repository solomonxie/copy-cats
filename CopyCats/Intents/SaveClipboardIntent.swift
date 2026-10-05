import AppIntents
import UniformTypeIdentifiers

struct SaveClipboardIntent: AppIntent {
    static let title: LocalizedStringResource = "Save Clipboard"
    static let description = IntentDescription("Saves what's on the clipboard to your CopyCats history. Pass the output of \"Get Clipboard\" for silent automations.")
    static let openAppWhenRun = false

    @Parameter(title: "Content")
    var content: [IntentFile]?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result: SaveResult
        if let content, !content.isEmpty {
            result = save(content)
        } else {
            result = await ClipboardCapture.capture(force: true)
        }
        switch result {
        case .saved: return .result(dialog: "Saved")
        case .bumped: return .result(dialog: "Already saved")
        case .skipped: return .result(dialog: "Nothing to save")
        }
    }

    @MainActor
    private func save(_ files: [IntentFile]) -> SaveResult {
        var result = SaveResult.skipped
        for file in files {
            let type = file.type ?? UTType(filenameExtension: (file.filename as NSString).pathExtension) ?? .data
            let clip = IncomingClip(representations: [IncomingRepresentation(type: type, data: file.data)],
                                    suggestedName: type.conforms(to: .text) ? nil : file.filename)
            guard let r = try? ClipStore.shared.save(clip) else { continue }
            if r == .saved || result == .skipped { result = r }
        }
        return result
    }
}

struct CopyCatsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SaveClipboardIntent(),
                    phrases: ["Save clipboard in \(.applicationName)", "\(.applicationName) save clipboard"],
                    shortTitle: "Save Clipboard",
                    systemImageName: "doc.on.clipboard")
    }
}

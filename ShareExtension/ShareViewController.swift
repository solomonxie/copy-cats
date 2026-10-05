import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
    private let status = ShareStatus()

    override func viewDidLoad() {
        super.viewDidLoad()
        let host = UIHostingController(rootView: ShareStatusView(status: status))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.backgroundColor = .clear
        view.addSubview(host.view)
        host.didMove(toParent: self)
        Task { await save() }
    }

    private func save() async {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
        var saved = false
        for provider in providers {
            guard let clip = await ItemProviderLoader.load(provider),
                  let result = try? ClipStore.shared.save(clip), result != .skipped else { continue }
            saved = true
        }
        status.state = saved ? .saved : .failed
        try? await Task.sleep(for: .seconds(saved ? 0.8 : 1.6))
        close()
    }

    func close() { extensionContext?.completeRequest(returningItems: nil) }
}

@Observable
final class ShareStatus {
    enum State { case saving, saved, failed }
    var state = State.saving
}

private struct ShareStatusView: View {
    let status: ShareStatus

    var body: some View {
        VStack {
            Spacer()
            Group {
                switch status.state {
                case .saving:
                    ProgressView("Saving…")
                case .saved:
                    Label("Saved to CopyCats", systemImage: "checkmark.circle.fill")
                case .failed:
                    Label("Couldn't save this item", systemImage: "exclamationmark.triangle")
                }
            }
            .font(.headline)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding()
        }
    }
}

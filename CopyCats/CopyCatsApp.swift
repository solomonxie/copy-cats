import SwiftUI

@main
struct CopyCatsApp: App {
    var body: some Scene {
        WindowGroup {
            HistoryView()
        }
        .modelContainer(ClipDatabase.shared)
    }
}

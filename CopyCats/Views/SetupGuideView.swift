import SwiftUI

struct SetupGuideView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            step(1, "Allow paste",
                 "Settings → CopyCats → Paste from Other Apps → Allow. Stops the paste prompt every time.",
                 action: ("Open Settings", URL(string: UIApplication.openSettingsURLString)!))
            step(2, "Save when leaving apps",
                 "Shortcuts → Automation → + → App → choose the apps you copy from → Is Closed → Run Immediately → New Blank Automation → add \"Get Clipboard\", then \"Save Clipboard\" with Content set to Clipboard.",
                 action: ("Open Shortcuts", URL(string: "shortcuts://")!))
            step(3, "One-press save (for Mac copies)",
                 "Settings → Action Button → Shortcut → Save Clipboard. Mac copies expire after about 2 minutes, so press it or open CopyCats soon after copying.",
                 action: nil)
        }
        .navigationTitle("Set up saving")
    }

    private func step(_ number: Int, _ title: String, _ body: String, action: (String, URL)?) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Circle().fill(.tint.opacity(0.15)))
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline)
                Text(body).font(.subheadline).foregroundStyle(.secondary)
                if let action {
                    Button(action.0) { openURL(action.1) }.buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @State private var policy = Retention.policy
    @State private var confirmClear = false
    @State private var storage = 0

    var body: some View {
        Form {
            Section("Automatic saving") {
                NavigationLink("Setup guide", value: Route.setup)
                Button("Paste permission") { openURL(URL(string: UIApplication.openSettingsURLString)!) }
            }
            Section("History") {
                NavigationLink {
                    RetentionPicker(policy: $policy)
                } label: {
                    LabeledContent("Keep history", value: policy.title)
                }
                LabeledContent("Storage used", value: ByteCountFormatter.string(fromByteCount: Int64(storage), countStyle: .file))
                Button("Clear history…", role: .destructive) { confirmClear = true }
            }
            Section("About") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
            }
        }
        .navigationTitle("Settings")
        .onAppear { storage = Retention.storageUsed(in: context) }
        .onChange(of: policy) { _, new in
            Retention.policy = new
            try? Retention.enforce(in: context)
            storage = Retention.storageUsed(in: context)
        }
        .alert("Clear history?", isPresented: $confirmClear) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                try? Retention.clearUnpinned(in: context)
                storage = Retention.storageUsed(in: context)
            }
        } message: {
            Text("Pinned items are kept. This can't be undone.")
        }
    }
}

private struct RetentionPicker: View {
    @Binding var policy: RetentionPolicy

    var body: some View {
        List {
            Section {
                ForEach(RetentionPolicy.allCases, id: \.self) { option in
                    Button {
                        policy = option
                    } label: {
                        HStack {
                            Text(option.title).foregroundStyle(.primary)
                            Spacer()
                            if option == policy { Image(systemName: "checkmark").foregroundStyle(.tint) }
                        }
                    }
                }
            } footer: {
                Text("Pinned items are always kept.")
            }
        }
        .navigationTitle("Keep history")
    }
}

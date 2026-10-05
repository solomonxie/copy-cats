import SwiftData
import SwiftUI

enum ClipFilter: String, CaseIterable {
    case all = "All", text = "Text", images = "Images", links = "Links", files = "Files"

    var kinds: [ClipKind] {
        switch self {
        case .all: []
        case .text: [.text, .richText]
        case .images: [.image]
        case .links: [.link]
        case .files: [.file]
        }
    }
}

struct HistoryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var search = ""
    @State private var filter = ClipFilter.all
    @State private var toast: String?
    @State private var capturing = false
    @State private var refreshID = UUID()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ClipList(search: search, filter: filter, capturing: capturing, onCopy: copied,
                     onSetup: { path.append(Route.setup) })
                .id(refreshID)
                .searchable(text: $search)
                .safeAreaInset(edge: .top) {
                    Picker("Type", selection: $filter) {
                        ForEach(ClipFilter.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                    .background(.bar)
                }
                .navigationTitle("Clipboard")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Save clipboard now", systemImage: "plus") { Task { await capture(force: true) } }
                        Button("Settings", systemImage: "gearshape") { path.append(Route.settings) }
                    }
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .settings: SettingsView()
                    case .setup: SetupGuideView()
                    }
                }
                .navigationDestination(for: ClipItem.self) { DetailView(item: $0, onCopy: copied) }
        }
        .overlay(alignment: .bottom) { ToastView(text: toast) }
        .task { await capture() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshID = UUID() // pick up rows written by extensions
            Task { await capture() }
        }
    }

    private func capture(force: Bool = false) async {
        guard force || ClipboardCapture.hasChanged else { return }
        capturing = true
        let result = await ClipboardCapture.capture(force: force)
        capturing = false
        if force { show(result == .skipped ? "Nothing to save" : "Saved") }
    }

    private func copied() { show("Copied") }

    private func show(_ text: String) {
        withAnimation { toast = text }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation { if toast == text { toast = nil } }
        }
    }
}

enum Route: Hashable { case settings, setup }

private struct ClipList: View {
    @Environment(\.modelContext) private var context
    @Query private var items: [ClipItem]
    let search: String
    let capturing: Bool
    let onCopy: () -> Void
    let onSetup: () -> Void

    init(search: String, filter: ClipFilter, capturing: Bool, onCopy: @escaping () -> Void, onSetup: @escaping () -> Void) {
        self.search = search
        self.capturing = capturing
        self.onCopy = onCopy
        self.onSetup = onSetup
        let kinds = filter.kinds.map(\.rawValue)
        let first = kinds.first ?? ""
        let second = kinds.last ?? ""
        let anyKind = kinds.isEmpty
        _items = Query(filter: #Predicate<ClipItem> { item in
            (anyKind || item.kindRaw == first || item.kindRaw == second)
                && (search.isEmpty || item.searchText.localizedStandardContains(search))
        }, sort: [SortDescriptor(\.lastCopiedAt, order: .reverse)])
    }

    var body: some View {
        List {
            if capturing {
                Label("Saving clipboard…", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.secondary)
            }
            let pinned = items.filter(\.isPinned)
            if !pinned.isEmpty {
                Section("Pinned") { rows(pinned) }
            }
            ForEach(daySections, id: \.title) { section in
                Section(section.title) { rows(section.items) }
            }
        }
        .listStyle(.plain)
        .overlay {
            if items.isEmpty && !capturing {
                if search.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing copied yet", systemImage: "doc.on.clipboard")
                    } description: {
                        Text("Copy something, then come back — it'll be here.")
                    } actions: {
                        Button("Set up automatic saving", action: onSetup).buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: search)
                }
            }
        }
    }

    private var daySections: [(title: String, items: [ClipItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items.filter { !$0.isPinned }) { calendar.startOfDay(for: $0.lastCopiedAt) }
        return grouped.keys.sorted(by: >).map { day in
            let title: String
            if calendar.isDateInToday(day) { title = "Today" }
            else if calendar.isDateInYesterday(day) { title = "Yesterday" }
            else { title = day.formatted(date: .abbreviated, time: .omitted) }
            return (title, grouped[day]!)
        }
    }

    private func rows(_ items: [ClipItem]) -> some View {
        ForEach(items) { item in
            Button {
                ClipboardCapture.copy(item)
                onCopy()
            } label: {
                ClipRow(item: item)
            }
            .tint(.primary)
            .swipeActions(edge: .leading) {
                Button(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin") {
                    item.isPinned.toggle()
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", systemImage: "trash", role: .destructive) { try? ClipStore(context: context).delete(item) }
            }
            .contextMenu {
                Button("Copy", systemImage: "doc.on.doc") { ClipboardCapture.copy(item); onCopy() }
                Button(item.isPinned ? "Unpin" : "Pin", systemImage: "pin") { item.isPinned.toggle() }
                NavigationLink(value: item) { Label("View", systemImage: "eye") }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) { try? ClipStore(context: context).delete(item) }
            }
        }
    }
}

struct ToastView: View {
    let text: String?

    var body: some View {
        if let text {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

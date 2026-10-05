# Clipboard History — Implementation Plan

Design: `DESIGN.md` · UI: `UIUX_DESIGN.md`

## Phase 1: Scaffold
Buildable project with shared App Group first — every later target writes to the same store.

- [x] T1.1 XcodeGen project: app + share extension, iOS 18, App Group, signing via gitignored `Local.xcconfig` — see `project.yml` — depends: none

## Phase 2: Core store
One save pipeline used by every capture source, so it lands before any source.

- [x] T2.1 `ClipItem` model + container in App Group — see `Shared/` — depends: T1.1
- [x] T2.2 Payload files, hashing, dedup, sensitive-type filter — see `Shared/ClipStore.swift`, `Shared/ItemProviderLoader.swift` — depends: T2.1
- [x] T2.3 Retention policy + enforcement, storage size — see `Shared/Retention.swift` — depends: T2.1

## Phase 3: Capture sources
Independent consumers of the store.

- [x] T3.1 Foreground capture on `changeCount` change; copy-back — see `CopyCats/Capture/` — depends: T2.2
- [x] T3.2 `SaveClipboardIntent` (param from Shortcuts, else pasteboard) + App Shortcut — see `CopyCats/Intents/` — depends: T2.2
- [x] T3.3 Share extension — see `ShareExtension/` — depends: T2.2

## Phase 4: UI
Needs real data from Phase 3 to be testable.

- [x] T4.1 History list: search, type filter, pin, delete, toast — `UIUX_DESIGN.md → History` — depends: T3.1
- [x] T4.2 Detail view — `UIUX_DESIGN.md → Detail` — depends: T4.1
- [x] T4.3 Settings + retention picker + clear — `UIUX_DESIGN.md → Settings` — depends: T2.3
- [x] T4.4 Setup guide — `UIUX_DESIGN.md → Setup guide` — depends: T3.2

## Phase 5: Extras & release
- [ ] T5.1 Control Center control (widget extension) running the intent — depends: T3.2
- [ ] T5.2 App Store metadata (no price wording; icon done via `Tools/make_icon.swift`), iPad launch check — depends: T4.*

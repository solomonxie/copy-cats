# iPhone Clipboard History

> 🚧 Work in progress — not yet functional.

Keeps every iPhone copy instead of letting the next one overwrite it. Text, rich text, images, links, files — including copies from a Mac via Universal Clipboard.

## Capture
iOS forbids background clipboard monitoring, so capture is triggered with minimal friction:
- **App open** — auto-saves if `changeCount` changed
- **Shortcuts automation** — "When [apps] are closed" → Get Clipboard → Save (silent)
- **App Intent** — Action Button, Back Tap, Control Center control
- **Share extension** — save selected content directly

One-time setup: Settings → app → Paste from Other Apps → **Allow** (no paste prompts).

## Universal Clipboard (Mac)
- Mac copies land on the iPhone pasteboard, expire in ~2 min
- Data is fetched lazily on read → async load with progress
- Not caught by app-close automation → use app open or Action Button

## Features
- All representations per item kept → paste back with full fidelity
- Dedup by content hash (bump to top)
- Skips concealed / password-manager items
- Search, type filters, pinning
- Retention: forever (default), last N items, last N days, or size cap; pinned exempt
- Storage usage view

## Storage
Local only (no iCloud for now). SwiftData metadata + payload files in an App Group container; stable IDs keep future sync possible.

## Build
Native Swift / SwiftUI, iOS 18+. Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen).
```sh
cp Config/Local.xcconfig.example Config/Local.xcconfig   # set your team, bundle id, app group
xcodegen generate
open CopyCats.xcodeproj
```

Design docs: `docs/design/clipboard-history/`

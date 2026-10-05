# Clipboard History — Design

## Problem
iOS keeps one clipboard item; every copy overwrites the last. Copies from a Mac (Universal Clipboard) vanish the same way. Losing a copied link, snippet or image means redoing the work.

## Goals
- Keep every copy: plain text, rich text, images, links, files
- Capture with near-zero effort — no app switching where avoidable
- Paste back with full fidelity (all original representations)
- Catch Mac copies via Universal Clipboard
- History forever by default; user-chosen retention

## Non-goals
- Custom keyboard
- iCloud sync (for now — data layout stays sync-ready)
- Mac app
- Accounts, server, analytics

## Platform constraints
- No background clipboard access on iOS — capture needs a trigger
- Pasteboard reads prompt "Allow Paste" unless user sets Settings → app → Paste from Other Apps → Allow
- `changeCount` / `detectPatterns` readable without prompt
- Universal Clipboard: expires ~2 min; data fetched lazily from Mac on read

## Options considered
- **Custom keyboard (Full Access)** — captures whenever keyboard shows; rejected: users must switch keyboards, scary permission
- **Background polling** — impossible on iOS
- **Foreground capture only** — reliable but needs app opens
- **Shortcuts automation + App Intent** — "When [apps] are closed" runs silently; no Mac/Universal Clipboard coverage
- **Share extension** — explicit save of anything, no clipboard involved

## Decision
Combine all non-keyboard triggers, one save pipeline:
- App foreground → capture if `changeCount` changed
- App Intent "Save Clipboard" → Shortcuts automation, Action Button, Back Tap
- Control Center control → same intent (later phase)
- Share extension → same pipeline from `NSItemProvider`s
- Guided one-time setup (paste permission, automation, Action Button)

Why: automation covers iPhone-origin copies silently; app open / Action Button covers Mac copies inside the 2-min window; share extension covers "save without copying". Keyboard adds friction for little extra coverage.

## Data
- SwiftData metadata in App Group container (app + extensions share it)
- Payloads as files: `Clips/<item-id>/<n>.<ext>`, one per representation (UTI)
- Thumbnail per image item
- Dedup by SHA-256 over sorted (UTI, bytes) → existing item bumped to top
- Skip sensitive: `org.nspasteboard.ConcealedType`, `TransientType`, password-manager markers
- Retention: forever (default) / last N items / last N days / size cap; pinned exempt
- Stable UUIDs + file payloads keep CloudKit sync addable later

## Risks / open questions
- Whether App Intents can read the pasteboard when run without opening the app — mitigated by passing Shortcuts' "Get Clipboard" output as the intent parameter
- Rich text through Shortcuts may reduce to plain text/file — app-open capture keeps full fidelity
- Large Universal Clipboard images: slow lazy fetch → async load, never block UI
- Unbounded storage growth → storage view + retention settings

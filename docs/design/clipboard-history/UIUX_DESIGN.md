# Clipboard History — UI/UX

Product reasoning: `DESIGN.md`.

## Stories
1. As a user, I want every copy kept automatically, so I never lose something I overwrote.
   - Trigger: copy in Safari, leave Safari → automation saves. Edge: paste permission set to Ask → automation shows prompt once.
2. As a user, I want to copy an old item again, so I can paste it anywhere.
   - Open app → tap row → "Copied" toast. Edge: item is image → copied as image.
3. As a Mac user, I want Mac copies saved, so they survive past Universal Clipboard expiry.
   - Copy on Mac → open app / press Action Button within ~2 min → saved. Edge: slow fetch → loading row.
4. As a user, I want to find an old item, so I don't scroll forever.
   - Search text; filter by type.
5. As a user, I want to control how much is kept, so storage stays reasonable.
   - Settings → Keep history → choose policy; see storage used.
6. As a new user, I want setup to be guided, so automatic capture works without research.

## Screen map
```
      Launch ── capture if changed
        │
        ▼
    ┌ History ┐──tap row──▶ copy + toast
    │         │──long-press─▶ [context menu] ──View──▶ Detail
    │   ⚙ ────┼──▶ Settings ──▶ Setup Guide
    └─────────┘      │
                     └──▶ [iOS Settings app]
   [Share sheet] ──▶ Share extension (save + dismiss)
   [Shortcuts / Action Button / Control Center] ──▶ Save Clipboard intent
```

## History (home)
```
Clipboard                           +   ⚙     ← + = save clipboard now
┌──────────────────────────────────────────┐
│ 🔍 Search                                │
└──────────────────────────────────────────┘
[ ALL | Text | Images | Links | Files ]
PINNED
📌 WiFi: Guest-5G / sunflower-42      Sep 30
TODAY
https://developer.apple.com/docume… 10:42 AM   ← link: url in blue
┌────┐ IMG_2041.png                  10:31 AM
│ ▓▓ │ 1179×2556 · 2.1 MB                       ← thumbnail
└────┘
Meeting notes — **Q4 roadmap**: ship…  9:58 AM   ← rich text badge "Aa"
func capture() async throws {         9:12 AM
YESTERDAY
Order #A-77812 confirmed               6:40 PM
```
- Tap row → copy back; toast `⌐ Copied ¬`
- Swipe right → Pin / Unpin; swipe left → Delete!
- Long-press → context menu
```
┌──────────────┐
│ Copy         │
│ Pin          │
│ View         │
├──────────────┤
│ Delete     ! │
└──────────────┘
```

### States
```
empty      Nothing copied yet
           Copy something, then come back — it'll be here.
           [[ Set up automatic saving ]]
loading    ⟳ Fetching from Mac…            (row placeholder)
no match   No results for "invoice"
```

## Detail
```
‹ Clipboard        Text · 9:58 AM        ⋯
──────────────────────────────────────────
Meeting notes — Q4 roadmap: ship the
sync beta, migrate storage, …
(full content, selectable; image fits width;
 file shows icon + name + size)

FORMATS                    rtf · html · txt   ← representations
SIZE                                 4 KB
──────────────────────────────────────────
            [[ Copy ]]
```
`⋯` → Pin, Share…, Delete!

## Settings
```
‹ Clipboard          Settings
AUTOMATIC SAVING
Setup guide                                 ›
Paste permission                            ›  ← opens iOS Settings (state not readable)
HISTORY
Keep history                        Forever ›
Storage used                          84 MB
( Clear history… )!
ABOUT
Version                                 1.0
```
Keep history options (pushed list):
```
Forever                                     ✓
Last 100 items
Last 1,000 items
Last 30 days
Last 365 days
Up to 1 GB
Pinned items are always kept.
```
Clear confirm:
```
┌────────────────────────────────┐
│  Clear history?                │
│  Pinned items are kept. This   │
│  can't be undone.              │
│      ( Cancel )  [[ Clear ]]!  │
└────────────────────────────────┘
```

## Setup guide
```
‹ Settings        Set up saving
1  Allow paste
   Settings → CopyCats → Paste from
   Other Apps → Allow
   [ Open Settings ]
2  Save when leaving apps
   Shortcuts → Automation → + → App →
   choose apps → Is Closed → Run
   Immediately → add "Save Clipboard"
   [ Open Shortcuts ]
3  One-press save (for Mac copies)
   Settings → Action Button → Shortcut
   → Save Clipboard
```

## Share extension
```
▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
      ✓ Saved to Clipboard        ← auto-dismiss 0.8 s
error ⚠ Couldn't save this item  ( Close )
```

## Copy
| Key | String |
|---|---|
| history.title | Clipboard |
| history.empty.title | Nothing copied yet |
| history.empty.body | Copy something, then come back — it'll be here. |
| history.empty.action | Set up automatic saving |
| toast.copied | Copied |
| intent.title | Save Clipboard |
| share.saved | Saved to Clipboard |

## Deviations
None.

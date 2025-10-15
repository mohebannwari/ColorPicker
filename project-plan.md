Here’s a clean, incremental build plan for a tiny macOS menu-bar color-picker using only system frameworks, SF Symbols, and SF fonts. It uses Apple’s “Liquid Glass” treatment for the panel, stores copied colors for 8 hours, and anchors a Clear History control to the bottom edge. Each step is an isolated task you can hand to Claude Code in order.

Citations to Apple docs are included where it matters.

# Ground rules

* Target: macOS 26 (Tahoe). Use the new glass APIs when available; fall back to NSVisualEffectView on older systems. Apple’s “Liquid Glass” is official and described in Apple’s newsroom and developer tech overview. ([Apple][1])
* Materials and vibrancy guidance live in the HIG and AppKit NSVisualEffectView docs. ([Apple Developer][2])
* Menu bar utilities use SwiftUI `MenuBarExtra` (Ventura+). There’s also a window-style variant. ([Apple Developer][3])
* Use `NSColorSampler` for the eyedropper. It’s the system color loupe, no hacks. ([Apple Developer][4])
* Use `RegisterEventHotKey` (Carbon) for a global shortcut. It’s still the canonical system API; Apple never shipped a modern AppKit replacement. Note it’s technically deprecated; you can still ship with it. ([cocoadev.github.io][5])

# Milestone 0 — Project scaffold

**Task 0.1: App identity**

* App Sandbox on. No special entitlements required for `NSColorSampler`.
* Hide Dock icon: set `LSUIElement=1` in Info.plist so it’s a background agent.

**Task 0.2: Assets and fonts**

* No custom assets. Use SF Symbols.
* Font for hex strings: SF Mono. For everything else: SF (system default).

# Milestone 1 — Status-bar entry

**Task 1.1: Add a `MenuBarExtra`**

* Label icon: `Image(systemName: "eyedropper")`.
* Style: `.window` (a floating panel anchored to the menu bar); prefer this to plain menu if you want a persistent glass panel. ([Apple Developer][6])

**Task 1.2: Provide two actions**

* “Pick Color…” starts `NSColorSampler`.
* “Quit Tint” calls `NSApp.terminate(nil)`.

# Milestone 2 — Liquid Glass panel

**Task 2.1: Define a reusable glass background**

* If macOS 26 SDK exposes the glass view (e.g., `NSGlassEffectView` or equivalent), wrap it in `NSViewRepresentable`.
* Fallback for macOS ≤25: `NSVisualEffectView` with `.hudWindow` or `.popover` material, `state = .active`, `blendingMode = .behindWindow`, window background clear, and rounded corners. ([Apple Developer][7])

**Task 2.2: Window affordances**

* Use the `.window` MenuBarExtra style; it creates a floating panel with rounded corners that matches 26’s increased radii. Do not draw custom chrome. ([Apple Developer][6])

**Task 2.3: Accessibility fallbacks**

* Respect system “Reduce transparency / Increase contrast” since Liquid Glass hurts legibility in some contexts. Ensure your view swaps to an opaque background when transparency is reduced. ([Apple Developer][8])

# Milestone 3 — Data model and persistence

**Task 3.1: Color model**

* `struct Swatch { let hex: String; let rgb: (Int,Int,Int); let timestamp: Date }`.

**Task 3.2: Store**

* `@MainActor class ColorStore: ObservableObject` with:

  * `@Published var history: [Swatch]`
  * `func add(_ color: NSColor)`
  * `func purgeOlderThan(hours: 8)`
  * Persistence via `UserDefaults` (JSON encoded). Load on launch; purge on load and on every add.

**Task 3.3: 8-hour retention**

* On `add`, append, then purge where `Date().timeIntervalSince(s.timestamp) > 8*3600`.
* On timer every 15 minutes, purge to keep it tidy.

# Milestone 4 — Eyedropper and hex conversion

**Task 4.1: Color picking**

* Integrate `NSColorSampler`: call `show` with completion, convert picked `NSColor` to sRGB, then to hex, store, and copy to pasteboard. ([Apple Developer][4])

**Task 4.2: Hex utility**

* Convert sRGB floats to 0–255, format `#RRGGBB` uppercase. Round by `Int(round(... * 255))`.

**Task 4.3: Copy to pasteboard**

* `NSPasteboard.general.clearContents()` then `setString(hex, forType: .string)`.

# Milestone 5 — UI layout (the panel)

**Task 5.1: Panel structure**

* Glass background container with fixed width ≈ 320–360 pt.
* Content VStack:

  * Scrollable History list
  * Spacer
  * Bottom-anchored “Clear history” button, full-width, subtle tinted pill matching system destructive role but not bright red unless hovered.

**Task 5.2: Row design (as in your wireframe)**

* HStack with:

  * Left: circular color preview, 28 pt diameter, 1 pt white stroke with low opacity to keep edge visible on busy backgrounds.
  * Middle: monospaced hex label using SF Mono, 13–14 pt, selectable false.
  * Right: Copy button with `doc.on.doc` SF Symbol, bordered or tint-accented.
* Row height ≈ 40 pt.
* On row tap or Copy button tap: copy hex to pasteboard and give 300 ms “Copied” checkmark feedback.

**Task 5.3: Empty state**

* If history empty: center label “No colors yet.” subdued, following HIG materials guidance. ([Apple Developer][2])

**Task 5.4: Clear History control**

* Bottom edge anchored within the glass container using a safe bottom inset so the button never floats. Use `.controlSize(.large)` and destructive role.

# Milestone 6 — Global hotkey

**Task 6.1: Register a default shortcut**

* Default: ⌘⇧C.
* Implement global registration with Carbon `RegisterEventHotKey` and an Event Handler that posts to main queue to call `NSColorSampler`. Provide a small preferences struct so the key combo is easy to swap later. ([cocoadev.github.io][5])

**Task 6.2: Deprecation note**

* Carbon hotkeys are deprecated but remain the system method for global shortcuts; track this in code comments and isolate in one file for drop-in replacement later. ([GitHub][9])

# Milestone 7 — Menu commands

**Task 7.1: Command equivalents**

* Add an app Command “Pick Color…” with KeyboardShortcut(“c”, modifiers: [.command, .shift]) so the shortcut works when the app is frontmost, even if Carbon registration fails or is disabled in permissions.

# Milestone 8 — App state and view wiring

**Task 8.1: App object**

* `@main struct TintApp: App { @StateObject var store = ColorStore() … }`
* `MenuBarExtra("Tint", systemImage: "eyedropper", isInserted: .constant(true)) { PanelView().environmentObject(store) } .menuBarExtraStyle(.window)`

**Task 8.2: Pick action**

* Expose `func pickColor()` on the App or a singleton service. Call from:

  * The menu bar button
  * The global hotkey handler
  * A “Pick” button inside the panel (optional)

# Milestone 9 — Liquid Glass polish checklist

Apply these if building on macOS 26:

* Use the system Liquid Glass material for the panel background. Apple’s WWDC25 notes and tech overview describe the new glass regions and window framing; keep hierarchy simple and let the system render glass. ([Apple Developer][10])
* Avoid heavy tints or custom blur radii. The HIG emphasizes letting the material provide separation; contrast comes from foreground styling. ([Apple Developer][2])
* Respect Accessibility: if transparency is reduced, swap to an opaque background (system grouped background). ([Apple Developer][8])

# Milestone 10 — Testing

**Task 10.1: Functional**

* Verify picker returns sRGB colors.
* Verify pasteboard after every pick.
* Verify history trims correctly across time changes and sleep/wake.

**Task 10.2: Visual**

* Test light/dark modes, increased contrast, reduced transparency.
* Ensure row edges remain visible over noisy wallpapers.

**Task 10.3: Performance**

* History size cap, e.g., 200 entries. Purge on add. No timers tighter than 15 minutes.

# Minimal code stubs for Claude to fill

Use these as starting points; keep them small so you can extend incrementally.

**Store**

```swift
final class ColorStore: ObservableObject {
    @Published private(set) var history: [Swatch] = []
    private let key = "history.v1"

    func add(_ color: NSColor) {
        let rgb = color.usingColorSpace(.sRGB) ?? color
        let hex = String(format: "#%02X%02X%02X",
                         Int(round(rgb.redComponent * 255)),
                         Int(round(rgb.greenComponent * 255)),
                         Int(round(rgb.blueComponent * 255)))
        let s = Swatch(hex: hex,
                       rgb: (Int(round(rgb.redComponent*255)),
                             Int(round(rgb.greenComponent*255)),
                             Int(round(rgb.blueComponent*255))),
                       timestamp: Date())
        history.insert(s, at: 0)
        purgeOlderThan(hours: 8)
        persist()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hex, forType: .string)
    }

    func purgeOlderThan(hours: Double) {
        let cutoff = Date().addingTimeInterval(-hours*3600)
        history.removeAll { $0.timestamp < cutoff }
    }

    // load()/persist() use JSONEncoder/Decoder + UserDefaults
}
```

**Picker**

```swift
func pickColor(store: ColorStore) {
    NSColorSampler().show { color in
        guard let c = color else { return }
        DispatchQueue.main.async { store.add(c) }
    }
}
```

([Apple Developer][4])

**Global hotkey shim (Carbon)**

```swift
// Encapsulate Carbon usage in one file for easy replacement later.
final class HotKeyService {
    private var hotKeyRef: EventHotKeyRef?

    func register() {
        var gMyHotKeyID = EventHotKeyID(signature: OSType(UInt32(truncatingIfNeeded: ("TiNT" as NSString).longLongValue)),
                                        id: UInt32(1))
        RegisterEventHotKey(UInt32(kVK_ANSI_C),
                            UInt32(cmdKey | shiftKey),
                            gMyHotKeyID,
                            GetApplicationEventTarget(),
                            0,
                            &hotKeyRef)
        // Install handler to call pickColor(...)
    }
}
```

([cocoadev.github.io][5])

**Glass background wrapper (fallback)**

```swift
struct GlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.state = .active
        v.blendingMode = .behindWindow
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {}
}
```

([Apple Developer][7])

# Deliverables checklist

* Swift package with the app target and no third-party deps.
* One Swift file per topic: `TintApp.swift`, `PanelView.swift`, `ColorStore.swift`, `HotKeyService.swift`, `GlassBackground.swift`.
* Unit test for `purgeOlderThan`.
* App icon is not needed; the status item uses the SF Symbol “eyedropper”.

# What this app does not do

* No multi-format output, no color spaces beyond sRGB, no eyedropper magnifier custom UI, no preferences pane. Deliberately lean.

# References

* Apple newsroom: Liquid Glass and the new design system. ([Apple][1])
* Developer tech overview: Liquid Glass. ([Apple Developer][11])
* HIG: Materials and vibrancy; general design guidance. ([Apple Developer][2])
* AppKit: `NSVisualEffectView` and materials. ([Apple Developer][12])
* SwiftUI: `MenuBarExtra` and window style. ([Apple Developer][3])
* AppKit: `NSColorSampler`. ([Apple Developer][4])
* AppKit: `NSPanel` background component, if you swap away from `.window` style. ([Apple Developer][13])
* Carbon: `RegisterEventHotKey` and deprecation context. ([cocoadev.github.io][5])

Build it in this order. Keep it tiny. The only task is picking a color, copying its hex, and keeping an 8-hour list with a bottom-anchored Clear History. Verification complete.

[1]: https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/?utm_source=chatgpt.com "Apple introduces a delightful and elegant new software ..."
[2]: https://developer.apple.com/design/human-interface-guidelines/materials?utm_source=chatgpt.com "Materials | Apple Developer Documentation"
[3]: https://developer.apple.com/documentation/SwiftUI/MenuBarExtra?utm_source=chatgpt.com "MenuBarExtra | Apple Developer Documentation"
[4]: https://developer.apple.com/documentation/appkit/nscolorsampler?utm_source=chatgpt.com "NSColorSampler | Apple Developer Documentation"
[5]: https://cocoadev.github.io/RegisterEventHotKey/?utm_source=chatgpt.com "RegisterEventHotKey - CocoaDev"
[6]: https://developer.apple.com/documentation/swiftui/menubarextrastyle?utm_source=chatgpt.com "MenuBarExtraStyle | Apple Developer Documentation"
[7]: https://developer.apple.com/documentation/appkit/nsvisualeffectview/material-swift.enum/hudwindow?utm_source=chatgpt.com "NSVisualEffectView.Material.hudWindow"
[8]: https://developer.apple.com/design/human-interface-guidelines/color?utm_source=chatgpt.com "Color | Apple Developer Documentation"
[9]: https://github.com/keepassxreboot/keepassxc/issues/3310?utm_source=chatgpt.com "Replace Carbon HotKey registration with NSEvent API #3310"
[10]: https://developer.apple.com/videos/play/wwdc2025/310/?utm_source=chatgpt.com "Build an AppKit app with the new design - WWDC25 - Videos"
[11]: https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass?utm_source=chatgpt.com "Liquid Glass | Apple Developer Documentation"
[12]: https://developer.apple.com/documentation/appkit/nsvisualeffectview?utm_source=chatgpt.com "NSVisualEffectView | Apple Developer Documentation"
[13]: https://developer.apple.com/documentation/appkit/nspanel?utm_source=chatgpt.com "NSPanel | Apple Developer Documentation"

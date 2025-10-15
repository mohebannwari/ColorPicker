# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ColorPicker (branded as "Tint") is a macOS 26+ menu bar utility for picking colors, storing them with 8-hour retention, and copying hex values to the clipboard. The app uses macOS Liquid Glass effects, NSColorSampler, and Carbon hotkeys for global shortcuts.

**Current Status:** Basic SwiftUI/SwiftData template. All advanced features (NSColorSampler, MenuBarExtra, Liquid Glass, hotkeys) are NOT YET IMPLEMENTED.

## Build Commands

### Development
```bash
# Open project in Xcode
open ColorPicker.xcodeproj

# Build for development
xcodebuild build -project ColorPicker.xcodeproj -scheme ColorPicker -configuration Debug

# Run the app (after building)
open build/Debug/ColorPicker.app
```

### Testing
```bash
# Test on specific architecture
xcodebuild build -project ColorPicker.xcodeproj -scheme ColorPicker -destination 'platform=macOS,arch=arm64'
xcodebuild build -project ColorPicker.xcodeproj -scheme ColorPicker -destination 'platform=macOS,arch=x86_64'

# Test universal binary
xcodebuild build -project ColorPicker.xcodeproj -scheme ColorPicker -destination 'generic/platform=macOS'
```

### Release Build
```bash
# Clean build
xcodebuild clean -project ColorPicker.xcodeproj -scheme ColorPicker

# Build for release
xcodebuild build -project ColorPicker.xcodeproj -scheme ColorPicker -configuration Release

# Archive for App Store
xcodebuild archive -project ColorPicker.xcodeproj -scheme ColorPicker -archivePath ColorPicker.xcarchive

# Export (requires ExportOptions.plist)
xcodebuild -exportArchive -archivePath ColorPicker.xcarchive -exportPath ./dist -exportOptionsPlist ExportOptions.plist
```

## Architecture

### Target Platform
- **macOS:** 26.0 (Tahoe) minimum
- **Architectures:** Universal Binary (arm64, x86_64)
- **Deployment Target:** `MACOSX_DEPLOYMENT_TARGET = 26.0`
- **App Type:** Menu bar utility (LSUIElement=1 to hide Dock icon)

### Core Technologies
- **SwiftUI:** UI framework with MenuBarExtra for menu bar integration
- **AppKit Integration:**
  - `NSColorSampler` for system color picker (eyedropper)
  - `NSVisualEffectView` for glass effects (macOS <26 fallback)
  - `NSPasteboard` for clipboard operations
- **Carbon APIs:** `RegisterEventHotKey` for global hotkey (⌘⇧C)
- **Persistence:** UserDefaults with JSON encoding for color history
- **Design System:** SF Symbols ("eyedropper"), SF Mono font for hex display

### Key Design Decisions
1. **No Third-Party Dependencies:** Pure Apple frameworks only
2. **Privacy-First:** No network access, no analytics, local storage only
3. **Sandboxed:** Minimal entitlements (app-sandbox enabled)
4. **Accessibility:** Respects reduced transparency and increased contrast
5. **8-Hour Retention:** Color history automatically purges after 8 hours

## Project Structure

```
ColorPicker/
├── ColorPickerApp.swift       # Main app entry point with SwiftData (TEMPLATE)
├── ContentView.swift           # Current template view (TO BE REPLACED)
├── Item.swift                  # SwiftData model (TO BE REMOVED)
├── ColorPicker.entitlements    # Sandbox configuration
└── Assets.xcassets/            # App assets (SF Symbols only)
```

### Planned Structure (NOT YET IMPLEMENTED)
```
ColorPicker/
├── TintApp.swift              # Main app with MenuBarExtra
├── PanelView.swift            # Glass panel UI
├── ColorStore.swift           # ObservableObject for color history
├── HotKeyService.swift        # Carbon hotkey registration
├── GlassBackground.swift      # NSViewRepresentable for glass effect
└── Models/
    └── Swatch.swift           # Color model (hex, rgb, timestamp)
```

## Development Plan (Milestones)

The project follows a 10-milestone incremental build plan (see `project-plan.md`). Each milestone is an isolated task:

### Phase 1: Foundation (Milestones 0-4)
- **M0:** Project scaffold (LSUIElement, entitlements, assets)
- **M1:** MenuBarExtra with eyedropper icon
- **M2:** Liquid Glass panel (NSGlassEffectView fallback)
- **M3:** ColorStore with 8-hour retention and UserDefaults persistence
- **M4:** NSColorSampler integration and hex conversion

### Phase 2: UI & Integration (Milestones 5-7)
- **M5:** Panel layout (history list, color rows, clear button)
- **M6:** Global hotkey (⌘⇧C via Carbon RegisterEventHotKey)
- **M7:** Menu commands with keyboard shortcuts

### Phase 3: Polish (Milestones 8-10)
- **M8:** Wire app state and pick actions
- **M9:** Apply Liquid Glass polish and accessibility
- **M10:** Testing (functional, visual, performance)

## Key Implementation Details

### Color Data Model
```swift
struct Swatch {
    let hex: String           // "#RRGGBB" format
    let rgb: (Int, Int, Int)  // 0-255 values
    let timestamp: Date       // For 8-hour purge
}
```

### ColorStore Pattern
- `@MainActor class ColorStore: ObservableObject`
- `@Published private(set) var history: [Swatch]`
- Automatic purge on every `add()` call
- Timer-based cleanup every 15 minutes
- JSON encoding to UserDefaults (key: "history.v1")

### Global Hotkey (Carbon)
- **API:** `RegisterEventHotKey` (deprecated but canonical)
- **Default:** ⌘⇧C (kVK_ANSI_C + cmdKey | shiftKey)
- **Isolation:** Keep in `HotKeyService.swift` for easy replacement
- **Note:** Track deprecation in code comments

### Liquid Glass Implementation
- **macOS 26+:** Use `NSGlassEffectView` if available
- **Fallback:** `NSVisualEffectView` with `.hudWindow` material
- **Accessibility:** Swap to opaque background when transparency is reduced
- **Panel Style:** `.window` MenuBarExtra style for rounded corners

### Clipboard Integration
```swift
NSPasteboard.general.clearContents()
NSPasteboard.general.setString(hex, forType: .string)
```

### Hex Conversion
```swift
// sRGB floats → 0-255 → #RRGGBB uppercase
let rgb = color.usingColorSpace(.sRGB) ?? color
let hex = String(format: "#%02X%02X%02X",
                 Int(round(rgb.redComponent * 255)),
                 Int(round(rgb.greenComponent * 255)),
                 Int(round(rgb.blueComponent * 255)))
```

## Configuration

### Entitlements (ColorPicker.entitlements)
- `com.apple.security.app-sandbox`: YES (sandboxed)
- `com.apple.security.files.user-selected.read-only`: YES (optional file ops)
- `com.apple.security.network.client`: YES (not used, can remove)
- `com.apple.security.print`: YES (optional)
- **Temporary exceptions:** Remove before production

### Info.plist (Auto-generated)
- `CFBundleDisplayName`: "Tint"
- `LSUIElement`: 1 (hide Dock icon)
- `LSApplicationCategoryType`: "public.app-category.utilities"
- `NSHighResolutionCapable`: YES

### Build Settings
- **Development Team:** RS2ZG352RH
- **Bundle Identifier:** com.mohebanwari.ColorPicker
- **Swift Version:** 5.0
- **Code Signing:** Automatic
- **Sandbox:** Enabled
- **Hardened Runtime:** Enabled

## Testing Strategy

### Functional Testing
```bash
# Verify NSColorSampler returns sRGB colors
# Verify pasteboard after every pick
# Verify history trims correctly across sleep/wake
# Verify global hotkey works system-wide
```

### Visual Testing
```bash
# Test light/dark modes
# Test increased contrast mode
# Test reduced transparency mode
# Verify row edges visible over busy wallpapers
```

### Performance Testing
```bash
# Cap history at 200 entries
# Purge on every add
# No timers tighter than 15 minutes
# Verify < 1s startup time
# Verify < 100ms hotkey response
```

## Common Development Tasks

### Starting Development
1. Read `project-plan.md` for detailed milestone specifications
2. Start with Milestone 0: Configure Info.plist and entitlements
3. Remove template code (ContentView.swift, Item.swift)
4. Implement milestones sequentially

### Debugging
- Follow guidance in `.cursor/debug.md`: analyze comprehensively, check related code, use Context7 for docs
- Check entitlements if NSColorSampler or hotkeys fail
- Verify LSUIElement=1 if menu bar icon doesn't appear
- Test accessibility settings for glass rendering issues

### Git Workflow
- Commit messages should match repo style (see `.cursor/git_push.md`)
- Use descriptive messages focusing on "why" not "what"
- Commands: `git add . && git commit -m "message" && git push`

## Important Notes

### Carbon API Deprecation
`RegisterEventHotKey` is deprecated but remains the canonical API for global hotkeys. Apple has no modern replacement. Isolate in `HotKeyService.swift` for future replacement.

### macOS 26 Liquid Glass
- Apple's new design language with 40% GPU reduction vs traditional blur
- Uses increased corner radii (12pt default)
- Requires respecting accessibility settings
- Fallback to NSVisualEffectView on older systems

### No Custom Assets
- Use SF Symbols exclusively (e.g., "eyedropper" for menu bar)
- Use SF Mono for hex display
- Use SF (system default) for all other text
- No app icon needed (menu bar apps can use SF Symbol)

### Privacy & Security
- No network access required
- No analytics or telemetry
- Colors stored locally in UserDefaults
- 8-hour automatic cleanup ensures minimal data retention
- Sandboxed with minimal entitlements

## References

Key Apple documentation:
- [NSColorSampler](https://developer.apple.com/documentation/appkit/nscolorsampler)
- [MenuBarExtra](https://developer.apple.com/documentation/SwiftUI/MenuBarExtra)
- [NSVisualEffectView](https://developer.apple.com/documentation/appkit/nsvisualeffectview)
- [Materials & Vibrancy HIG](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Liquid Glass Overview](https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass)
- [Carbon RegisterEventHotKey](https://cocoadev.github.io/RegisterEventHotKey/)

## Current Task Status

See `TODO` file for milestone tracking. Current state: basic template, awaiting Milestone 0 implementation.

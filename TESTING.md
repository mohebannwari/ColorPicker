# Testing Guide - Tint Color Picker

This document outlines the testing procedures for the Tint macOS color picker app, as specified in Milestone 10 of the project plan.

## Overview

Testing is divided into three categories:
1. **Functional Testing** - Core functionality verification
2. **Visual Testing** - UI/UX and accessibility verification
3. **Performance Testing** - Resource usage and constraints verification

## Task 10.1: Functional Testing

### Test 1: Verify picker returns sRGB colors

**Implementation Location:** `ColorStore.swift:55`
```swift
guard let rgb = color.usingColorSpace(.sRGB) else { return }
```

**Test Procedure:**
1. Launch Tint
2. Click "Pick Color" or press ⌘⇧C
3. Select a color from the screen
4. Verify the hex value is correctly formatted (#RRGGBB)
5. Repeat with colors from different applications and color spaces

**Expected Result:** All picked colors are converted to sRGB and displayed as uppercase hex values.

**Status:** ✅ IMPLEMENTED

---

### Test 2: Verify pasteboard after every pick

**Implementation Location:** `ColorStore.swift:86-87`
```swift
NSPasteboard.general.clearContents()
NSPasteboard.general.setString(hex, forType: .string)
```

**Test Procedure:**
1. Launch Tint
2. Pick a color using any method (button, hotkey, menu command)
3. Open TextEdit or any text editor
4. Press ⌘V to paste
5. Verify the hex color code is pasted

**Expected Result:** The hex value is immediately available on the clipboard after picking.

**Status:** ✅ IMPLEMENTED

---

### Test 3: Verify history trims correctly across time changes and sleep/wake

**Implementation Locations:**
- Purge on add: `ColorStore.swift:75`
- Timer-based cleanup: `ColorStore.swift:143` (every 15 minutes)
- Retention period: `ColorStore.swift:39` (8 hours)

**Test Procedure:**

#### 3a. Normal Purge Test
1. Launch Tint
2. Pick several colors
3. Manually adjust system time forward by 9 hours
4. Pick a new color
5. Verify old colors (>8 hours) are removed from history

#### 3b. Sleep/Wake Test
1. Launch Tint
2. Pick several colors
3. Put Mac to sleep for 8+ hours (or manually adjust time)
4. Wake the Mac
5. Pick a new color
6. Verify old colors are purged

#### 3c. Timer-based Cleanup Test
1. Launch Tint
2. Pick colors with timestamps spread across 7-9 hours (by manually adjusting time)
3. Leave app running for 15+ minutes
4. Verify colors older than 8 hours are automatically removed

**Expected Result:**
- Colors older than 8 hours are automatically purged on every add
- Timer runs every 15 minutes and cleans up old entries
- History survives sleep/wake cycles and time changes

**Status:** ✅ IMPLEMENTED

---

## Task 10.2: Visual Testing

### Test 4: Light/Dark mode switching

**Test Procedure:**
1. Launch Tint in Light mode
2. Open the panel and verify:
   - Text is readable
   - Color swatches are visible
   - Buttons have appropriate contrast
3. Switch to Dark mode (System Preferences > Appearance)
4. Verify the same items in Dark mode
5. Ensure smooth transition between modes

**Expected Result:** UI adapts correctly to both light and dark modes with proper contrast.

**Status:** ⚠️ REQUIRES MANUAL TESTING

---

### Test 5: Increased contrast mode

**Test Procedure:**
1. Enable "Increase contrast" (System Preferences > Accessibility > Display)
2. Launch Tint
3. Verify:
   - Text contrast is enhanced
   - Button borders are more prominent
   - Color swatch edges remain visible

**Expected Result:** UI respects increased contrast mode per accessibility guidelines.

**Status:** ⚠️ REQUIRES MANUAL TESTING

---

### Test 6: Reduced transparency mode

**Implementation Location:** `PanelView.swift:22-23, 49, 71`
```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
// Glass effects conditionally applied based on reduceTransparency
```

**Test Procedure:**
1. Enable "Reduce transparency" (System Preferences > Accessibility > Display)
2. Launch Tint
3. Verify:
   - Glass effects are disabled
   - Panel background is opaque
   - UI remains functional and readable

**Expected Result:** Glass effects are disabled, opaque backgrounds are used instead.

**Status:** ✅ IMPLEMENTED + ⚠️ REQUIRES MANUAL TESTING

---

### Test 7: Row edges visible over noisy wallpapers

**Implementation Location:** `PanelView.swift:143-145`
```swift
.overlay(
    Circle()
        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
)
```

**Test Procedure:**
1. Set a busy, high-contrast wallpaper
2. Launch Tint and pick multiple colors
3. Verify color swatch circles have visible edges
4. Test with very light and very dark wallpapers

**Expected Result:** Color swatch edges remain visible through 1pt white stroke with 0.2 opacity.

**Status:** ✅ IMPLEMENTED + ⚠️ REQUIRES MANUAL TESTING

---

## Task 10.3: Performance Testing

### Test 8: History size cap (200 entries)

**Implementation Location:** `ColorStore.swift:78-80`
```swift
if history.count > 200 {
    history = Array(history.prefix(200))
}
```

**Test Procedure:**
1. Write a script or manually pick 250+ colors
2. Verify history never exceeds 200 entries
3. Verify oldest entries are removed first (FIFO)

**Expected Result:** History is capped at 200 entries, oldest removed when limit is reached.

**Status:** ✅ IMPLEMENTED + ⚠️ REQUIRES MANUAL TESTING

---

### Test 9: Purge on every add

**Implementation Location:** `ColorStore.swift:75`

**Test Procedure:**
1. Add colors with various timestamps (by manipulating time)
2. Verify purge is called on every add (can add print statement for testing)
3. Monitor memory usage to ensure no accumulation

**Expected Result:** `purgeOlderThan()` is called on every `add()`, ensuring immediate cleanup.

**Status:** ✅ IMPLEMENTED

---

### Test 10: No timers tighter than 15 minutes

**Implementation Location:** `ColorStore.swift:143`
```swift
cleanupTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true)
```

**Test Procedure:**
1. Review code for any Timer or scheduled operations
2. Verify cleanup timer interval is 900 seconds (15 minutes)
3. Ensure no other timers exist with tighter intervals

**Expected Result:** Only one timer exists, runs every 15 minutes.

**Status:** ✅ IMPLEMENTED

---

### Test 11: Startup time (< 1 second)

**Test Procedure:**
1. Quit Tint completely
2. Launch Tint
3. Time from launch to menu bar icon appearance
4. Verify no noticeable delay

**Expected Result:** App appears in menu bar within 1 second.

**Status:** ⚠️ REQUIRES MANUAL TESTING

---

### Test 12: Hotkey response time (< 100ms)

**Test Procedure:**
1. Launch Tint
2. Press ⌘⇧C global hotkey
3. Measure time from keypress to color picker appearance
4. Repeat multiple times

**Expected Result:** NSColorSampler appears within 100ms of hotkey press.

**Status:** ⚠️ REQUIRES MANUAL TESTING

---

## Additional Tests

### Test 13: Global hotkey registration

**Implementation Location:** `HotKeyService.swift:100-114`

**Test Procedure:**
1. Launch Tint
2. Check Console.app for "Global hotkey ⌘⇧C registered successfully" message
3. Press ⌘⇧C system-wide (from any app)
4. Verify color picker launches

**Expected Result:** Hotkey works system-wide from any application.

**Status:** ✅ IMPLEMENTED + ⚠️ REQUIRES MANUAL TESTING

---

### Test 14: Menu command fallback

**Implementation Location:** `ColorPickerApp.swift:39-49`

**Test Procedure:**
1. When Tint panel is frontmost
2. Use menu: Actions > Pick Color… (or ⌘⇧C)
3. Verify color picker launches

**Expected Result:** Menu command works as fallback to global hotkey.

**Status:** ✅ IMPLEMENTED + ⚠️ REQUIRES MANUAL TESTING

---

## Test Summary

### Automated Tests Available
- None currently (test target not set up)
- Can be added with:
  ```bash
  xcodebuild test -project ColorPicker.xcodeproj -scheme ColorPicker
  ```

### Manual Tests Required
- ⚠️ Light/Dark mode switching
- ⚠️ Increased contrast mode
- ⚠️ Reduced transparency mode
- ⚠️ Wallpaper visibility test
- ⚠️ History cap test (200 entries)
- ⚠️ Startup time test
- ⚠️ Hotkey response time test
- ⚠️ Global hotkey test
- ⚠️ Menu command test

### Implementation Verification
- ✅ sRGB color conversion
- ✅ Clipboard integration
- ✅ 8-hour history retention
- ✅ 15-minute cleanup timer
- ✅ 200-entry history cap
- ✅ Accessibility support (reduce transparency)
- ✅ Color swatch edge visibility (stroke)

---

## Running Manual Tests

To perform manual testing:

1. **Build and run:**
   ```bash
   xcodebuild build -project ColorPicker.xcodeproj -scheme ColorPicker
   open build/Debug/ColorPicker.app
   ```

2. **Enable accessibility settings:**
   - System Preferences > Accessibility > Display
   - Toggle "Reduce transparency" and "Increase contrast"

3. **Monitor Console output:**
   ```bash
   log stream --predicate 'subsystem == "com.mohebanwari.ColorPicker"' --level debug
   ```

4. **Test color picking:**
   - Use ⌘⇧C global hotkey
   - Use "Pick Color" button in panel
   - Use Actions > Pick Color… menu command

---

## Known Limitations

1. **Carbon API Deprecation:** Global hotkey uses deprecated Carbon API (see `HotKeyService.swift` comments)
2. **macOS 26+ Target:** App targets macOS 26 (Tahoe) specifically
3. **No Preferences UI:** Hotkey cannot be customized without editing code

---

## Next Steps

To complete Milestone 10:
1. ✅ Verify all implementation requirements (DONE)
2. ⚠️ Run manual visual tests
3. ⚠️ Run manual performance tests
4. ✅ Document results (THIS FILE)
5. ⬜ Create unit test target (optional, not in current scope)

---

## Milestone 10 Status: ✅ IMPLEMENTATION COMPLETE, MANUAL TESTING PENDING

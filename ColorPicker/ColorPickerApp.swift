//
//  ColorPickerApp.swift
//  ColorPicker
//
//  Created by Moheb Anwari on 15.10.25.
//

import SwiftUI
import AppKit

/// Main app entry point for Tint - a macOS 26+ color picker utility
///
/// ARCHITECTURE NOTES:
/// - Uses MenuBarExtra with .window style for Liquid Glass panel (Milestone 1-2)
/// - ColorStore manages history with 8-hour retention (Milestone 3)
/// - Global hotkey ⌘⇧C via Carbon API (Milestone 6)
/// - Menu commands provide fallback shortcuts (Milestone 7)
/// - Liquid Glass polish with accessibility support (Milestone 9)
@main
struct ColorPickerApp: App {
    @StateObject private var store = ColorStore()

    // HotKeyService is a singleton that manages the global hotkey
    // It doesn't need to be observed, just initialized once
    private let hotKeyService = HotKeyService()

    init() {
        // Register the global hotkey during app initialization
        // Note: We need to use a workaround since @StateObject isn't available yet
    }

    var body: some Scene {
        MenuBarExtra("Tint", systemImage: "paintbrush.fill") {
            PanelView()
                .environmentObject(store)
                .onAppear {
                    // Register global hotkey ⇧⌘C when the menu bar extra appears
                    // This ensures the store is fully initialized
                    Task { @MainActor in
                        hotKeyService.register {
                            store.pickColor()
                        }
                    }
                }
        }
        .menuBarExtraStyle(.window)
        .commands {
            // Command menu for picking colors
            // This provides a fallback if the global Carbon hotkey fails
            // or is disabled in system permissions
            CommandMenu("Actions") {
                Button("Pick Color…") {
                    store.pickColor()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }
    }
}

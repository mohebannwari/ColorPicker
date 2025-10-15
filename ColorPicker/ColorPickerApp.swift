//
//  ColorPickerApp.swift
//  ColorPicker
//
//  Created by Moheb Anwari on 15.10.25.
//

import SwiftUI
import AppKit

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
        MenuBarExtra("Tint", systemImage: "eyedropper") {
            PanelView()
                .environmentObject(store)
                .onAppear {
                    // Register global hotkey ⌥⌘T when the menu bar extra appears
                    // This ensures the store is fully initialized
                    Task { @MainActor in
                        hotKeyService.register {
                            store.pickColor()
                        }
                    }
                }
        }
        .menuBarExtraStyle(.window)
    }
}

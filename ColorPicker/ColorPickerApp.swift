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

    var body: some Scene {
        MenuBarExtra("Tint", systemImage: "eyedropper") {
            VStack(alignment: .leading, spacing: 8) {
                Button("Pick Color…") {
                    pickColor()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Divider()

                Button("Quit Tint") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
            .padding()
            .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }

    private func pickColor() {
        NSColorSampler().show { color in
            guard let selectedColor = color else { return }

            // ColorStore handles sRGB conversion, hex conversion, persistence, and clipboard
            Task { @MainActor in
                store.add(selectedColor)
            }
        }
    }
}

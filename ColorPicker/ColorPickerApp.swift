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
            PanelView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}

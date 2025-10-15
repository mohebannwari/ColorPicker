//
//  ColorStore.swift
//  ColorPicker
//
//  Created by Moheb Anwari on 15.10.25.
//

import SwiftUI
import AppKit
import Combine

/// A single color swatch with hex, RGB values, and timestamp
struct Swatch: Codable, Identifiable {
    let id: UUID
    let hex: String           // "#RRGGBB" format
    let rgb: RGB              // 0-255 values
    let timestamp: Date       // For 8-hour purge

    struct RGB: Codable {
        let red: Int
        let green: Int
        let blue: Int
    }

    init(hex: String, rgb: RGB, timestamp: Date = Date()) {
        self.id = UUID()
        self.hex = hex
        self.rgb = rgb
        self.timestamp = timestamp
    }
}

/// Observable store for managing color history with 8-hour retention
@MainActor
final class ColorStore: ObservableObject {
    @Published private(set) var history: [Swatch] = []

    private let key = "com.mohebanwari.ColorPicker.history.v1"
    private let retentionHours: Double = 8
    private var cleanupTimer: Timer?

    init() {
        load()
        purgeOlderThan(hours: retentionHours)
        setupCleanupTimer()
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    /// Adds a color to the history, converts to hex, and copies to clipboard
    func add(_ color: NSColor) {
        // Convert to sRGB color space
        guard let rgb = color.usingColorSpace(.sRGB) else { return }

        // Convert to 0-255 RGB values
        let red = Int(round(rgb.redComponent * 255))
        let green = Int(round(rgb.greenComponent * 255))
        let blue = Int(round(rgb.blueComponent * 255))

        // Format as #RRGGBB uppercase
        let hex = String(format: "#%02X%02X%02X", red, green, blue)

        // Create swatch and add to history (newest first)
        let swatch = Swatch(
            hex: hex,
            rgb: Swatch.RGB(red: red, green: green, blue: blue),
            timestamp: Date()
        )

        history.insert(swatch, at: 0)

        // Purge old entries
        purgeOlderThan(hours: retentionHours)

        // Cap history at 200 entries for performance
        if history.count > 200 {
            history = Array(history.prefix(200))
        }

        // Persist to UserDefaults
        persist()

        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hex, forType: .string)
    }

    /// Removes swatches older than the specified number of hours
    func purgeOlderThan(hours: Double) {
        let cutoff = Date().addingTimeInterval(-hours * 3600)
        history.removeAll { $0.timestamp < cutoff }
    }

    /// Clears all color history
    func clearHistory() {
        history.removeAll()
        persist()
    }

    /// Launches the system color picker (NSColorSampler) and adds the selected color to history
    func pickColor() {
        NSColorSampler().show { [weak self] color in
            guard let self = self, let color = color else { return }
            Task { @MainActor in
                self.add(color)
            }
        }
    }

    // MARK: - Persistence

    /// Loads history from UserDefaults
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }

        do {
            let decoder = JSONDecoder()
            history = try decoder.decode([Swatch].self, from: data)
        } catch {
            print("Failed to load color history: \(error)")
            history = []
        }
    }

    /// Persists history to UserDefaults
    private func persist() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(history)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to persist color history: \(error)")
        }
    }

    // MARK: - Cleanup Timer

    /// Sets up a timer to purge old entries every 15 minutes
    private func setupCleanupTimer() {
        // Run cleanup every 15 minutes (900 seconds)
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.purgeOlderThan(hours: self.retentionHours)
                if !self.history.isEmpty {
                    self.persist()
                }
            }
        }
    }
}

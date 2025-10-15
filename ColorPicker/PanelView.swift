//
//  PanelView.swift
//  ColorPicker
//
//  Created by Moheb Anwari on 15.10.25.
//

import SwiftUI

/// Main panel view for the menu bar extra
///
/// LIQUID GLASS IMPLEMENTATION (Milestone 9):
/// - Uses MenuBarExtra.window style for system-provided glass background
/// - Button glass effects use .glassEffect() modifier (macOS 26+)
/// - Accessibility: Respects reduced transparency and increased contrast
/// - Foreground styling provides contrast per HIG materials guidance
struct PanelView: View {
    @EnvironmentObject var store: ColorStore
    @State private var copiedId: UUID?

    // Accessibility environment values
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityInvertColors) var invertColors

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Tint")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Action buttons
            VStack(spacing: 8) {
                // Pick Color button (solid blue with optional glass effect, white text)
                Button(action: pickColor) {
                    Text("Pick Color")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                        // Apply glass effect only if transparency is not reduced
                        .conditionalGlassEffect(enabled: !reduceTransparency)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            // History list only (no empty state)
            if !store.history.isEmpty {
                historyList
            }
        }
        .frame(width: 200)
        .frame(maxHeight: store.history.isEmpty ? nil : 500)
        .fixedSize(horizontal: false, vertical: store.history.isEmpty)
    }

    // MARK: - History List

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(store.history) { swatch in
                    ColorRow(
                        swatch: swatch,
                        isCopied: copiedId == swatch.id,
                        onCopy: {
                            copyToClipboard(swatch)
                        }
                    )
                    .transition(.opacity)
                }
            }
            .padding(.vertical, 8)
        }
        .mask {
            VStack(spacing: 0) {
                // Progressive fade for content scrolling behind header
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)

                // Rest of content fully visible
                Rectangle()
                    .fill(.black)
            }
        }
    }

    // MARK: - Actions

    private func pickColor() {
        NSColorSampler().show { color in
            guard let selectedColor = color else { return }
            Task { @MainActor in
                store.add(selectedColor)
            }
        }
    }

    private func copyToClipboard(_ swatch: Swatch) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(swatch.hex, forType: .string)

        // Show copied feedback with smooth easing
        withAnimation(.easeInOut(duration: 0.3)) {
            copiedId = swatch.id
        }

        // Reset after 2 seconds with smooth easing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                copiedId = nil
            }
        }
    }
}

// MARK: - Color Row

struct ColorRow: View {
    let swatch: Swatch
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 10) {
                // Circular color preview with white stroke (smaller)
                Circle()
                    .fill(color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )

                // Hex label in SF Mono
                Text(swatch.hex)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.primary)

                Spacer()

                // "Copied" indicator
                if isCopied {
                    Text("Copied")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(nsColor: .separatorColor))
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            )
                        )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Color.primary.opacity(0.0001)
        )
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var color: Color {
        Color(
            red: Double(swatch.rgb.red) / 255.0,
            green: Double(swatch.rgb.green) / 255.0,
            blue: Double(swatch.rgb.blue) / 255.0
        )
    }
}

// MARK: - Accessibility Helpers

/// View extension to conditionally apply glass effect based on accessibility settings
extension View {
    /// Conditionally applies glass effect if enabled (respects reduced transparency)
    @ViewBuilder
    func conditionalGlassEffect(enabled: Bool) -> some View {
        if enabled {
            self.glassEffect(.regular, in: Capsule())
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview("Panel with History") {
    @Previewable @StateObject var store = ColorStore()

    PanelView()
        .environmentObject(store)
        .frame(width: 200, height: 400)
}

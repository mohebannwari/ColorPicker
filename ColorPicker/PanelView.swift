//
//  PanelView.swift
//  ColorPicker
//
//  Created by Moheb Anwari on 15.10.25.
//

import SwiftUI

/// Main panel view for the menu bar extra
struct PanelView: View {
    @EnvironmentObject var store: ColorStore
    @State private var copiedId: UUID?

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
                // Pick Color button (solid blue with liquid glass effect, white text)
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
                        .glassEffect(.regular, in: Capsule())
                }
                .buttonStyle(.plain)

                // Clear History button (liquid glass, white text) - only show when history exists
                if !store.history.isEmpty {
                    Button(action: {
                        withAnimation {
                            store.clearHistory()
                        }
                    }) {
                        Text("Clear History")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .glassEffect(.regular, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
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
            LazyVStack(spacing: 0) {
                ForEach(Array(store.history.enumerated()), id: \.element.id) { index, swatch in
                    VStack(spacing: 0) {
                        ColorRow(
                            swatch: swatch,
                            isCopied: copiedId == swatch.id,
                            onCopy: {
                                copyToClipboard(swatch)
                            }
                        )

                        if index < store.history.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(.vertical, 8)
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

        // Show copied feedback
        withAnimation {
            copiedId = swatch.id
        }

        // Reset after 300ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
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

                // Copy button or checkmark
                if isCopied {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
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

// MARK: - Preview

#Preview {
    PanelView()
        .environmentObject({
            let store = ColorStore()
            // Add some sample colors for preview
            return store
        }())
        .frame(width: 200, height: 400)
}

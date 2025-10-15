//
//  GlassBackground.swift
//  ColorPicker
//
//  Created by Moheb Anwari on 15.10.25.
//

import SwiftUI
import AppKit

/// A SwiftUI wrapper for NSVisualEffectView that provides a glass/blur background effect.
/// Automatically respects accessibility settings like "Reduce Transparency".
struct GlassBackground: NSViewRepresentable {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        // Use hudWindow material for a glass-like effect
        // This is the fallback for macOS < 26; macOS 26+ will use NSGlassEffectView if available
        view.material = .hudWindow
        view.state = .active
        view.blendingMode = .behindWindow

        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        // Respect accessibility: swap to opaque background when transparency is reduced
        if reduceTransparency {
            view.material = .titlebar
            view.state = .active
        } else {
            view.material = .hudWindow
            view.state = .active
        }
    }
}

// Preview helper
#Preview {
    ZStack {
        // Simulated wallpaper background
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Glass Effect Test")
                .font(.title)
            Text("This should have a glass/blur background")
                .font(.caption)
        }
        .padding(40)
        .background(GlassBackground())
        .cornerRadius(16)
        .frame(width: 320)
    }
}

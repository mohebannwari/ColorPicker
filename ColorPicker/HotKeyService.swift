//
//  HotKeyService.swift
//  ColorPicker
//
//  Created by Moheb Anwari on 15.10.25.
//

import Carbon
import AppKit

/// Service for registering and handling global hotkeys using Carbon API
///
/// DEPRECATION NOTE:
/// This service uses Carbon's RegisterEventHotKey API, which is technically deprecated
/// but remains the canonical system method for global shortcuts. Apple has not shipped
/// a modern AppKit/SwiftUI replacement as of macOS 26.
///
/// This implementation is isolated in a single file to facilitate drop-in replacement
/// when Apple provides a modern alternative.
///
/// References:
/// - Carbon API: https://cocoadev.github.io/RegisterEventHotKey/
/// - Deprecation discussion: https://github.com/keepassxreboot/keepassxc/issues/3310
@MainActor
final class HotKeyService {
    // MARK: - Properties

    /// Reference to the registered hotkey (needed for unregistration)
    private var hotKeyRef: EventHotKeyRef?

    /// Event handler reference
    private var eventHandler: EventHandlerRef?

    /// Callback to invoke when hotkey is pressed
    private var onHotKeyPressed: (() -> Void)?

    // MARK: - Configuration

    /// Default hotkey configuration: ⇧⌘C (Shift+Command+C)
    private struct HotKeyConfig {
        static let keyCode: UInt32 = UInt32(kVK_ANSI_C)
        static let modifiers: UInt32 = UInt32(cmdKey | shiftKey)

        // Unique identifier for our hotkey
        static let signature: OSType = {
            // Convert "TiNT" string to OSType (4-character code)
            let str = "TiNT" as NSString
            return OSType(str.utf8String![0]) << 24 |
                   OSType(str.utf8String![1]) << 16 |
                   OSType(str.utf8String![2]) << 8 |
                   OSType(str.utf8String![3])
        }()
        static let id: UInt32 = 1
    }

    // MARK: - Registration

    /// Registers the global hotkey (⇧⌘T) and sets up the event handler
    /// - Parameter callback: Closure to call when the hotkey is pressed
    func register(onPressed callback: @escaping () -> Void) {
        self.onHotKeyPressed = callback

        // Create event type specification for hotkey events
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Install event handler
        // Note: Using withUnsafeMutablePointer to pass 'self' as user data
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                // Extract self from user data
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()

                // Call the callback on main thread
                Task { @MainActor in
                    service.onHotKeyPressed?()
                }

                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        // Create hotkey ID
        let hotKeyID = EventHotKeyID(
            signature: HotKeyConfig.signature,
            id: HotKeyConfig.id
        )

        // Register the hotkey
        let status = RegisterEventHotKey(
            HotKeyConfig.keyCode,
            HotKeyConfig.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("Warning: Failed to register global hotkey ⇧⌘C (status: \(status))")
            print("The hotkey may conflict with another application or system shortcut.")
        } else {
            print("Global hotkey ⇧⌘C registered successfully")
        }
    }

    // MARK: - Cleanup

    /// Unregisters the hotkey and removes the event handler
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        onHotKeyPressed = nil
    }

    nonisolated deinit {
        // Clean up hotkey registration
        // Note: We can't call @MainActor methods from deinit, so we do cleanup directly
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}

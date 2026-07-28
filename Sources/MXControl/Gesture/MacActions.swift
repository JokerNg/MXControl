import CoreGraphics
import AppKit
import os

/// macOS system actions triggered by gesture recognition.
///
/// Uses CGEvent keyboard shortcuts for all actions (Ctrl+Fn+Arrow).
/// This is the same approach BetterMouse uses via SkyLight SymbolicHotKey.
///
/// Key requirements (discovered through testing + RE):
///   - Event source: `.privateState` (isolated from real keyboard state)
///   - Modifier flags: `0x840000` (Control + SecondaryFn — arrow keys need Fn)
///   - Event tap: `.cghidEventTap` (injects at HID level)
///
/// Requires Accessibility permission.
enum MacActions {

    // MARK: - Workspace Switch Cooldown

    /// macOS ignores keyboard shortcuts during workspace switch animation (~750-1000ms).
    /// Track the last switch time so we can delay Mission Control until animation completes.
    nonisolated(unsafe) private static var lastWorkspaceSwitchTime: Date = .distantPast

    // MARK: - Actions

    /// Trigger Mission Control (Ctrl+Fn+UpArrow, SymbolicHotKey ID 32).
    static func missionControl() {
        postWithCooldown(keyCode: 0x7E, label: "Mission Control")  // kVK_UpArrow
    }

    /// Trigger App Exposé (Ctrl+Fn+DownArrow, SymbolicHotKey ID 33).
    /// Shows all windows of the frontmost application.
    static func appExpose() {
        postWithCooldown(keyCode: 0x7D, label: "App Exposé")  // kVK_DownArrow
    }

    /// Switch to the workspace on the LEFT (Ctrl+Fn+LeftArrow, SymbolicHotKey ID 79).
    static func workspaceLeft() {
        lastWorkspaceSwitchTime = Date()
        postKeyboardShortcut(keyCode: 0x7B)  // kVK_LeftArrow
        debugLog("[MacActions] Workspace Left triggered")
    }

    /// Switch to the workspace on the RIGHT (Ctrl+Fn+RightArrow, SymbolicHotKey ID 81).
    static func workspaceRight() {
        lastWorkspaceSwitchTime = Date()
        postKeyboardShortcut(keyCode: 0x7C)  // kVK_RightArrow
        debugLog("[MacActions] Workspace Right triggered")
    }

    /// Navigate back in the frontmost app using Cmd+[.
    static func navigateBack() {
        postCommandShortcut(keyCode: 0x21, label: "Back")  // kVK_ANSI_LeftBracket
    }

    /// Navigate forward in the frontmost app using Cmd+].
    static func navigateForward() {
        postCommandShortcut(keyCode: 0x1E, label: "Forward")  // kVK_ANSI_RightBracket
    }

    /// Post a middle mouse click at the current pointer location.
    static func middleClick() {
        guard AXIsProcessTrusted() else {
            debugLog("[MacActions] ERROR: Not trusted for accessibility")
            return
        }

        guard let source = CGEventSource(stateID: .privateState),
              let location = CGEvent(source: nil)?.location,
              let mouseDown = CGEvent(
                  mouseEventSource: source,
                  mouseType: .otherMouseDown,
                  mouseCursorPosition: location,
                  mouseButton: .center
              ),
              let mouseUp = CGEvent(
                  mouseEventSource: source,
                  mouseType: .otherMouseUp,
                  mouseCursorPosition: location,
                  mouseButton: .center
              )
        else {
            debugLog("[MacActions] ERROR: Failed to create middle-click events")
            return
        }

        mouseDown.post(tap: .cghidEventTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) {
            mouseUp.post(tap: .cghidEventTap)
        }
    }

    /// Trigger Show Desktop using the default Fn+F11 shortcut.
    static func showDesktop() {
        postShortcut(
            keyCode: 0x67,  // kVK_F11
            flags: CGEventFlags(rawValue: 0x800000),
            label: "Show Desktop"
        )
    }

    static func switchApplication() {
        postCommandShortcut(keyCode: 0x30, label: "Switch Application")  // kVK_Tab
    }

    static func closeWindow() {
        postCommandShortcut(keyCode: 0x0D, label: "Close Window")  // kVK_ANSI_W
    }

    static func copy() {
        postCommandShortcut(keyCode: 0x08, label: "Copy")  // kVK_ANSI_C
    }

    static func paste() {
        postCommandShortcut(keyCode: 0x09, label: "Paste")  // kVK_ANSI_V
    }

    static func playPause() {
        postMediaKey(16, label: "Play/Pause")  // NX_KEYTYPE_PLAY
    }

    static func mute() {
        postMediaKey(7, label: "Mute")  // NX_KEYTYPE_MUTE
    }

    static func volumeDown() {
        postMediaKey(1, label: "Volume Down")  // NX_KEYTYPE_SOUND_DOWN
    }

    static func volumeUp() {
        postMediaKey(0, label: "Volume Up")  // NX_KEYTYPE_SOUND_UP
    }

    // MARK: - Cooldown Helper

    /// Post a keyboard shortcut, respecting the workspace switch cooldown.
    /// If called within 1.5s of a workspace switch, delays until animation finishes.
    private static func postWithCooldown(keyCode: CGKeyCode, label: String) {
        let elapsed = Date().timeIntervalSince(lastWorkspaceSwitchTime)
        if elapsed < 1.5 {
            let delay = 1.5 - elapsed
            debugLog("[MacActions] \(label) delayed \(String(format: "%.0f", delay * 1000))ms (workspace cooldown)")
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + delay) {
                postKeyboardShortcut(keyCode: keyCode)
                debugLog("[MacActions] \(label) triggered (after cooldown)")
            }
        } else {
            postKeyboardShortcut(keyCode: keyCode)
            debugLog("[MacActions] \(label) triggered")
        }
    }

    // MARK: - CGEvent Keyboard Shortcut

    /// 0x040000 = kCGEventFlagMaskControl
    /// 0x800000 = kCGEventFlagMaskSecondaryFn (arrow keys are fn keys)
    private static let arrowModifiers = CGEventFlags(rawValue: 0x840000)
    private static let commandModifier = CGEventFlags.maskCommand

    private static func postKeyboardShortcut(keyCode: CGKeyCode) {
        guard AXIsProcessTrusted() else {
            debugLog("[MacActions] ERROR: Not trusted for accessibility")
            return
        }

        guard let source = CGEventSource(stateID: .privateState) else {
            debugLog("[MacActions] ERROR: Failed to create CGEventSource")
            return
        }

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else {
            debugLog("[MacActions] ERROR: Failed to create CGEvent for keyCode 0x\(String(format: "%02X", keyCode))")
            return
        }

        keyDown.flags = arrowModifiers
        keyUp.flags = arrowModifiers

        keyDown.post(tap: .cghidEventTap)
        usleep(20_000)  // 20ms gap
        keyUp.post(tap: .cghidEventTap)
    }

    private static func postCommandShortcut(keyCode: CGKeyCode, label: String) {
        postShortcut(keyCode: keyCode, flags: commandModifier, label: label)
    }

    private static func postShortcut(
        keyCode: CGKeyCode,
        flags: CGEventFlags,
        label: String
    ) {
        guard AXIsProcessTrusted() else {
            debugLog("[MacActions] ERROR: Not trusted for accessibility")
            return
        }

        guard let source = CGEventSource(stateID: .privateState) else {
            debugLog("[MacActions] ERROR: Failed to create CGEventSource")
            return
        }

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else {
            debugLog("[MacActions] ERROR: Failed to create command event for keyCode 0x\(String(format: "%02X", keyCode))")
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags

        let bundle = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
        debugLog("[MacActions] \(label) triggered (frontmost=\(bundle))")

        keyDown.post(tap: .cghidEventTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) {
            keyUp.post(tap: .cghidEventTap)
        }
    }

    private static func postMediaKey(_ key: Int, label: String) {
        guard AXIsProcessTrusted() else {
            debugLog("[MacActions] ERROR: Not trusted for accessibility")
            return
        }

        let keyDownData = (key << 16) | (0xA << 8)
        let keyUpData = (key << 16) | (0xB << 8)
        let keyDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: keyDownData,
            data2: -1
        )
        let keyUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: keyUpData,
            data2: -1
        )

        guard let downEvent = keyDown?.cgEvent, let upEvent = keyUp?.cgEvent else {
            debugLog("[MacActions] ERROR: Failed to create \(label) media-key events")
            return
        }

        downEvent.post(tap: .cghidEventTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) {
            upEvent.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Accessibility Permission

    static func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    nonisolated(unsafe) private static var hasPromptedAccessibility = false

    @discardableResult
    static func requestAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        debugLog("[MacActions] AXIsProcessTrusted = \(trusted)")
        if trusted { return true }

        guard !hasPromptedAccessibility else {
            debugLog("[MacActions] Skipping duplicate accessibility prompt")
            return false
        }
        hasPromptedAccessibility = true

        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let result = AXIsProcessTrustedWithOptions(options)
        if !result {
            debugLog("[MacActions] Accessibility NOT granted.")
        }
        return result
    }
}

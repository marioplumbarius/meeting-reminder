import AppKit
import Combine
import SwiftUI

@MainActor
final class FocusCountdownWindowController: NSObject, NSWindowDelegate {
    private static let positionKey = "focusCountdownPosition"
    private static let panelSize = NSSize(width: 200, height: 70)

    private var panel: NSPanel?
    private var resetObserver: Any?

    func show(service: FocusCountdownService) {
        guard panel == nil else { return }

        let origin = Self.loadOrigin(for: Self.panelSize)
        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: Self.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.delegate = self

        let view = FocusCountdownView(service: service)
        panel.contentView = NSHostingView(rootView: view)
        panel.orderFrontRegardless()

        self.panel = panel

        resetObserver = NotificationCenter.default.addObserver(
            forName: .focusCountdownResetPosition,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.resetToDefaultPosition() }
        }
    }

    func close() {
        if let panel = panel {
            Self.saveOrigin(panel.frame.origin)
            panel.orderOut(nil)
        }
        panel = nil
        if let resetObserver {
            NotificationCenter.default.removeObserver(resetObserver)
        }
        resetObserver = nil
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        Self.saveOrigin(window.frame.origin)
    }

    private func resetToDefaultPosition() {
        guard let panel else { return }
        UserDefaults.standard.removeObject(forKey: Self.positionKey)
        let origin = Self.defaultOrigin(for: Self.panelSize)
        panel.setFrameOrigin(origin)
    }

    private static func loadOrigin(for size: NSSize) -> NSPoint {
        if let saved = UserDefaults.standard.dictionary(forKey: positionKey) as? [String: Double],
           let x = saved["x"], let y = saved["y"] {
            let point = NSPoint(x: x, y: y)
            if NSScreen.screens.contains(where: { $0.frame.contains(point) }) {
                return point
            }
        }
        return defaultOrigin(for: size)
    }

    private static func defaultOrigin(for size: NSSize) -> NSPoint {
        guard let screen = NSScreen.main else {
            return NSPoint(x: 100, y: 100)
        }
        let frame = screen.visibleFrame
        return NSPoint(x: frame.maxX - size.width - 20, y: frame.minY + 20)
    }

    private static func saveOrigin(_ point: NSPoint) {
        UserDefaults.standard.set(
            ["x": Double(point.x), "y": Double(point.y)],
            forKey: positionKey
        )
    }
}

struct FocusCountdownView: View {
    @ObservedObject var service: FocusCountdownService

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

            if let event = service.nextEvent {
                VStack(spacing: 2) {
                    Text(formatted(service.remaining))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                    Text(event.title)
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                }
            } else {
                VStack(spacing: 2) {
                    Text("No meetings")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Enjoy the focus time")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
    }

    private func formatted(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

import Foundation

// Forced offline for the plugin's HTTP traffic. MapLibre iOS 6.28 exposes no
// switch for this, so while it is on, requests that go through
// SiroHeadersProtocol fail at once with "not connected". That covers the
// style, tiles, sprites and glyphs, which all go through that session.
enum SiroForcedOffline {
    private static let lock = NSLock()
    private static var enabled = false

    static func setEnabled(_ value: Bool) {
        lock.lock()
        enabled = value
        lock.unlock()
    }

    static var isEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return enabled
    }
}

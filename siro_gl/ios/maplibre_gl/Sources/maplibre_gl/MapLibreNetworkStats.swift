import Foundation

// Counts the HTTP(S) requests MapLibre starts through the session configuration
// that carries MapLibreHeadersProtocol. Counting is off until
// setNetworkStatsEnabled(true) is called, so apps that never ask pay nothing
// beyond one lock and a flag check per request.
//
// Only requests are counted on iOS. Response bytes are not, because the
// protocol only sees a response's bytes when it intercepts the request, and it
// intercepts only when custom headers are set.
enum MapLibreNetworkStats {
    private static let lock = NSLock()
    private static var enabled = false
    private static var requestCount = 0

    static func setEnabled(_ value: Bool) {
        lock.lock()
        enabled = value
        lock.unlock()
    }

    static func reset() {
        lock.lock()
        requestCount = 0
        lock.unlock()
    }

    static func recordRequest() {
        lock.lock()
        if enabled {
            requestCount += 1
        }
        lock.unlock()
    }

    static func snapshot() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return requestCount
    }
}

import CoreLocation
import UIKit

/// An ordered list of coordinates, as Google's `GMSPath`.
public class GMSPath: NSObject {

    internal var coordinates: [CLLocationCoordinate2D]

    public override init() {
        coordinates = []
        super.init()
    }

    public init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        super.init()
    }

    /// A path from a Google encoded polyline (precision 5), or nil if the string is not valid.
    public convenience init?(fromEncodedPath encoded: String) {
        guard let coordinates = GMSPath.decode(encoded) else { return nil }
        self.init(coordinates: coordinates)
    }

    public class func path(fromEncodedPath encoded: String) -> GMSPath? {
        GMSPath(fromEncodedPath: encoded)
    }

    /// The path as a Google encoded polyline (precision 5).
    public func encodedPath() -> String {
        var result = ""
        var lastLat = 0, lastLng = 0
        func write(_ value: Int) {
            var v = value < 0 ? ~(value << 1) : value << 1
            while v >= 0x20 {
                result.append(Character(UnicodeScalar((0x20 | (v & 0x1f)) + 63)!))
                v >>= 5
            }
            result.append(Character(UnicodeScalar(v + 63)!))
        }
        for coordinate in coordinates {
            let lat = Int((coordinate.latitude * 1e5).rounded())
            let lng = Int((coordinate.longitude * 1e5).rounded())
            write(lat - lastLat)
            write(lng - lastLng)
            lastLat = lat
            lastLng = lng
        }
        return result
    }

    private static func decode(_ encoded: String) -> [CLLocationCoordinate2D]? {
        let bytes = Array(encoded.utf8)
        var index = 0, lat = 0, lng = 0
        var out: [CLLocationCoordinate2D] = []
        func next() -> Int? {
            var result = 0, shift = 0
            while index < bytes.count {
                let b = Int(bytes[index]) - 63
                index += 1
                guard b >= 0 else { return nil }
                result |= (b & 0x1f) << shift
                shift += 5
                if b < 0x20 { return (result & 1) != 0 ? ~(result >> 1) : result >> 1 }
            }
            return nil
        }
        while index < bytes.count {
            guard let dLat = next(), let dLng = next() else { return nil }
            lat += dLat
            lng += dLng
            out.append(CLLocationCoordinate2D(latitude: Double(lat) / 1e5, longitude: Double(lng) / 1e5))
        }
        return out
    }

    /// The number of coordinates in the path.
    public func count() -> UInt {
        UInt(coordinates.count)
    }

    public func coordinate(at index: UInt) -> CLLocationCoordinate2D {
        coordinates[Int(index)]
    }
}

/// A path that can be changed, as Google's `GMSMutablePath`.
public final class GMSMutablePath: GMSPath {

    public func add(_ coordinate: CLLocationCoordinate2D) {
        coordinates.append(coordinate)
    }

    public func addLatitude(_ latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        coordinates.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }

    public func removeLastCoordinate() {
        if !coordinates.isEmpty { coordinates.removeLast() }
    }

    public func removeCoordinate(at index: UInt) {
        coordinates.remove(at: Int(index))
    }

    public func replaceCoordinate(at index: UInt, with coordinate: CLLocationCoordinate2D) {
        coordinates[Int(index)] = coordinate
    }

    public func removeAllCoordinates() {
        coordinates.removeAll()
    }
}

/// A rectangle of the map between two corners, as Google's `GMSCoordinateBounds`.
public class GMSCoordinateBounds: NSObject {

    public private(set) var southWest: CLLocationCoordinate2D
    public private(set) var northEast: CLLocationCoordinate2D

    public init(coordinate first: CLLocationCoordinate2D, coordinate second: CLLocationCoordinate2D) {
        southWest = CLLocationCoordinate2D(
            latitude: min(first.latitude, second.latitude),
            longitude: min(first.longitude, second.longitude)
        )
        northEast = CLLocationCoordinate2D(
            latitude: max(first.latitude, second.latitude),
            longitude: max(first.longitude, second.longitude)
        )
        super.init()
    }

    public convenience init(path: GMSPath) {
        self.init(coordinates: path.coordinates)
    }

    public convenience init(coordinates: [CLLocationCoordinate2D]) {
        guard let first = coordinates.first else {
            self.init(
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            )
            return
        }
        self.init(coordinate: first, coordinate: first)
        for coordinate in coordinates.dropFirst() {
            southWest = CLLocationCoordinate2D(
                latitude: min(southWest.latitude, coordinate.latitude),
                longitude: min(southWest.longitude, coordinate.longitude)
            )
            northEast = CLLocationCoordinate2D(
                latitude: max(northEast.latitude, coordinate.latitude),
                longitude: max(northEast.longitude, coordinate.longitude)
            )
        }
    }

    public func includingCoordinate(_ coordinate: CLLocationCoordinate2D) -> GMSCoordinateBounds {
        GMSCoordinateBounds(coordinates: [southWest, northEast, coordinate])
    }

    public func includingPath(_ path: GMSPath) -> GMSCoordinateBounds {
        GMSCoordinateBounds(coordinates: [southWest, northEast] + path.coordinates)
    }

    /// Whether the two rectangles share any area.
    public func intersects(_ other: GMSCoordinateBounds) -> Bool {
        southWest.latitude <= other.northEast.latitude && northEast.latitude >= other.southWest.latitude
            && southWest.longitude <= other.northEast.longitude && northEast.longitude >= other.southWest.longitude
    }

    public func includingBounds(_ other: GMSCoordinateBounds) -> GMSCoordinateBounds {
        GMSCoordinateBounds(coordinates: [southWest, northEast, other.southWest, other.northEast])
    }

    public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude >= southWest.latitude && coordinate.latitude <= northEast.latitude
            && coordinate.longitude >= southWest.longitude && coordinate.longitude <= northEast.longitude
    }

    /// Google's `valid`: both corners are set to real coordinates.
    public var isValid: Bool {
        CLLocationCoordinate2DIsValid(southWest) && CLLocationCoordinate2DIsValid(northEast)
    }

    public var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (southWest.latitude + northEast.latitude) / 2,
            longitude: (southWest.longitude + northEast.longitude) / 2
        )
    }
}

// MARK: - Geodesic shapes, in metres on a sphere of Earth's radius.

private let earthRadius: Double = 6_371_000

/// The coordinate `distance` metres from `origin` along `bearing` (radians).
private func destination(from origin: CLLocationCoordinate2D, distance: Double, bearing: Double) -> CLLocationCoordinate2D {
    let delta = distance / earthRadius
    let phi1 = origin.latitude * .pi / 180
    let lambda1 = origin.longitude * .pi / 180
    let phi2 = asin(sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(bearing))
    let lambda2 = lambda1 + atan2(sin(bearing) * sin(delta) * cos(phi1), cos(delta) - sin(phi1) * sin(phi2))
    return CLLocationCoordinate2D(latitude: phi2 * 180 / .pi, longitude: lambda2 * 180 / .pi)
}

/// The angle between two coordinates, in radians.
private func angularDistance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    let phi1 = a.latitude * .pi / 180
    let phi2 = b.latitude * .pi / 180
    let dPhi = phi2 - phi1
    let dLambda = (b.longitude - a.longitude) * .pi / 180
    let h = sin(dPhi / 2) * sin(dPhi / 2) + cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2)
    return 2 * asin(min(1, sqrt(h)))
}

/// A circle of `radius` metres around `center`, as a ring of `points` coordinates.
internal func geodesicCircle(center: CLLocationCoordinate2D, radius: Double, points: Int = 64) -> [CLLocationCoordinate2D] {
    (0..<points).map { index in
        destination(from: center, distance: radius, bearing: 2 * .pi * Double(index) / Double(points))
    }
}

/// Splits each segment of `path` into great-circle pieces no longer than `stepMeters`.
internal func geodesicLine(_ path: [CLLocationCoordinate2D], stepMeters: Double = 50_000) -> [CLLocationCoordinate2D] {
    guard path.count > 1 else { return path }
    var out: [CLLocationCoordinate2D] = [path[0]]
    for index in 0..<(path.count - 1) {
        let a = path[index]
        let b = path[index + 1]
        let angle = angularDistance(a, b)
        let steps = max(1, Int(ceil(angle * earthRadius / stepMeters)))
        if angle > 0 {
            for step in 1...steps {
                out.append(greatCircleInterpolate(a, b, fraction: Double(step) / Double(steps), angle: angle))
            }
        } else {
            out.append(b)
        }
    }
    return out
}

/// Interpolates along the great circle from `a` to `b` (spherical linear interpolation).
private func greatCircleInterpolate(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, fraction: Double, angle: Double) -> CLLocationCoordinate2D {
    let wa = sin((1 - fraction) * angle) / sin(angle)
    let wb = sin(fraction * angle) / sin(angle)
    let pa = (a.latitude * .pi / 180, a.longitude * .pi / 180)
    let pb = (b.latitude * .pi / 180, b.longitude * .pi / 180)
    let x = wa * cos(pa.0) * cos(pa.1) + wb * cos(pb.0) * cos(pb.1)
    let y = wa * cos(pa.0) * sin(pa.1) + wb * cos(pb.0) * sin(pb.1)
    let z = wa * sin(pa.0) + wb * sin(pb.0)
    return CLLocationCoordinate2D(
        latitude: atan2(z, sqrt(x * x + y * y)) * 180 / .pi,
        longitude: atan2(y, x) * 180 / .pi
    )
}

/// The CSS colour the renderer writes into feature attributes, e.g. `rgba(255, 0, 0, 0.5)`.
internal func cssColor(_ color: UIColor) -> String {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return String(format: "rgba(%d, %d, %d, %.3f)", Int(red * 255), Int(green * 255), Int(blue * 255), alpha)
}

import CoreLocation
import Foundation

/// Google's `GMSServices`. Siro's styles need no key, so these exist for code that calls them at launch.
public final class GMSServices: NSObject {

    /// Accepted and ignored: Siro needs no API key. Returns true, as Google's does for a valid key.
    @discardableResult
    public class func provideAPIKey(_ key: String) -> Bool {
        true
    }

    public class func sdkVersion() -> String {
        "Siro Maps 1.0"
    }

    public class func openSourceLicenseInfo() -> String {
        "Siro Maps is built on MapLibre Native (BSD 2-Clause) and OpenStreetMap data (ODbL)."
    }
}

// MARK: - Geometry utilities, with Google's names. Distances are in metres on a sphere of Earth's radius.

private let earthRadiusMeters: Double = 6_371_009

private func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
private func degrees(_ radians: Double) -> Double { radians * 180 / .pi }

/// The distance in metres between two coordinates.
public func GMSGeometryDistance(_ from: CLLocationCoordinate2D, _ to: CLLocationCoordinate2D) -> CLLocationDistance {
    let phi1 = radians(from.latitude), phi2 = radians(to.latitude)
    let dPhi = phi2 - phi1
    let dLambda = radians(to.longitude - from.longitude)
    let h = sin(dPhi / 2) * sin(dPhi / 2) + cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2)
    return 2 * earthRadiusMeters * asin(min(1, sqrt(h)))
}

/// The length in metres of a path.
public func GMSGeometryLength(_ path: GMSPath) -> CLLocationDistance {
    var total: CLLocationDistance = 0
    let points = path.coordinates
    guard points.count > 1 else { return 0 }
    for index in 1..<points.count {
        total += GMSGeometryDistance(points[index - 1], points[index])
    }
    return total
}

/// The heading in degrees, 0 to 360, from one coordinate to another.
public func GMSGeometryHeading(_ from: CLLocationCoordinate2D, _ to: CLLocationCoordinate2D) -> CLLocationDirection {
    let phi1 = radians(from.latitude), phi2 = radians(to.latitude)
    let dLambda = radians(to.longitude - from.longitude)
    let y = sin(dLambda) * cos(phi2)
    let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda)
    return (degrees(atan2(y, x)) + 360).truncatingRemainder(dividingBy: 360)
}

/// The coordinate `distance` metres from `from`, along `heading` degrees.
public func GMSGeometryOffset(_ from: CLLocationCoordinate2D, _ distance: CLLocationDistance, _ heading: CLLocationDirection) -> CLLocationCoordinate2D {
    let delta = distance / earthRadiusMeters
    let theta = radians(heading)
    let phi1 = radians(from.latitude), lambda1 = radians(from.longitude)
    let phi2 = asin(sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(theta))
    let lambda2 = lambda1 + atan2(sin(theta) * sin(delta) * cos(phi1), cos(delta) - sin(phi1) * sin(phi2))
    return CLLocationCoordinate2D(latitude: degrees(phi2), longitude: degrees(lambda2))
}

/// The coordinate `fraction` of the way along the great circle from `from` to `to`.
public func GMSGeometryInterpolate(_ from: CLLocationCoordinate2D, _ to: CLLocationCoordinate2D, _ fraction: Double) -> CLLocationCoordinate2D {
    let phi1 = radians(from.latitude), lambda1 = radians(from.longitude)
    let phi2 = radians(to.latitude), lambda2 = radians(to.longitude)
    let angle = GMSGeometryDistance(from, to) / earthRadiusMeters
    guard angle > 0 else { return from }
    let a = sin((1 - fraction) * angle) / sin(angle)
    let b = sin(fraction * angle) / sin(angle)
    let x = a * cos(phi1) * cos(lambda1) + b * cos(phi2) * cos(lambda2)
    let y = a * cos(phi1) * sin(lambda1) + b * cos(phi2) * sin(lambda2)
    let z = a * sin(phi1) + b * sin(phi2)
    return CLLocationCoordinate2D(latitude: degrees(atan2(z, sqrt(x * x + y * y))), longitude: degrees(atan2(y, x)))
}

/// The signed area in square metres enclosed by a path on the sphere. Positive for a counterclockwise ring.
public func GMSGeometrySignedArea(_ path: GMSPath) -> Double {
    let points = path.coordinates
    guard points.count > 2 else { return 0 }
    var total = 0.0
    for index in 0..<points.count {
        let p1 = points[index]
        let p2 = points[(index + 1) % points.count]
        total += radians(p2.longitude - p1.longitude) * (2 + sin(radians(p1.latitude)) + sin(radians(p2.latitude)))
    }
    return total * earthRadiusMeters * earthRadiusMeters / 2
}

/// The area in square metres enclosed by a path on the sphere.
public func GMSGeometryArea(_ path: GMSPath) -> Double {
    abs(GMSGeometrySignedArea(path))
}

/// Whether `point` is inside the closed `path`. With `geodesic` the edges are great circles; otherwise straight on the map.
public func GMSGeometryContainsLocation(_ point: CLLocationCoordinate2D, _ path: GMSPath, _ geodesic: Bool) -> Bool {
    let ring = geodesic ? geodesicLine(path.coordinates + [path.coordinates.first].compactMap { $0 }) : path.coordinates
    guard ring.count > 2 else { return false }
    // Even-odd rule on longitude and latitude.
    var inside = false
    var j = ring.count - 1
    for i in 0..<ring.count {
        let a = ring[i], b = ring[j]
        if (a.latitude > point.latitude) != (b.latitude > point.latitude),
           point.longitude < (b.longitude - a.longitude) * (point.latitude - a.latitude) / (b.latitude - a.latitude) + a.longitude {
            inside.toggle()
        }
        j = i
    }
    return inside
}

/// Whether `point` is within `tolerance` metres of `path`.
public func GMSGeometryIsLocationOnPathTolerance(_ point: CLLocationCoordinate2D, _ path: GMSPath, _ geodesic: Bool, _ tolerance: CLLocationDistance) -> Bool {
    let points = geodesic ? geodesicLine(path.coordinates, stepMeters: 10_000) : path.coordinates
    guard points.count > 1 else { return points.first.map { GMSGeometryDistance(point, $0) <= tolerance } ?? false }
    for index in 1..<points.count {
        if distanceToSegment(point, points[index - 1], points[index]) <= tolerance { return true }
    }
    return false
}

/// Whether `point` is on `path`, within 0.1 metres.
public func GMSGeometryIsLocationOnPath(_ point: CLLocationCoordinate2D, _ path: GMSPath, _ geodesic: Bool) -> Bool {
    GMSGeometryIsLocationOnPathTolerance(point, path, geodesic, 0.1)
}

/// The distance in metres from `point` to the segment `a`-`b`, on a local flat projection.
private func distanceToSegment(_ point: CLLocationCoordinate2D, _ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    let metersPerDegreeLat = earthRadiusMeters * .pi / 180
    let metersPerDegreeLng = metersPerDegreeLat * cos(radians(point.latitude))
    let ax = (a.longitude - point.longitude) * metersPerDegreeLng, ay = (a.latitude - point.latitude) * metersPerDegreeLat
    let bx = (b.longitude - point.longitude) * metersPerDegreeLng, by = (b.latitude - point.latitude) * metersPerDegreeLat
    let dx = bx - ax, dy = by - ay
    let lengthSquared = dx * dx + dy * dy
    let t = lengthSquared == 0 ? 0 : max(0, min(1, -(ax * dx + ay * dy) / lengthSquared))
    return hypot(ax + t * dx, ay + t * dy)
}

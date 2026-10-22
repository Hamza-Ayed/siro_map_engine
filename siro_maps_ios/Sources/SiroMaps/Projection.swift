import CoreLocation
import UIKit

/// The part of the map on screen, as Google's `GMSVisibleRegion`: four corners.
public struct GMSVisibleRegion {
    public var nearLeft: CLLocationCoordinate2D
    public var nearRight: CLLocationCoordinate2D
    public var farLeft: CLLocationCoordinate2D
    public var farRight: CLLocationCoordinate2D
}

/// Converts between screen points and coordinates, as Google's `GMSProjection`.
public final class GMSProjection: NSObject {

    private weak var map: GMSMapView?

    internal init(map: GMSMapView) {
        self.map = map
        super.init()
    }

    /// The point on the map's screen where `coordinate` is.
    public func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        guard let map else { return .zero }
        return map.mlnMapView.convert(coordinate, toPointTo: map)
    }

    /// The coordinate under `point` on the map's screen.
    public func coordinate(for point: CGPoint) -> CLLocationCoordinate2D {
        guard let map else { return CLLocationCoordinate2D(latitude: 0, longitude: 0) }
        return map.mlnMapView.convert(point, toCoordinateFrom: map)
    }

    /// Whether `coordinate` is on the map's screen.
    public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard let map else { return false }
        return map.bounds.contains(point(for: coordinate))
    }

    /// The corners of the part of the map that is on screen.
    public var visibleRegion: GMSVisibleRegion {
        guard let map else {
            let zero = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            return GMSVisibleRegion(nearLeft: zero, nearRight: zero, farLeft: zero, farRight: zero)
        }
        let frame = map.bounds
        return GMSVisibleRegion(
            nearLeft: coordinate(for: CGPoint(x: frame.minX, y: frame.maxY)),
            nearRight: coordinate(for: CGPoint(x: frame.maxX, y: frame.maxY)),
            farLeft: coordinate(for: CGPoint(x: frame.minX, y: frame.minY)),
            farRight: coordinate(for: CGPoint(x: frame.maxX, y: frame.minY))
        )
    }
}

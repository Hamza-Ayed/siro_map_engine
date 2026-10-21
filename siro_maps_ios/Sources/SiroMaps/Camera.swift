import CoreLocation
import UIKit

/// Where the camera looks, as Google's `GMSCameraPosition`.
public class GMSCameraPosition: NSObject {

    public let target: CLLocationCoordinate2D
    public let zoom: Float
    /// The compass heading of the map, in degrees clockwise from north.
    public let bearing: CLLocationDirection
    /// The tilt from straight down, in degrees.
    public let viewingAngle: Double

    public init(target: CLLocationCoordinate2D, zoom: Float, bearing: CLLocationDirection = 0, viewingAngle: Double = 0) {
        self.target = target
        self.zoom = zoom
        self.bearing = bearing
        self.viewingAngle = viewingAngle
        super.init()
    }

    public convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, zoom: Float) {
        self.init(target: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), zoom: zoom)
    }

    public class func camera(withTarget target: CLLocationCoordinate2D, zoom: Float) -> GMSCameraPosition {
        GMSCameraPosition(target: target, zoom: zoom)
    }

    public class func camera(withLatitude latitude: CLLocationDegrees, longitude: CLLocationDegrees, zoom: Float) -> GMSCameraPosition {
        GMSCameraPosition(latitude: latitude, longitude: longitude, zoom: zoom)
    }

    public class func camera(withTarget target: CLLocationCoordinate2D, zoom: Float, bearing: CLLocationDirection, viewingAngle: Double) -> GMSCameraPosition {
        GMSCameraPosition(target: target, zoom: zoom, bearing: bearing, viewingAngle: viewingAngle)
    }
}

/// A change to the camera, as Google's `GMSCameraUpdate`. Build it with the class methods.
///
/// A change is worked out against the camera and the map when it is applied, so a
/// change like `scrollBy` or `fit` uses the map's current size and position.
public class GMSCameraUpdate: NSObject {

    internal let resolve: (GMSCameraPosition, GMSMapView) -> GMSCameraPosition

    internal init(resolve: @escaping (GMSCameraPosition, GMSMapView) -> GMSCameraPosition) {
        self.resolve = resolve
        super.init()
    }

    /// Moves the camera's target to `coordinate`, keeping the zoom.
    public class func setTarget(_ target: CLLocationCoordinate2D) -> GMSCameraUpdate {
        GMSCameraUpdate { camera, _ in
            GMSCameraPosition(target: target, zoom: camera.zoom, bearing: camera.bearing, viewingAngle: camera.viewingAngle)
        }
    }

    public class func setTarget(_ target: CLLocationCoordinate2D, zoom: Float) -> GMSCameraUpdate {
        GMSCameraUpdate { camera, _ in
            GMSCameraPosition(target: target, zoom: zoom, bearing: camera.bearing, viewingAngle: camera.viewingAngle)
        }
    }

    public class func setCamera(_ position: GMSCameraPosition) -> GMSCameraUpdate {
        GMSCameraUpdate { _, _ in position }
    }

    public class func zoomIn() -> GMSCameraUpdate {
        zoomBy(1)
    }

    public class func zoomOut() -> GMSCameraUpdate {
        zoomBy(-1)
    }

    public class func zoomTo(_ zoom: Float) -> GMSCameraUpdate {
        GMSCameraUpdate { camera, _ in
            GMSCameraPosition(target: camera.target, zoom: zoom, bearing: camera.bearing, viewingAngle: camera.viewingAngle)
        }
    }

    /// Changes the zoom by `delta` levels. The focus is currently the centre of the map.
    public class func zoomBy(_ delta: Float) -> GMSCameraUpdate {
        GMSCameraUpdate { camera, _ in
            GMSCameraPosition(target: camera.target, zoom: camera.zoom + delta, bearing: camera.bearing, viewingAngle: camera.viewingAngle)
        }
    }

    /// Changes the zoom by `delta` levels around `point`. The focus is currently the centre of the map.
    public class func zoomBy(_ delta: Float, at point: CGPoint) -> GMSCameraUpdate {
        zoomBy(delta)
    }

    /// Moves the camera by `x` and `y` points on the screen.
    public class func scrollBy(x: CGFloat, y: CGFloat) -> GMSCameraUpdate {
        GMSCameraUpdate { camera, map in
            let centre = CGPoint(x: map.bounds.midX, y: map.bounds.midY)
            let target = map.projection.coordinate(for: CGPoint(x: centre.x + x, y: centre.y + y))
            return GMSCameraPosition(target: target, zoom: camera.zoom, bearing: camera.bearing, viewingAngle: camera.viewingAngle)
        }
    }

    /// Fits `bounds` inside the map, with `padding` points on every side.
    public class func fit(_ bounds: GMSCoordinateBounds, withPadding padding: CGFloat) -> GMSCameraUpdate {
        GMSCameraUpdate { camera, map in
            let width = Double(map.bounds.width - 2 * padding)
            let height = Double(map.bounds.height - 2 * padding)
            return cameraFitting(bounds, width: width, height: height, base: camera)
        }
    }

    /// Fits `bounds` inside an area of `size` points.
    public class func fit(_ bounds: GMSCoordinateBounds, with size: CGSize) -> GMSCameraUpdate {
        GMSCameraUpdate { camera, _ in
            cameraFitting(bounds, width: Double(size.width), height: Double(size.height), base: camera)
        }
    }

    public class func fit(_ bounds: GMSCoordinateBounds) -> GMSCameraUpdate {
        fit(bounds, withPadding: 0)
    }
}

/// The camera that shows `bounds` in a `width` by `height` area, centred on the bounds.
/// Uses the Web Mercator projection, the one the map draws.
private func cameraFitting(_ bounds: GMSCoordinateBounds, width: Double, height: Double, base: GMSCameraPosition) -> GMSCameraPosition {
    let lngSpan = max(bounds.northEast.longitude - bounds.southWest.longitude, 1e-9)
    let zoomX = log2(max(width, 1) * 360 / (256 * lngSpan))
    let ySpan = max(abs(mercatorY(bounds.northEast.latitude) - mercatorY(bounds.southWest.latitude)), 1e-12)
    let zoomY = log2(max(height, 1) * 2 * Double.pi / (256 * ySpan))
    let zoom = min(zoomX, zoomY, 22)
    return GMSCameraPosition(target: bounds.center, zoom: Float(zoom), bearing: base.bearing, viewingAngle: base.viewingAngle)
}

private func mercatorY(_ latitude: Double) -> Double {
    log(tan(Double.pi / 4 + latitude * Double.pi / 360))
}

import CoreLocation
import UIKit

/// The base of everything that sits on the map, as Google's `GMSOverlay`.
///
/// Setting `map` adds the overlay to a map; setting it to nil removes it.
public class GMSOverlay: NSObject {

    public weak var map: GMSMapView? {
        didSet {
            guard oldValue !== map else { return }
            oldValue?.removeOverlay(self)
            map?.addOverlay(self)
        }
    }

    public var zIndex: Int32 = 0 {
        didSet { overlayChanged() }
    }

    /// Whether a tap on the overlay reaches the map's delegate.
    public var isTappable = false {
        didSet { overlayChanged() }
    }

    /// Anything the app wants to keep with the overlay.
    public var userData: Any?

    internal func overlayChanged() {
        map?.overlayDidChange()
    }
}

/// A pin on the map, as Google's `GMSMarker`.
public final class GMSMarker: GMSOverlay {

    public var position = CLLocationCoordinate2D(latitude: 0, longitude: 0) {
        didSet { overlayChanged() }
    }

    public var title: String? {
        didSet {
            overlayChanged()
            map?.infoContentDidChange(self)
        }
    }

    public var snippet: String? {
        didSet {
            overlayChanged()
            map?.infoContentDidChange(self)
        }
    }

    /// The image of the pin. Nil shows the default red pin.
    public var icon: UIImage? {
        didSet { overlayChanged() }
    }

    /// The point of the image that sits on `position`, in unit coordinates. (0.5, 1) is the bottom centre.
    public var groundAnchor = CGPoint(x: 0.5, y: 1.0) {
        didSet { overlayChanged() }
    }

    /// The rotation about the anchor, in degrees clockwise.
    public var rotation: CLLocationDegrees = 0 {
        didSet { overlayChanged() }
    }

    public var opacity: Float = 1.0 {
        didSet { overlayChanged() }
    }

    /// A flat marker stays fixed to the map when the camera is tilted.
    public var isFlat = false {
        didSet { overlayChanged() }
    }

    /// Whether a long press on the marker lets the user drag it.
    public var isDraggable = false {
        didSet { overlayChanged() }
    }

    public override init() {
        super.init()
        isTappable = true
    }

    public init(position: CLLocationCoordinate2D) {
        self.position = position
        super.init()
        isTappable = true
    }

    /// The default pin in `color`, as Google's `markerImageWithColor:`. Nil gives Google's red.
    public class func markerImage(with color: UIColor?) -> UIImage {
        let tint = color ?? UIColor.systemRed
        let size = CGSize(width: 28, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            // Two separate fills: one path with overlapping subpaths would cancel where they meet.
            let centre = CGPoint(x: size.width / 2, y: 14)
            let head = UIBezierPath(arcCenter: centre, radius: 13, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            let tip = UIBezierPath()
            tip.move(to: CGPoint(x: 4.5, y: 20))
            tip.addLine(to: CGPoint(x: size.width / 2, y: size.height - 1))
            tip.addLine(to: CGPoint(x: size.width - 4.5, y: 20))
            tip.close()
            tint.setFill()
            head.fill()
            tip.fill()
            UIColor.white.setFill()
            UIBezierPath(arcCenter: centre, radius: 4.5, startAngle: 0, endAngle: .pi * 2, clockwise: true).fill()
        }
    }
}

/// A line through a path, as Google's `GMSPolyline`.
public final class GMSPolyline: GMSOverlay {

    public var path: GMSPath? {
        didSet { overlayChanged() }
    }

    public var strokeWidth: CGFloat = 1 {
        didSet { overlayChanged() }
    }

    public var strokeColor: UIColor = .black {
        didSet { overlayChanged() }
    }

    /// Whether the line follows great circles between points, not straight lines on the flat map.
    public var geodesic = false {
        didSet { overlayChanged() }
    }

    public override init() {
        super.init()
    }

    public init(path: GMSPath?) {
        self.path = path
        super.init()
    }
}

/// A filled area with optional holes, as Google's `GMSPolygon`.
public final class GMSPolygon: GMSOverlay {

    public var path: GMSPath? {
        didSet { overlayChanged() }
    }

    public var holes: [GMSPath]? {
        didSet { overlayChanged() }
    }

    public var fillColor: UIColor? {
        didSet { overlayChanged() }
    }

    public var strokeColor: UIColor? {
        didSet { overlayChanged() }
    }

    public var strokeWidth: CGFloat = 1 {
        didSet { overlayChanged() }
    }

    public var geodesic = false {
        didSet { overlayChanged() }
    }

    public override init() {
        super.init()
    }

    public init(path: GMSPath?) {
        self.path = path
        super.init()
    }
}

/// A circle of `radius` metres around `position`, as Google's `GMSCircle`.
public final class GMSCircle: GMSOverlay {

    public var position = CLLocationCoordinate2D(latitude: 0, longitude: 0) {
        didSet { overlayChanged() }
    }

    public var radius: CLLocationDistance = 0 {
        didSet { overlayChanged() }
    }

    public var fillColor: UIColor? {
        didSet { overlayChanged() }
    }

    public var strokeColor: UIColor? {
        didSet { overlayChanged() }
    }

    public var strokeWidth: CGFloat = 1 {
        didSet { overlayChanged() }
    }

    public override init() {
        super.init()
    }

    public init(position: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.position = position
        self.radius = radius
        super.init()
    }
}

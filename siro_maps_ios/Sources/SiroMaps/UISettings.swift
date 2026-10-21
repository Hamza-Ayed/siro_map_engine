import UIKit

/// Gesture and control settings, as Google's `GMSUISettings`.
///
/// A change applies to the map at once. The my-location button is stored but not drawn yet.
public final class GMSUISettings: NSObject {

    private weak var map: GMSMapView?

    public var compassButton: Bool = false {
        didSet { map?.mlnMapView.showsCompassView = compassButton }
    }

    public var zoomGestures: Bool = true {
        didSet { map?.mlnMapView.isZoomEnabled = zoomGestures }
    }

    public var scrollGestures: Bool = true {
        didSet { map?.mlnMapView.isScrollEnabled = scrollGestures }
    }

    public var rotateGestures: Bool = true {
        didSet { map?.mlnMapView.isRotateEnabled = rotateGestures }
    }

    public var tiltGestures: Bool = true {
        didSet { map?.mlnMapView.isPitchEnabled = tiltGestures }
    }

    /// Stored for parity with Google. The button is not drawn by this SDK yet.
    public var myLocationButton: Bool = false

    /// Stored for parity with Google. Scrolling during a rotate or zoom is always allowed.
    public var allowScrollGesturesDuringRotateOrZoom: Bool = true

    internal init(map: GMSMapView) {
        self.map = map
        super.init()
    }
}

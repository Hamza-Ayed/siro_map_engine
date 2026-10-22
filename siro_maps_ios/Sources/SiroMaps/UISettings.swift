import UIKit

/// Gesture and control settings, as Google's `GMSUISettings`.
///
/// A change applies to the map at once.
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

    /// Shows the button that recentres the map on the user. It appears while my-location is on.
    public var myLocationButton: Bool = false {
        didSet { map?.updateMyLocationButton() }
    }

    /// Stored for compatibility. Siro has no indoor maps.
    public var indoorPicker: Bool = true

    /// Stored for compatibility. Siro's gestures always work in the map view.
    public var consumesGesturesInView: Bool = true

    /// Turns every gesture on or off at once.
    public func setAllGesturesEnabled(_ enabled: Bool) {
        zoomGestures = enabled
        scrollGestures = enabled
        rotateGestures = enabled
        tiltGestures = enabled
    }

    /// Stored for parity with Google. Scrolling during a rotate or zoom is always allowed.
    public var allowScrollGesturesDuringRotateOrZoom: Bool = true

    internal init(map: GMSMapView) {
        self.map = map
        super.init()
    }
}

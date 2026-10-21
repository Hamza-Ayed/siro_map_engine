import CoreLocation
import UIKit

/// Called by a `GMSMapView` about camera changes, taps, markers and info windows.
/// Every method is optional, as in Google's `GMSMapViewDelegate`.
@objc public protocol GMSMapViewDelegate: NSObjectProtocol {

    /// The camera started to move. `gesture` is true for a touch, false for an animation.
    @objc optional func mapView(_ mapView: GMSMapView, willMove gesture: Bool)
    @objc optional func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition)
    @objc optional func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition)

    @objc optional func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D)
    @objc optional func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D)

    /// Return true to consume the tap. If false or not implemented, the marker's info window opens.
    @objc(mapView:didTapMarker:) optional func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool
    @objc(mapView:didTapOverlay:) optional func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay)
    @objc optional func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker)

    /// A custom window for the marker, or nil to use `markerInfoContents`, then the default.
    @objc optional func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView?
    /// The content of the default window, or nil for the default layout.
    @objc optional func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView?

    @objc optional func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker)
    @objc optional func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker)
    @objc optional func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker)
}

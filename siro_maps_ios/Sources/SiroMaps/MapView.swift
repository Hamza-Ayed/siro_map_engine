import CoreLocation
import MapLibre
import UIKit

/// A map view with the Google Maps SDK for iOS API, as Google's `GMSMapView`.
///
/// Built on MapLibre with Siro's own styles. Overlays are drawn with the same names
/// and signatures as Google's; the attribution Siro's data needs replaces Google's logo.
public class GMSMapView: UIView {

    internal let mlnMapView: MLNMapView
    internal var overlays: [GMSOverlay] = []
    private lazy var renderer = Renderer(map: self)
    private lazy var projectionObject = GMSProjection(map: self)
    private let attributionLabel = UILabel()
    private let myLocationButton = UIButton(type: .system)
    private var infoWindow: UIView?
    private var draggingMarker: GMSMarker?
    private var scrollWasEnabled = true

    /// Receives the map's taps, camera changes, markers and info windows.
    public weak var delegate: GMSMapViewDelegate?

    public private(set) lazy var settings = GMSUISettings(map: self)

    public var mapType: GMSMapViewType = .normal {
        didSet { applyStyle() }
    }

    /// A custom style for the map. Used with `.normal` and `.terrain`; `.none` shows no map.
    public var mapStyle: GMSMapStyle? {
        didSet { applyStyle() }
    }

    /// The camera. Setting it moves the map at once, without animation.
    public var camera: GMSCameraPosition {
        get {
            GMSCameraPosition(
                target: mlnMapView.centerCoordinate,
                zoom: Float(mlnMapView.zoomLevel),
                bearing: mlnMapView.direction,
                viewingAngle: Double(mlnMapView.camera.pitch)
            )
        }
        set { apply(camera: newValue, animated: false) }
    }

    public var projection: GMSProjection { projectionObject }

    /// The marker whose info window is open. Setting it opens or closes the window.
    public var selectedMarker: GMSMarker? {
        didSet {
            updateInfoWindow()
            if let closed = oldValue, closed !== selectedMarker {
                delegate?.mapView?(self, didCloseInfoWindowOf: closed)
            }
        }
    }

    /// Shows the user's position. Asks for location permission when first turned on.
    public var isMyLocationEnabled: Bool = false {
        didSet {
            mlnMapView.showsUserLocation = isMyLocationEnabled
            updateMyLocationButton()
        }
    }

    public var minZoom: Float { Float(mlnMapView.minimumZoomLevel) }

    public var maxZoom: Float { Float(mlnMapView.maximumZoomLevel) }

    public func setMinZoom(_ minZoom: Float, maxZoom: Float) {
        mlnMapView.minimumZoomLevel = Double(minZoom)
        mlnMapView.maximumZoomLevel = Double(maxZoom)
    }

    public override init(frame: CGRect) {
        mlnMapView = MLNMapView(frame: frame, styleURL: SiroStyleURL.day)
        super.init(frame: frame)
        setUp(camera: GMSCameraPosition(target: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoom: 1))
    }

    public init(frame: CGRect, camera: GMSCameraPosition) {
        mlnMapView = MLNMapView(frame: frame, styleURL: SiroStyleURL.day)
        super.init(frame: frame)
        setUp(camera: camera)
    }

    public required init?(coder: NSCoder) {
        mlnMapView = MLNMapView(frame: .zero, styleURL: SiroStyleURL.day)
        super.init(coder: coder)
        setUp(camera: GMSCameraPosition(target: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoom: 1))
    }

    /// A map with `camera`, as Google's `map(withFrame:camera:)`.
    public class func map(withFrame frame: CGRect, camera: GMSCameraPosition) -> GMSMapView {
        GMSMapView(frame: frame, camera: camera)
    }

    private func setUp(camera: GMSCameraPosition) {
        mlnMapView.frame = bounds
        mlnMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mlnMapView.delegate = self
        mlnMapView.showsAttributionButton = false
        mlnMapView.showsLogoView = false
        mlnMapView.showsCompassView = settings.compassButton
        addSubview(mlnMapView)

        attributionLabel.text = "© OpenStreetMap contributors · Siro Maps"
        attributionLabel.font = .systemFont(ofSize: 10)
        attributionLabel.textColor = .darkGray
        attributionLabel.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        attributionLabel.sizeToFit()
        addSubview(attributionLabel)

        myLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        myLocationButton.backgroundColor = .white
        myLocationButton.tintColor = .darkGray
        myLocationButton.layer.cornerRadius = 22
        myLocationButton.layer.shadowColor = UIColor.black.cgColor
        myLocationButton.layer.shadowOpacity = 0.25
        myLocationButton.layer.shadowRadius = 3
        myLocationButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        myLocationButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        myLocationButton.isHidden = true
        myLocationButton.addTarget(self, action: #selector(recenterOnUser), for: .touchUpInside)
        addSubview(myLocationButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        // A double tap zooms the map. Wait for it to fail, so a double tap is not a tap.
        if let doubleTap = mlnMapView.gestureRecognizers?
            .compactMap({ $0 as? UITapGestureRecognizer })
            .first(where: { $0.numberOfTapsRequired == 2 }) {
            tap.require(toFail: doubleTap)
        }
        mlnMapView.addGestureRecognizer(tap)
        mlnMapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:))))

        apply(camera: camera, animated: false)
        applyStyle()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        mlnMapView.frame = bounds
        attributionLabel.frame.origin = CGPoint(x: 6, y: bounds.height - attributionLabel.frame.height - 6)
        myLocationButton.frame.origin = CGPoint(x: bounds.width - 44 - 12, y: safeAreaInsets.top + 12)
        positionInfoWindow()
    }

    /// Shows the my-location button while my-location is on and the settings ask for it.
    internal func updateMyLocationButton() {
        myLocationButton.isHidden = !(settings.myLocationButton && isMyLocationEnabled)
    }

    /// Centres the map on the user's position, keeping the zoom.
    @objc private func recenterOnUser() {
        if delegate?.didTapMyLocationButton?(for: self) == true { return }
        guard let coordinate = mlnMapView.userLocation?.location?.coordinate else { return }
        mlnMapView.setCenter(coordinate, animated: true)
    }

    // MARK: - Camera

    /// Animates the camera to `camera`, as Google's `animate(to:)`.
    public func animate(to camera: GMSCameraPosition) {
        apply(camera: camera, animated: true)
    }

    /// Animates the camera with `update`, as Google's `animate(with:)`.
    public func animate(with update: GMSCameraUpdate) {
        apply(camera: update.resolve(camera, self), animated: true)
    }

    /// Moves the camera with `update` at once, as Google's `moveCamera(_:)`.
    public func moveCamera(_ update: GMSCameraUpdate) {
        apply(camera: update.resolve(camera, self), animated: false)
    }

    private func apply(camera: GMSCameraPosition, animated: Bool) {
        mlnMapView.setCenter(camera.target, zoomLevel: Double(camera.zoom), direction: camera.bearing, animated: animated)
        if Double(mlnMapView.camera.pitch) != camera.viewingAngle {
            let tilted = mlnMapView.camera
            tilted.pitch = CGFloat(camera.viewingAngle)
            mlnMapView.setCamera(tilted, animated: animated)
        }
    }

    // MARK: - More of Google's map API

    /// Stored for compatibility. Siro has no traffic layer.
    public var isTrafficEnabled = false

    /// Stored for compatibility. Siro has no indoor maps.
    public var isIndoorEnabled = false

    /// Shows or hides the 3D buildings of the style.
    public var isBuildingsEnabled = true {
        didSet { applyBuildings() }
    }

    private func applyBuildings() {
        guard let style = mlnMapView.style else { return }
        for id in ["building-3d", "building-3d-osm"] {
            style.layer(withIdentifier: id)?.isVisible = isBuildingsEnabled
        }
    }

    /// The user's last known location, or nil if my-location is off or there is no fix yet.
    public var myLocation: CLLocation? {
        isMyLocationEnabled ? mlnMapView.userLocation?.location : nil
    }

    public func animate(toZoom zoom: Float) {
        animate(with: .zoomTo(zoom))
    }

    public func animate(toLocation location: CLLocationCoordinate2D) {
        animate(with: .setTarget(location))
    }

    public func animate(toBearing bearing: CLLocationDirection) {
        let current = camera
        animate(to: GMSCameraPosition(target: current.target, zoom: current.zoom, bearing: bearing, viewingAngle: current.viewingAngle))
    }

    public func animate(toViewingAngle viewingAngle: Double) {
        let current = camera
        animate(to: GMSCameraPosition(target: current.target, zoom: current.zoom, bearing: current.bearing, viewingAngle: viewingAngle))
    }

    /// The camera that fits `bounds` inside the map, leaving `insets` free, as Google's `camera(for:insets:)`.
    public func camera(for bounds: GMSCoordinateBounds, insets: UIEdgeInsets) -> GMSCameraPosition? {
        guard bounds.isValid else { return nil }
        let size = CGSize(width: max(1, self.bounds.width - insets.left - insets.right), height: max(1, self.bounds.height - insets.top - insets.bottom))
        return GMSCameraUpdate.fit(bounds, with: size).resolve(camera, self)
    }

    // MARK: - Overlays


    /// Removes every overlay from the map, as Google's `clear()`.
    public func clear() {
        for overlay in overlays {
            overlay.map = nil
        }
        selectedMarker = nil
    }

    internal func addOverlay(_ overlay: GMSOverlay) {
        if !overlays.contains(where: { $0 === overlay }) {
            overlays.append(overlay)
        }
        renderer.refresh()
    }

    internal func removeOverlay(_ overlay: GMSOverlay) {
        overlays.removeAll { $0 === overlay }
        if selectedMarker === overlay {
            selectedMarker = nil
        }
        renderer.refresh()
    }

    internal func overlayDidChange() {
        renderer.refresh()
        positionInfoWindow()
    }

    /// Rebuilds the info window when a marker's title or snippet changes while it is open.
    internal func infoContentDidChange(_ marker: GMSMarker) {
        if marker === selectedMarker {
            updateInfoWindow()
        }
    }

    // MARK: - Style

    private func applyStyle() {
        if mapType == .none {
            mlnMapView.styleJSON = GMSMapView.blankStyleJSON
            return
        }
        if let style = mapStyle {
            if let json = style.json {
                mlnMapView.styleJSON = json
            } else if let url = style.url {
                mlnMapView.styleURL = url
            }
            return
        }
        // Satellite and hybrid are not served yet. They show the day style, as on Android.
        mlnMapView.styleURL = mapType == .terrain ? SiroStyleURL.tactical : SiroStyleURL.day
    }

    private static let blankStyleJSON =
        ##"{"version":8,"sources":{},"layers":[{"id":"siro-background","type":"background","paint":{"background-color":"#eef1f4"}}]}"##

    // MARK: - Gestures

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let point = gesture.location(in: mlnMapView)
        guard let hit = renderer.hits(at: point).first else {
            delegate?.mapView?(self, didTapAt: coordinate(at: point))
            return
        }
        guard let overlay = overlays.first(where: { Renderer.identifier(for: $0) == hit.id }) else { return }
        if let marker = overlay as? GMSMarker {
            let consumed = delegate?.mapView?(self, didTap: marker) ?? false
            if !consumed {
                selectedMarker = marker
            }
        } else {
            delegate?.mapView?(self, didTap: overlay)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: mlnMapView)
        switch gesture.state {
        case .began:
            if let marker = draggableMarker(at: point) {
                startDragging(marker)
            } else {
                delegate?.mapView?(self, didLongPressAt: coordinate(at: point))
            }
        case .changed:
            guard let marker = draggingMarker else { return }
            marker.position = coordinate(at: point)
            delegate?.mapView?(self, didDrag: marker)
        case .ended, .cancelled, .failed:
            guard let marker = draggingMarker else { return }
            draggingMarker = nil
            mlnMapView.isScrollEnabled = scrollWasEnabled
            delegate?.mapView?(self, didEndDragging: marker)
        default:
            break
        }
    }

    private func draggableMarker(at point: CGPoint) -> GMSMarker? {
        guard let hit = renderer.hits(at: point).first(where: { $0.kind == "marker" }) else { return nil }
        return overlays.first(where: { Renderer.identifier(for: $0) == hit.id }) as? GMSMarker
    }

    private func startDragging(_ marker: GMSMarker) {
        guard marker.isDraggable else { return }
        draggingMarker = marker
        scrollWasEnabled = mlnMapView.isScrollEnabled
        mlnMapView.isScrollEnabled = false
        delegate?.mapView?(self, didBeginDragging: marker)
    }

    private func coordinate(at point: CGPoint) -> CLLocationCoordinate2D {
        mlnMapView.convert(point, toCoordinateFrom: mlnMapView)
    }

    // MARK: - Info window

    private func updateInfoWindow() {
        infoWindow?.removeFromSuperview()
        infoWindow = nil
        guard let marker = selectedMarker, marker.map === self else { return }

        let view: UIView
        if let custom = delegate?.mapView?(self, markerInfoWindow: marker) {
            view = custom
        } else if let contents = delegate?.mapView?(self, markerInfoContents: marker) {
            view = contents
        } else {
            guard marker.title != nil || marker.snippet != nil else { return }
            view = GMSInfoWindowView(title: marker.title, snippet: marker.snippet)
        }
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(infoWindowTapped)))
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(infoWindowLongPressed(_:))))
        addSubview(view)
        infoWindow = view
        positionInfoWindow()
    }

    private func positionInfoWindow() {
        guard let view = infoWindow, let marker = selectedMarker else { return }
        let point = mlnMapView.convert(marker.position, toPointTo: self)
        let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        // The window sits above the pin, which is about 44 points tall.
        view.frame = CGRect(x: point.x - size.width / 2, y: point.y - size.height - 44, width: size.width, height: size.height)
    }

    @objc private func infoWindowLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let marker = selectedMarker else { return }
        delegate?.mapView?(self, didLongPressInfoWindowOf: marker)
    }

    @objc private func infoWindowTapped() {
        guard let marker = selectedMarker else { return }
        delegate?.mapView?(self, didTapInfoWindowOf: marker)
    }
}

// MARK: - MapLibre events

extension GMSMapView: MLNMapViewDelegate {

    public func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        renderer.attach(to: style)
        applyBuildings()
    }

    public func mapView(_ mapView: MLNMapView, regionWillChangeAnimated animated: Bool) {
        // A camera change the user made is not animated; an animation the app asked for is.
        delegate?.mapView?(self, willMove: !animated)
    }

    public func mapViewRegionIsChanging(_ mapView: MLNMapView) {
        positionInfoWindow()
        delegate?.mapView?(self, didChange: camera)
    }

    public func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        positionInfoWindow()
    }

    public func mapViewDidBecomeIdle(_ mapView: MLNMapView) {
        delegate?.mapView?(self, idleAt: camera)
    }
}

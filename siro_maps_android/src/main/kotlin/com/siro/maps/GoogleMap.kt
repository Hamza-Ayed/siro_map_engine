package com.siro.maps

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.PointF
import android.view.MotionEvent
import androidx.core.content.ContextCompat
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.Style
import org.maplibre.android.style.layers.Property
import org.maplibre.android.style.layers.PropertyFactory
import org.maplibre.android.location.LocationComponentActivationOptions

/**
 * The map, with the API of the Google Maps SDK for Android.
 *
 * Obtain one from [MapView.getMapAsync] or [SupportMapFragment.getMapAsync]. Markers,
 * polylines, polygons and circles are added with the same `add*` methods and options.
 */
class GoogleMap internal constructor(
    internal val engine: MapLibreMap,
    internal val context: Context,
    internal val hostView: MapView,
) {
    internal val renderer = Renderer(this)
    internal val markers = mutableListOf<Marker>()
    internal val polylines = mutableListOf<Polyline>()
    internal val polygons = mutableListOf<Polygon>()
    internal val circles = mutableListOf<Circle>()
    internal val infoWindows = InfoWindows(this)
    private var nextId = 0
    private var listenersAttached = false
    private var markerClick: OnMarkerClickListener? = null
    private var mapClick: OnMapClickListener? = null
    private var mapLongClick: OnMapLongClickListener? = null
    private var polylineClick: OnPolylineClickListener? = null
    private var polygonClick: OnPolygonClickListener? = null
    private var circleClick: OnCircleClickListener? = null
    private var infoWindowClick: OnInfoWindowClickListener? = null
    private var infoWindowClose: OnInfoWindowCloseListener? = null
    private var infoWindowLongClick: OnInfoWindowLongClickListener? = null
    private var mapLoaded: OnMapLoadedCallback? = null
    private var loadedReported = false
    private var locationButtonClick: OnMyLocationButtonClickListener? = null
    private var buildings = true
    private var traffic = false
    private var indoor = false
    private var cameraIdle: OnCameraIdleListener? = null
    private var cameraMove: OnCameraMoveListener? = null
    private var cameraMoveStarted: OnCameraMoveStartedListener? = null
    private var markerDrag: OnMarkerDragListener? = null
    private var dragging: Marker? = null
    private var styleRequest = 0
    private var myLocation = false
    private var currentMapType = MAP_TYPE_NORMAL

    /** The camera's position as Google reports it. */
    val cameraPosition: CameraPosition
        get() = engine.cameraPosition.toSiro()

    val uiSettings: UiSettings = UiSettings(this)

    val projection: Projection = Projection(engine)

    /** The map type. Siro has day, night and tactical styles; see the constants. */
    var mapType: Int
        get() = currentMapType
        set(value) {
            if (value == currentMapType) return
            currentMapType = value
            loadStyle(styleUrlFor(value))
        }

    val minZoomLevel: Float
        get() = engine.minZoomLevel.toFloat()

    val maxZoomLevel: Float
        get() = engine.maxZoomLevel.toFloat()

    fun setMinZoomPreference(minZoom: Float) = engine.setMinZoomPreference(minZoom.toDouble())

    fun setMaxZoomPreference(maxZoom: Float) = engine.setMaxZoomPreference(maxZoom.toDouble())

    /** Restores the full zoom range. */
    fun resetMinMaxZoomPreference() {
        engine.setMinZoomPreference(0.0)
        engine.setMaxZoomPreference(25.5)
    }

    /** Keeps the camera's target inside [bounds]. Null removes the limit. */
    fun setLatLngBoundsForCameraTarget(bounds: LatLngBounds?) {
        engine.setLatLngBoundsForCameraTarget(bounds?.toEngine())
    }

    /**
     * Insets the map's controls and camera centre, as Google's `setPadding`.
     * The engine marks its own `setPadding` as deprecated, but it is still the one that insets the view.
     */
    @Suppress("DEPRECATION")
    fun setPadding(left: Int, top: Int, right: Int, bottom: Int) = engine.setPadding(left, top, right, bottom)

    /** Stops a camera animation where it is. */
    fun stopAnimation() = engine.cancelTransitions()

    /** Draws the map into a bitmap. The callback gets null if the map could not be drawn. */
    fun snapshot(callback: SnapshotReadyCallback) {
        engine.snapshot { bitmap: Bitmap? -> callback.onSnapshotReady(bitmap) }
    }

    fun setContentDescription(description: String?) {
        hostView.contentDescription = description
    }

    /** Shows or hides the 3D buildings of the style. */
    var isBuildingsEnabled: Boolean
        get() = buildings
        set(value) {
            buildings = value
            engine.style?.let { applyBuildings(it) }
        }

    /** Stored for compatibility. Siro has no traffic layer. */
    var isTrafficEnabled: Boolean
        get() = traffic
        set(value) {
            traffic = value
        }

    /** Stored for compatibility. Siro has no indoor maps. */
    var isIndoorEnabled: Boolean
        get() = indoor
        set(value) {
            indoor = value
        }

    private fun applyBuildings(style: Style) {
        val visibility = PropertyFactory.visibility(if (buildings) Property.VISIBLE else Property.NONE)
        for (id in listOf("building-3d", "building-3d-osm")) {
            style.getLayer(id)?.setProperties(visibility)
        }
    }

    fun setOnMapLoadedCallback(callback: OnMapLoadedCallback?) {
        mapLoaded = callback
        if (loadedReported) callback?.onMapLoaded()
    }

    fun setOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener?) {
        engine.addOnCameraMoveCancelListener { listener?.onCameraMoveCanceled() }
    }

    fun setOnInfoWindowCloseListener(listener: OnInfoWindowCloseListener?) {
        infoWindowClose = listener
    }

    fun setOnInfoWindowLongClickListener(listener: OnInfoWindowLongClickListener?) {
        infoWindowLongClick = listener
    }

    fun setOnMyLocationButtonClickListener(listener: OnMyLocationButtonClickListener?) {
        locationButtonClick = listener
    }

    /** Accepted so code written for Google compiles. The blue dot is not tappable yet. */
    fun setOnMyLocationClickListener(listener: OnMyLocationClickListener?) = Unit

    /** Accepted so code written for Google compiles. Siro's map has no tappable points of interest. */
    fun setOnPoiClickListener(listener: OnPoiClickListener?) = Unit

    /** Shows the blue dot at the user's position. Needs a location permission. */
    var isMyLocationEnabled: Boolean
        get() = myLocation
        set(value) {
            if (value) {
                val fine = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
                val coarse = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION)
                if (fine != PackageManager.PERMISSION_GRANTED && coarse != PackageManager.PERMISSION_GRANTED) {
                    throw SecurityException("Requires ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION permission.")
                }
            }
            myLocation = value
            engine.style?.let { style -> applyLocation(style) }
            updateMyLocationButton()
        }

    internal fun updateMyLocationButton() {
        hostView.setMyLocationButtonVisible(myLocation && uiSettings.isMyLocationButtonEnabled)
    }

    /** Animates the camera to the last known position of the user, as the my-location button does. */
    internal fun animateToMyLocation() {
        val location = engine.locationComponent.lastKnownLocation ?: return
        engine.animateCamera(
            org.maplibre.android.camera.CameraUpdateFactory.newLatLng(
                org.maplibre.android.geometry.LatLng(location.latitude, location.longitude),
            ),
        )
    }

    @Suppress("MissingPermission")
    private fun applyLocation(style: Style) {
        val component = engine.locationComponent
        if (myLocation) {
            if (!component.isLocationComponentActivated) {
                component.activateLocationComponent(
                    LocationComponentActivationOptions.builder(context, style).build(),
                )
            }
            component.isLocationComponentEnabled = true
        } else if (component.isLocationComponentActivated) {
            component.isLocationComponentEnabled = false
        }
    }

    // ---------------------------------------------------------------- camera

    fun moveCamera(update: CameraUpdate) = engine.moveCamera(update.toEngine(engine))

    fun animateCamera(update: CameraUpdate) = engine.animateCamera(update.toEngine(engine))

    fun animateCamera(update: CameraUpdate, callback: CancelableCallback?) {
        engine.animateCamera(update.toEngine(engine), callback?.let { wrap(it) })
    }

    fun animateCamera(update: CameraUpdate, durationMs: Int, callback: CancelableCallback?) {
        engine.animateCamera(update.toEngine(engine), durationMs, callback?.let { wrap(it) })
    }

    private fun wrap(callback: CancelableCallback) = object : MapLibreMap.CancelableCallback {
        override fun onCancel() = callback.onCancel()
        override fun onFinish() = callback.onFinish()
    }

    fun setOnCameraIdleListener(listener: OnCameraIdleListener?) {
        cameraIdle = listener
        attachListeners()
    }

    fun setOnCameraMoveListener(listener: OnCameraMoveListener?) {
        cameraMove = listener
        attachListeners()
    }

    fun setOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener?) {
        cameraMoveStarted = listener
        attachListeners()
    }

    // ---------------------------------------------------------------- objects

    fun addMarker(options: MarkerOptions): Marker =
        Marker(this, nextIdFor("m"), options).also {
            markers.add(it)
            // A long press on a draggable marker needs the map's gestures listening.
            attachListeners()
            renderer.refresh()
        }

    fun addPolyline(options: PolylineOptions): Polyline =
        Polyline(this, nextIdFor("p"), options).also {
            polylines.add(it)
            renderer.refresh()
        }

    fun addPolygon(options: PolygonOptions): Polygon =
        Polygon(this, nextIdFor("g"), options).also {
            polygons.add(it)
            renderer.refresh()
        }

    fun addCircle(options: CircleOptions): Circle =
        Circle(this, nextIdFor("c"), options).also {
            circles.add(it)
            renderer.refresh()
        }

    /** Removes every marker, polyline, polygon and circle. */
    fun clear() {
        markers.forEach { infoWindows.hide(it) }
        markers.clear()
        polylines.clear()
        polygons.clear()
        circles.clear()
        renderer.refresh()
    }

    private fun nextIdFor(prefix: String): String = "$prefix${nextId++}"

    // ---------------------------------------------------------------- style

    /** Sets a map style from a JSON string, or a style URL. Pass null to restore the default style. */
    fun setMapStyle(options: MapStyleOptions?): Boolean {
        val json = options?.json ?: styleUrlFor(currentMapType)
        loadStyle(json)
        return true
    }

    private fun loadStyle(styleUrlOrJson: String) {
        val builder = if (styleUrlOrJson.trimStart().startsWith("{")) {
            Style.Builder().fromJson(styleUrlOrJson)
        } else {
            Style.Builder().fromUri(styleUrlOrJson)
        }
        // Only the newest request attaches. An older style that finishes late would
        // otherwise take the renderer's sources away from the style on screen.
        val request = ++styleRequest
        engine.setStyle(builder) { style ->
            if (request == styleRequest) {
                renderer.attach(style)
                applyLocation(style)
                applyBuildings(style)
                if (!loadedReported) {
                    loadedReported = true
                    mapLoaded?.onMapLoaded()
                }
            }
        }
    }

    // ---------------------------------------------------------------- events

    fun setOnMarkerClickListener(listener: OnMarkerClickListener?) {
        markerClick = listener
        attachListeners()
    }

    fun setOnMapClickListener(listener: OnMapClickListener?) {
        mapClick = listener
        attachListeners()
    }

    fun setOnMapLongClickListener(listener: OnMapLongClickListener?) {
        mapLongClick = listener
        attachListeners()
    }

    fun setOnPolylineClickListener(listener: OnPolylineClickListener?) {
        polylineClick = listener
        attachListeners()
    }

    fun setOnPolygonClickListener(listener: OnPolygonClickListener?) {
        polygonClick = listener
        attachListeners()
    }

    fun setOnCircleClickListener(listener: OnCircleClickListener?) {
        circleClick = listener
        attachListeners()
    }

    fun setOnInfoWindowClickListener(listener: OnInfoWindowClickListener?) {
        infoWindowClick = listener
    }

    fun setInfoWindowAdapter(adapter: InfoWindowAdapter?) {
        infoWindows.adapter = adapter
    }

    private fun attachListeners() {
        if (listenersAttached) return
        listenersAttached = true
        engine.addOnMapClickListener { latLng -> handleTap(latLng, longPress = false) }
        engine.addOnMapLongClickListener { latLng -> handleTap(latLng, longPress = true) }
        engine.addOnCameraIdleListener {
            infoWindows.onCameraChanged()
            cameraIdle?.onCameraIdle()
        }
        engine.addOnCameraMoveListener {
            infoWindows.onCameraChanged()
            cameraMove?.onCameraMove()
        }
        engine.addOnCameraMoveStartedListener { reason -> cameraMoveStarted?.onCameraMoveStarted(reason) }
    }

    private fun handleTap(latLng: org.maplibre.android.geometry.LatLng, longPress: Boolean): Boolean {
        val hits = renderer.hitTest(engine.projection.toScreenLocation(latLng), engine)
        val hit = hits.firstOrNull()
        if (longPress && hit != null && hit.first == "marker") {
            val marker = markers.firstOrNull { it.id == hit.second }
            if (marker != null && marker.isDraggable) {
                startDrag(marker)
                return true
            }
        }
        if (hit != null && !longPress) {
            val (kind, id) = hit
            when (kind) {
                "marker" -> markers.firstOrNull { it.id == id }?.let { marker ->
                    val consumed = markerClick?.onMarkerClick(marker) ?: false
                    if (!consumed && (marker.title != null || marker.snippet != null)) marker.showInfoWindow()
                    return true
                }
                "polyline" -> polylines.firstOrNull { it.id == id }?.let { polylineClick?.onPolylineClick(it); return true }
                "polygon" -> polygons.firstOrNull { it.id == id }?.let { polygonClick?.onPolygonClick(it); return true }
                "circle" -> circles.firstOrNull { it.id == id }?.let { circleClick?.onCircleClick(it); return true }
            }
        }
        val target = latLng.toSiro()
        if (longPress) {
            mapLongClick?.onMapLongClick(target)
        } else {
            infoWindows.hideAll()
            mapClick?.onMapClick(target)
        }
        return true
    }

    internal fun notifyInfoWindowClick(marker: Marker) {
        infoWindowClick?.onInfoWindowClick(marker)
    }

    internal fun notifyInfoWindowClose(marker: Marker) {
        infoWindowClose?.onInfoWindowClose(marker)
    }

    internal fun notifyInfoWindowLongClick(marker: Marker) {
        infoWindowLongClick?.onInfoWindowLongClick(marker)
    }

    /** The my-location button was tapped. Recentres on the user unless the listener consumes it. */
    internal fun onMyLocationButtonClicked() {
        if (locationButtonClick?.onMyLocationButtonClick() != true) animateToMyLocation()
    }

    fun setOnMarkerDragListener(listener: OnMarkerDragListener?) {
        markerDrag = listener
    }

    private fun startDrag(marker: Marker) {
        dragging = marker
        // The map must not pan while the marker follows the finger.
        engine.uiSettings.setScrollGesturesEnabled(false)
        markerDrag?.onMarkerDragStart(marker)
    }

    /**
     * Moves the marker being dragged to the finger. Returns true while a drag owns the touch,
     * so the map does not pan under it.
     */
    internal fun onDragTouch(event: MotionEvent): Boolean {
        val marker = dragging ?: return false
        when (event.actionMasked) {
            MotionEvent.ACTION_MOVE -> {
                marker.position = engine.projection.fromScreenLocation(PointF(event.x, event.y)).toSiro()
                markerDrag?.onMarkerDrag(marker)
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                dragging = null
                engine.uiSettings.setScrollGesturesEnabled(uiSettings.isScrollGesturesEnabled)
                markerDrag?.onMarkerDragEnd(marker)
            }
        }
        return true
    }

    // ---------------------------------------------------------------- listeners

    fun interface OnMarkerClickListener {
        /** Return true to consume the click. If false, the marker's info window shows. */
        fun onMarkerClick(marker: Marker): Boolean
    }

    /** Called while a marker is dragged. Like Google's, a drag starts with a long press on a draggable marker. */
    interface OnMarkerDragListener {
        fun onMarkerDragStart(marker: Marker)
        fun onMarkerDrag(marker: Marker)
        fun onMarkerDragEnd(marker: Marker)
    }

    fun interface OnMapLoadedCallback {
        fun onMapLoaded()
    }

    fun interface SnapshotReadyCallback {
        fun onSnapshotReady(bitmap: Bitmap?)
    }

    fun interface OnCameraMoveCanceledListener {
        fun onCameraMoveCanceled()
    }

    fun interface OnInfoWindowCloseListener {
        fun onInfoWindowClose(marker: Marker)
    }

    fun interface OnInfoWindowLongClickListener {
        fun onInfoWindowLongClick(marker: Marker)
    }

    fun interface OnMyLocationButtonClickListener {
        /** Return true to consume the tap, so the map does not recentre. */
        fun onMyLocationButtonClick(): Boolean
    }

    fun interface OnMyLocationClickListener {
        fun onMyLocationClick(location: android.location.Location)
    }

    fun interface OnPoiClickListener {
        fun onPoiClick(poi: PointOfInterest)
    }

    fun interface OnMapClickListener {
        fun onMapClick(latLng: LatLng)
    }

    fun interface OnMapLongClickListener {
        fun onMapLongClick(latLng: LatLng)
    }

    fun interface OnPolylineClickListener {
        fun onPolylineClick(polyline: Polyline)
    }

    fun interface OnPolygonClickListener {
        fun onPolygonClick(polygon: Polygon)
    }

    fun interface OnCircleClickListener {
        fun onCircleClick(circle: Circle)
    }

    fun interface OnInfoWindowClickListener {
        fun onInfoWindowClick(marker: Marker)
    }

    fun interface OnCameraIdleListener {
        fun onCameraIdle()
    }

    fun interface OnCameraMoveListener {
        fun onCameraMove()
    }

    fun interface OnCameraMoveStartedListener {
        /** [reason] is one of the `REASON_*` values from [OnCameraMoveStartedListener.Companion]. */
        fun onCameraMoveStarted(reason: Int)

        companion object {
            const val REASON_API_GESTURE = 1
            const val REASON_DEVELOPER_ANIMATION = 2
            const val REASON_API_ANIMATION = 3
        }
    }

    interface CancelableCallback {
        fun onFinish()
        fun onCancel()
    }

    interface InfoWindowAdapter {
        /** A custom window for the marker, or null to use [getInfoContents]. */
        fun getInfoWindow(marker: Marker): android.view.View?

        /** The content of the window, or null for the default layout. */
        fun getInfoContents(marker: Marker): android.view.View?
    }

    companion object {
        const val MAP_TYPE_NONE = 0
        const val MAP_TYPE_NORMAL = 1
        const val MAP_TYPE_SATELLITE = 2
        const val MAP_TYPE_TERRAIN = 3
        const val MAP_TYPE_HYBRID = 4

        /** Siro's day style, on our server. */
        const val DAY_STYLE_URL = "https://map-saas.intaleqapp.com/siro/style-sovereign.json"

        /** Siro's night style. */
        const val NIGHT_STYLE_URL = "https://map-saas.intaleqapp.com/siro/style-sovereign-night.json"

        /** Siro's tactical 3D style, with terrain. */
        const val TACTICAL_STYLE_URL = "https://map-saas.intaleqapp.com/siro/style-sovereign-tactical.json"

        internal fun styleUrlFor(mapType: Int): String = when (mapType) {
            MAP_TYPE_TERRAIN -> TACTICAL_STYLE_URL
            else -> DAY_STYLE_URL
        }
    }
}

/** A JSON style, as in the Google Maps SDK, or a style URL on Siro's server. */
class MapStyleOptions(internal val json: String) {
    companion object {
        /** Siro's own style at [url]. Not part of Google's API: Google's style files are not used. */
        @JvmStatic
        fun fromSiroStyleUrl(url: String): MapStyleOptions = MapStyleOptions(url)
    }
}

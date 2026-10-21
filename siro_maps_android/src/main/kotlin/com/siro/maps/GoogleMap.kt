package com.siro.maps

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.Style
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
    private var cameraIdle: OnCameraIdleListener? = null
    private var cameraMove: OnCameraMoveListener? = null
    private var cameraMoveStarted: OnCameraMoveStartedListener? = null
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
        engine.setStyle(builder) { style ->
            renderer.attach(style)
            applyLocation(style)
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

    // ---------------------------------------------------------------- listeners

    fun interface OnMarkerClickListener {
        /** Return true to consume the click. If false, the marker's info window shows. */
        fun onMarkerClick(marker: Marker): Boolean
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

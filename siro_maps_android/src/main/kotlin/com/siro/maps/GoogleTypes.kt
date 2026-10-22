package com.siro.maps

import android.content.Context

/**
 * Google's `MapsInitializer`. Siro needs no initialisation, so these return success at once.
 * They exist so code that calls them before creating a map compiles and runs unchanged.
 */
object MapsInitializer {
    enum class Renderer { LEGACY, LATEST }

    fun interface OnMapsSdkInitializedCallback {
        fun onMapsSdkInitialized(renderer: Renderer)
    }

    /** Returns 0, Google's `ConnectionResult.SUCCESS`. */
    @JvmStatic
    fun initialize(context: Context): Int = 0

    @JvmStatic
    fun initialize(context: Context, preferredRenderer: Renderer?, callback: OnMapsSdkInitializedCallback?): Int {
        callback?.onMapsSdkInitialized(Renderer.LATEST)
        return 0
    }
}

/** Options for a map, as Google's `GoogleMapOptions`. Pass it to [MapView] or [SupportMapFragment.newInstance]. */
class GoogleMapOptions {
    internal var camera: CameraPosition? = null
    internal var mapType: Int? = null
    internal var compassEnabled: Boolean? = null
    internal var rotateGesturesEnabled: Boolean? = null
    internal var scrollGesturesEnabled: Boolean? = null
    internal var tiltGesturesEnabled: Boolean? = null
    internal var zoomGesturesEnabled: Boolean? = null
    internal var zoomControlsEnabled: Boolean? = null
    internal var mapToolbarEnabled: Boolean? = null
    internal var minZoom: Float? = null
    internal var maxZoom: Float? = null
    internal var cameraTargetBounds: LatLngBounds? = null

    fun camera(camera: CameraPosition?): GoogleMapOptions = apply { this.camera = camera }
    fun mapType(mapType: Int): GoogleMapOptions = apply { this.mapType = mapType }
    fun compassEnabled(enabled: Boolean): GoogleMapOptions = apply { compassEnabled = enabled }
    fun rotateGesturesEnabled(enabled: Boolean): GoogleMapOptions = apply { rotateGesturesEnabled = enabled }
    fun scrollGesturesEnabled(enabled: Boolean): GoogleMapOptions = apply { scrollGesturesEnabled = enabled }
    fun tiltGesturesEnabled(enabled: Boolean): GoogleMapOptions = apply { tiltGesturesEnabled = enabled }
    fun zoomGesturesEnabled(enabled: Boolean): GoogleMapOptions = apply { zoomGesturesEnabled = enabled }
    fun zoomControlsEnabled(enabled: Boolean): GoogleMapOptions = apply { zoomControlsEnabled = enabled }
    fun mapToolbarEnabled(enabled: Boolean): GoogleMapOptions = apply { mapToolbarEnabled = enabled }
    fun minZoomPreference(minZoom: Float): GoogleMapOptions = apply { this.minZoom = minZoom }
    fun maxZoomPreference(maxZoom: Float): GoogleMapOptions = apply { this.maxZoom = maxZoom }
    fun latLngBoundsForCameraTarget(bounds: LatLngBounds?): GoogleMapOptions = apply { cameraTargetBounds = bounds }

    // Accepted so code written for Google compiles. They do not change anything in Siro.
    fun liteMode(enabled: Boolean): GoogleMapOptions = this
    fun ambientEnabled(enabled: Boolean): GoogleMapOptions = this
    fun zOrderOnTop(onTop: Boolean): GoogleMapOptions = this
    fun useViewLifecycleInFragment(use: Boolean): GoogleMapOptions = this
    fun mapId(mapId: String?): GoogleMapOptions = this
}

/** A point of interest, as Google's `PointOfInterest`. */
class PointOfInterest(val latLng: LatLng, val placeId: String, val name: String)

/** A line end, as Google's `Cap`. Stored on the polyline; the line is drawn with round ends. */
open class Cap internal constructor(internal val name: String)

class ButtCap : Cap("butt")

class RoundCap : Cap("round")

class SquareCap : Cap("square")

/** A custom line end from an image. Accepted for compatibility; it is not drawn. */
class CustomCap(val bitmapDescriptor: BitmapDescriptor, val refWidth: Float = 10f) : Cap("custom")

/** Joint types of a line, as Google's `JointType`. */
object JointType {
    const val DEFAULT = 0
    const val BEVEL = 1
    const val ROUND = 2
}

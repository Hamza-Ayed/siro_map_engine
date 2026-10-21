package com.siro.maps

import android.graphics.Point
import android.graphics.PointF
import org.maplibre.android.camera.CameraUpdate as EngineCameraUpdate
import org.maplibre.android.camera.CameraUpdateFactory as EngineCameraUpdateFactory
import org.maplibre.android.maps.MapLibreMap

/**
 * A change to the camera, as in the Google Maps SDK. Build it with [CameraUpdateFactory].
 *
 * Some changes, like [CameraUpdateFactory.scrollBy], depend on where the camera is now,
 * so the change is resolved against the map when it is applied.
 */
class CameraUpdate internal constructor(private val resolve: (MapLibreMap) -> EngineCameraUpdate) {

    internal constructor(engine: EngineCameraUpdate) : this({ engine })

    internal fun toEngine(map: MapLibreMap): EngineCameraUpdate = resolve(map)
}

/** Creates [CameraUpdate]s, with the same names and signatures as the Google Maps SDK. */
object CameraUpdateFactory {

    @JvmStatic
    fun newCameraPosition(position: CameraPosition): CameraUpdate =
        CameraUpdate(EngineCameraUpdateFactory.newCameraPosition(position.toEngine()))

    @JvmStatic
    fun newLatLng(latLng: LatLng): CameraUpdate =
        CameraUpdate(EngineCameraUpdateFactory.newLatLng(latLng.toEngine()))

    @JvmStatic
    fun newLatLngZoom(latLng: LatLng, zoom: Float): CameraUpdate =
        CameraUpdate(EngineCameraUpdateFactory.newLatLngZoom(latLng.toEngine(), zoom.toDouble()))

    /** Fits [bounds] inside the map with [padding] pixels on every side. */
    @JvmStatic
    fun newLatLngBounds(bounds: LatLngBounds, padding: Int): CameraUpdate =
        CameraUpdate(
            EngineCameraUpdateFactory.newLatLngBounds(
                bounds.toEngine(),
                padding,
                padding,
                padding,
                padding,
            ),
        )

    /** Fits [bounds] inside a [width] by [height] pixel area with [padding] pixels. */
    @JvmStatic
    fun newLatLngBounds(bounds: LatLngBounds, width: Int, height: Int, padding: Int): CameraUpdate =
        CameraUpdate(
            EngineCameraUpdateFactory.newLatLngBounds(bounds.toEngine(), width.toDouble(), height.toDouble(), padding),
        )

    @JvmStatic
    fun zoomIn(): CameraUpdate = CameraUpdate(EngineCameraUpdateFactory.zoomIn())

    @JvmStatic
    fun zoomOut(): CameraUpdate = CameraUpdate(EngineCameraUpdateFactory.zoomOut())

    @JvmStatic
    fun zoomTo(zoom: Float): CameraUpdate =
        CameraUpdate(EngineCameraUpdateFactory.zoomTo(zoom.toDouble()))

    /** Changes the zoom by [amount], keeping the point at [focus] fixed on the screen. */
    @JvmStatic
    fun zoomBy(amount: Float, focus: Point? = null): CameraUpdate =
        CameraUpdate(
            if (focus == null) {
                EngineCameraUpdateFactory.zoomBy(amount.toDouble())
            } else {
                EngineCameraUpdateFactory.zoomBy(amount.toDouble(), focus)
            },
        )

    /** Moves the camera by [dx] and [dy] pixels on the screen. */
    @JvmStatic
    fun scrollBy(dx: Float, dy: Float): CameraUpdate = CameraUpdate { map ->
        val target = requireNotNull(map.cameraPosition.target)
        val here = map.projection.toScreenLocation(target)
        val moved = map.projection.fromScreenLocation(PointF(here.x + dx, here.y + dy))
        EngineCameraUpdateFactory.newLatLng(moved)
    }
}

internal fun LatLng.toEngine(): org.maplibre.android.geometry.LatLng =
    org.maplibre.android.geometry.LatLng(latitude, longitude)

internal fun org.maplibre.android.geometry.LatLng.toSiro(): LatLng =
    LatLng(latitude, longitude)

internal fun LatLngBounds.toEngine(): org.maplibre.android.geometry.LatLngBounds =
    org.maplibre.android.geometry.LatLngBounds.Builder()
        .include(southwest.toEngine())
        .include(northeast.toEngine())
        .build()

internal fun CameraPosition.toEngine(): org.maplibre.android.camera.CameraPosition =
    org.maplibre.android.camera.CameraPosition.Builder()
        .target(target.toEngine())
        .zoom(zoom.toDouble())
        .tilt(tilt.toDouble())
        .bearing(bearing.toDouble())
        .build()

internal fun org.maplibre.android.camera.CameraPosition.toSiro(): CameraPosition =
    CameraPosition(
        target = target!!.toSiro(),
        zoom = zoom.toFloat(),
        tilt = tilt.toFloat(),
        bearing = bearing.toFloat(),
    )

package com.siro.maps

import android.graphics.Point
import android.graphics.PointF
import org.maplibre.android.maps.MapLibreMap

/** Converts between screen pixels and map coordinates, as Google's `Projection`. */
class Projection internal constructor(private val engine: MapLibreMap) {

    /** The pixel on screen where [latLng] is, counted from the map's top-left corner. */
    fun toScreenLocation(latLng: LatLng): Point {
        val point: PointF = engine.projection.toScreenLocation(latLng.toEngine())
        return Point(point.x.toInt(), point.y.toInt())
    }

    /** The coordinate under the pixel [point]. */
    fun fromScreenLocation(point: Point): LatLng =
        engine.projection.fromScreenLocation(PointF(point.x.toFloat(), point.y.toFloat())).toSiro()

    /** The part of the map that is on screen right now. */
    val visibleRegion: VisibleRegion
        get() = engine.projection.getVisibleRegion().toSiro()
}

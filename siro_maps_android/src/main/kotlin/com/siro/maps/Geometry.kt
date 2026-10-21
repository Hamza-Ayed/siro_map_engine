package com.siro.maps

import kotlin.math.asin
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.math.PI

private const val EARTH_RADIUS_METERS = 6371000.0

/** A circle of [radiusMeters] around [center], on the sphere, so its size is right at any latitude. */
internal fun geodesicCircle(center: LatLng, radiusMeters: Double, points: Int = 64): List<LatLng> {
    val angular = radiusMeters / EARTH_RADIUS_METERS
    val lat1 = Math.toRadians(center.latitude)
    val lng1 = Math.toRadians(center.longitude)
    return List(points) { i ->
        val bearing = 2 * PI * i / points
        val lat2 = asin(sin(lat1) * cos(angular) + cos(lat1) * sin(angular) * cos(bearing))
        val lng2 = lng1 + atan2(
            sin(bearing) * sin(angular) * cos(lat1),
            cos(angular) - sin(lat1) * sin(lat2),
        )
        LatLng(Math.toDegrees(lat2), Math.toDegrees(lng2).let { ((it + 540) % 360) - 180 })
    }
}

/** Points along the great circle through [points], so a geodesic line follows the curve of the earth. */
internal fun geodesicLine(points: List<LatLng>, stepMeters: Double = 50000.0): List<LatLng> {
    if (points.size < 2) return points
    val out = mutableListOf(points.first())
    for (i in 1 until points.size) {
        val a = points[i - 1]
        val b = points[i]
        val lat1 = Math.toRadians(a.latitude)
        val lng1 = Math.toRadians(a.longitude)
        val lat2 = Math.toRadians(b.latitude)
        val lng2 = Math.toRadians(b.longitude)
        val h = sin((lat2 - lat1) / 2).let { it * it } +
            cos(lat1) * cos(lat2) * sin((lng2 - lng1) / 2).let { it * it }
        val angular = 2 * asin(sqrt(h))
        val steps = floor(angular * EARTH_RADIUS_METERS / stepMeters).toInt()
        val sinAngular = sin(angular)
        if (sinAngular != 0.0) {
            for (s in 1..steps) {
                val f = s.toDouble() / (steps + 1)
                val k1 = sin((1 - f) * angular) / sinAngular
                val k2 = sin(f * angular) / sinAngular
                val x = k1 * cos(lat1) * cos(lng1) + k2 * cos(lat2) * cos(lng2)
                val y = k1 * cos(lat1) * sin(lng1) + k2 * cos(lat2) * sin(lng2)
                val z = k1 * sin(lat1) + k2 * sin(lat2)
                out.add(LatLng(Math.toDegrees(atan2(z, sqrt(x * x + y * y))), Math.toDegrees(atan2(y, x))))
            }
        }
        out.add(b)
    }
    return out
}

/** A colour as the CSS `rgba(...)` string the engine's expressions read. */
internal fun cssColor(argb: Int): String {
    val a = (argb ushr 24) and 0xFF
    val r = (argb ushr 16) and 0xFF
    val g = (argb ushr 8) and 0xFF
    val b = argb and 0xFF
    return "rgba($r, $g, $b, ${"%.3f".format(a / 255.0)})"
}

internal fun alphaOf(argb: Int): Float = ((argb ushr 24) and 0xFF) / 255f

/**
 * Google's dash pattern in pixels, as the engine's dash array in line-width units.
 * Alternating dash and gap lengths; a zero-length item is a dot. An odd count repeats,
 * as in Google, and a single item is doubled, because a dash array needs an even count.
 */
internal fun dashArrayFor(patternPixels: List<Float>, width: Float): List<Float> {
    if (patternPixels.isEmpty()) return emptyList()
    val unit = if (width <= 0f) 1f else width
    var items = patternPixels.map { maxOf(kotlin.math.abs(it), 0.1f) / unit }
    if (items.size % 2 == 1) items = items + items
    return items
}

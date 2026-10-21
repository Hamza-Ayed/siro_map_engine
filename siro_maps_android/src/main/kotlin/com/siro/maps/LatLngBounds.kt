package com.siro.maps

/** A rectangle of latitudes and longitudes, as in the Google Maps SDK. */
class LatLngBounds(val southwest: LatLng, val northeast: LatLng) {

    /** Whether [point] lies inside the rectangle. Bounds that cross the antimeridian are not handled. */
    fun contains(point: LatLng): Boolean =
        point.latitude in southwest.latitude..northeast.latitude &&
            point.longitude in southwest.longitude..northeast.longitude

    val center: LatLng
        get() = LatLng(
            (southwest.latitude + northeast.latitude) / 2,
            (southwest.longitude + northeast.longitude) / 2,
        )

    override fun equals(other: Any?): Boolean =
        other is LatLngBounds && other.southwest == southwest && other.northeast == northeast

    override fun hashCode(): Int = 31 * southwest.hashCode() + northeast.hashCode()

    override fun toString(): String = "LatLngBounds(southwest=$southwest, northeast=$northeast)"

    class Builder {
        private var minLat = Double.POSITIVE_INFINITY
        private var maxLat = Double.NEGATIVE_INFINITY
        private var minLng = Double.POSITIVE_INFINITY
        private var maxLng = Double.NEGATIVE_INFINITY

        /** Includes [latLng] in the bounds. */
        fun include(latLng: LatLng): Builder {
            minLat = minOf(minLat, latLng.latitude)
            maxLat = maxOf(maxLat, latLng.latitude)
            minLng = minOf(minLng, latLng.longitude)
            maxLng = maxOf(maxLng, latLng.longitude)
            return this
        }

        fun build(): LatLngBounds {
            check(minLat <= maxLat) { "no points were included" }
            return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng))
        }
    }

    companion object {
        @JvmStatic
        fun builder(): Builder = Builder()
    }
}

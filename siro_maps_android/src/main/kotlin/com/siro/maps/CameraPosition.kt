package com.siro.maps

/** The camera's target, zoom, bearing and tilt, as in the Google Maps SDK. */
data class CameraPosition(
    val target: LatLng,
    val zoom: Float,
    val tilt: Float,
    val bearing: Float,
) {
    class Builder {
        private var target = LatLng(0.0, 0.0)
        private var zoom = 0f
        private var tilt = 0f
        private var bearing = 0f

        constructor()

        constructor(from: CameraPosition) {
            target = from.target
            zoom = from.zoom
            tilt = from.tilt
            bearing = from.bearing
        }

        fun target(target: LatLng): Builder = apply { this.target = target }
        fun zoom(zoom: Float): Builder = apply { this.zoom = zoom }
        fun tilt(tilt: Float): Builder = apply { this.tilt = tilt }
        fun bearing(bearing: Float): Builder = apply { this.bearing = bearing }
        fun build(): CameraPosition = CameraPosition(target, zoom, tilt, bearing)
    }

    companion object {
        @JvmStatic
        fun builder(): Builder = Builder()

        @JvmStatic
        fun builder(from: CameraPosition): Builder = Builder(from)

        @JvmStatic
        fun fromLatLngZoom(target: LatLng, zoom: Float): CameraPosition =
            CameraPosition(target, zoom, 0f, 0f)
    }
}

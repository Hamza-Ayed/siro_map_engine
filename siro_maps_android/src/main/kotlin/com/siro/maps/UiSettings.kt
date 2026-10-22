package com.siro.maps

/**
 * Gesture and control settings, with the names of Google's `UiSettings`.
 *
 * A change applies to the map at once. Zoom controls are not drawn by this SDK yet.
 */
class UiSettings internal constructor(private val map: GoogleMap) {

    var isCompassEnabled: Boolean = true
        set(value) {
            field = value
            map.engine.uiSettings.setCompassEnabled(value)
        }

    var isRotateGesturesEnabled: Boolean = true
        set(value) {
            field = value
            map.engine.uiSettings.setRotateGesturesEnabled(value)
        }

    var isScrollGesturesEnabled: Boolean = true
        set(value) {
            field = value
            map.engine.uiSettings.setScrollGesturesEnabled(value)
        }

    var isTiltGesturesEnabled: Boolean = true
        set(value) {
            field = value
            map.engine.uiSettings.setTiltGesturesEnabled(value)
        }

    var isZoomGesturesEnabled: Boolean = true
        set(value) {
            field = value
            map.engine.uiSettings.setZoomGesturesEnabled(value)
        }

    /** The button that recentres the map on the user. It shows while my-location is on. */
    var isMyLocationButtonEnabled: Boolean = false
        set(value) {
            field = value
            map.updateMyLocationButton()
        }
}

package com.siro.maps

/** A latitude and longitude in degrees, as in the Google Maps SDK. */
data class LatLng(val latitude: Double, val longitude: Double) {
    init {
        require(latitude in -90.0..90.0) { "latitude out of range: $latitude" }
    }

    override fun toString(): String = "lat/lng: ($latitude,$longitude)"
}

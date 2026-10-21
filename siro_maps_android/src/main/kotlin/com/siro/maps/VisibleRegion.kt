package com.siro.maps

/** The part of the map on screen, as its four corners and the bounds around them. */
class VisibleRegion(
    val nearLeft: LatLng,
    val nearRight: LatLng,
    val farLeft: LatLng,
    val farRight: LatLng,
    val latLngBounds: LatLngBounds,
)

internal fun org.maplibre.android.geometry.VisibleRegion.toSiro(): VisibleRegion = VisibleRegion(
    nearLeft = requireNotNull(nearLeft).toSiro(),
    nearRight = requireNotNull(nearRight).toSiro(),
    farLeft = requireNotNull(farLeft).toSiro(),
    farRight = requireNotNull(farRight).toSiro(),
    latLngBounds = requireNotNull(latLngBounds).toSiro(),
)

internal fun org.maplibre.android.geometry.LatLngBounds.toSiro(): LatLngBounds =
    LatLngBounds(southWest.toSiro(), northEast.toSiro())

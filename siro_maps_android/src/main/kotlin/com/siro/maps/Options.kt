package com.siro.maps

import android.graphics.Color

/** Options for a [Marker]. Same builder methods as the Google Maps SDK. */
class MarkerOptions {
    internal var position: LatLng? = null
    internal var title: String? = null
    internal var snippet: String? = null
    internal var icon: BitmapDescriptor = BitmapDescriptorFactory.defaultMarker()
    internal var alpha = 1f
    internal var anchorU = 0.5f
    internal var anchorV = 1f
    internal var rotation = 0f
    internal var flat = false
    internal var visible = true
    internal var zIndex = 0f
    internal var draggable = false
    internal var infoWindowAnchorU = 0.5f
    internal var infoWindowAnchorV = 0f
    internal var tag: Any? = null

    fun position(position: LatLng): MarkerOptions = apply { this.position = position }
    fun title(title: String?): MarkerOptions = apply { this.title = title }
    fun snippet(snippet: String?): MarkerOptions = apply { this.snippet = snippet }
    fun icon(icon: BitmapDescriptor?): MarkerOptions = apply {
        this.icon = icon ?: BitmapDescriptorFactory.defaultMarker()
    }
    fun alpha(alpha: Float): MarkerOptions = apply { this.alpha = alpha }
    fun anchor(u: Float, v: Float): MarkerOptions = apply {
        anchorU = u
        anchorV = v
    }
    fun rotation(rotation: Float): MarkerOptions = apply { this.rotation = rotation }
    fun flat(flat: Boolean): MarkerOptions = apply { this.flat = flat }
    fun visible(visible: Boolean): MarkerOptions = apply { this.visible = visible }
    fun zIndex(zIndex: Float): MarkerOptions = apply { this.zIndex = zIndex }
    fun draggable(draggable: Boolean): MarkerOptions = apply { this.draggable = draggable }
    fun infoWindowAnchor(u: Float, v: Float): MarkerOptions = apply {
        infoWindowAnchorU = u
        infoWindowAnchorV = v
    }
}

/** Options for a [Polyline]. Same builder methods as the Google Maps SDK. */
class PolylineOptions {
    internal val points = mutableListOf<LatLng>()
    internal var width = 10f
    internal var color = Color.BLACK
    internal var zIndex = 0f
    internal var visible = true
    internal var geodesic = false
    internal var pattern: List<PatternItem>? = null
    internal var clickable = false
    internal var startCap: Cap = ButtCap()
    internal var endCap: Cap = ButtCap()
    internal var jointType = JointType.DEFAULT

    fun add(vararg points: LatLng): PolylineOptions = apply { this.points.addAll(points) }
    fun addAll(points: Iterable<LatLng>): PolylineOptions = apply { this.points.addAll(points) }
    fun width(width: Float): PolylineOptions = apply { this.width = width }
    fun color(color: Int): PolylineOptions = apply { this.color = color }
    fun zIndex(zIndex: Float): PolylineOptions = apply { this.zIndex = zIndex }
    fun visible(visible: Boolean): PolylineOptions = apply { this.visible = visible }
    fun geodesic(geodesic: Boolean): PolylineOptions = apply { this.geodesic = geodesic }
    fun pattern(pattern: List<PatternItem>?): PolylineOptions = apply { this.pattern = pattern }
    fun clickable(clickable: Boolean): PolylineOptions = apply { this.clickable = clickable }
    fun startCap(cap: Cap): PolylineOptions = apply { startCap = cap }
    fun endCap(cap: Cap): PolylineOptions = apply { endCap = cap }
    fun jointType(jointType: Int): PolylineOptions = apply { this.jointType = jointType }
}

/** Options for a [Polygon]. Same builder methods as the Google Maps SDK. */
class PolygonOptions {
    internal val points = mutableListOf<LatLng>()
    internal val holes = mutableListOf<List<LatLng>>()
    internal var strokeWidth = 10f
    internal var strokeColor = Color.BLACK
    internal var fillColor = Color.TRANSPARENT
    internal var zIndex = 0f
    internal var visible = true
    internal var geodesic = false
    internal var clickable = false

    fun add(vararg points: LatLng): PolygonOptions = apply { this.points.addAll(points) }
    fun addAll(points: Iterable<LatLng>): PolygonOptions = apply { this.points.addAll(points) }
    fun addHole(hole: Iterable<LatLng>): PolygonOptions = apply { holes.add(hole.toList()) }
    fun strokeWidth(width: Float): PolygonOptions = apply { strokeWidth = width }
    fun strokeColor(color: Int): PolygonOptions = apply { strokeColor = color }
    fun fillColor(color: Int): PolygonOptions = apply { fillColor = color }
    fun zIndex(zIndex: Float): PolygonOptions = apply { this.zIndex = zIndex }
    fun visible(visible: Boolean): PolygonOptions = apply { this.visible = visible }
    fun geodesic(geodesic: Boolean): PolygonOptions = apply { this.geodesic = geodesic }
    fun clickable(clickable: Boolean): PolygonOptions = apply { this.clickable = clickable }

    // Accepted so code written for Google compiles. The outline is drawn solid with round joints.
    fun strokePattern(pattern: List<PatternItem>?): PolygonOptions = this
    fun strokeJointType(jointType: Int): PolygonOptions = this
}

/** Options for a [Circle]. Same builder methods as the Google Maps SDK. */
class CircleOptions {
    internal var center: LatLng = LatLng(0.0, 0.0)
    internal var radius = 0.0
    internal var strokeWidth = 10f
    internal var strokeColor = Color.BLACK
    internal var fillColor = Color.TRANSPARENT
    internal var zIndex = 0f
    internal var visible = true
    internal var clickable = false

    fun center(center: LatLng): CircleOptions = apply { this.center = center }
    /** The radius in metres, on the ground. */
    fun radius(radius: Double): CircleOptions = apply { this.radius = radius }
    fun strokeWidth(width: Float): CircleOptions = apply { strokeWidth = width }
    fun strokeColor(color: Int): CircleOptions = apply { strokeColor = color }
    fun fillColor(color: Int): CircleOptions = apply { fillColor = color }
    fun zIndex(zIndex: Float): CircleOptions = apply { this.zIndex = zIndex }
    fun visible(visible: Boolean): CircleOptions = apply { this.visible = visible }
    fun clickable(clickable: Boolean): CircleOptions = apply { this.clickable = clickable }

    /** Accepted so code written for Google compiles. The outline is drawn solid. */
    fun strokePattern(pattern: List<PatternItem>?): CircleOptions = this
}

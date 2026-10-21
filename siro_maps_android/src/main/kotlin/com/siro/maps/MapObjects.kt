package com.siro.maps

/** Marker: a point on the map. Created with [GoogleMap.addMarker]. */
class Marker internal constructor(
    internal val owner: GoogleMap,
    internal val id: String,
    options: MarkerOptions,
) {
    private var pos: LatLng = options.position ?: throw IllegalArgumentException("position must be set")
    private var titleText: String? = options.title
    private var snippetText: String? = options.snippet
    private var iconValue: BitmapDescriptor = options.icon
    private var alphaValue = options.alpha
    private var anchorU = options.anchorU
    private var anchorV = options.anchorV
    private var rotationValue = options.rotation
    private var flatValue = options.flat
    private var visibleValue = options.visible
    private var zIndexValue = options.zIndex
    private var draggableValue = options.draggable
    private var removed = false

    /** Arbitrary data attached to the marker, as with Google's `setTag`. */
    var tag: Any? = options.tag

    var position: LatLng
        get() = pos
        set(value) {
            pos = value
            owner.renderer.refresh()
        }

    var title: String?
        get() = titleText
        set(value) {
            titleText = value
            owner.infoWindows.refreshIfShown(this)
        }

    var snippet: String?
        get() = snippetText
        set(value) {
            snippetText = value
            owner.infoWindows.refreshIfShown(this)
        }

    var alpha: Float
        get() = alphaValue
        set(value) {
            alphaValue = value
            owner.renderer.refresh()
        }

    var rotation: Float
        get() = rotationValue
        set(value) {
            rotationValue = value
            owner.renderer.refresh()
        }

    var zIndex: Float
        get() = zIndexValue
        set(value) {
            zIndexValue = value
            owner.renderer.refresh()
        }

    var isVisible: Boolean
        get() = visibleValue
        set(value) {
            visibleValue = value
            owner.renderer.refresh()
        }

    var isFlat: Boolean
        get() = flatValue
        set(value) {
            flatValue = value
        }

    var isDraggable: Boolean
        get() = draggableValue
        set(value) {
            draggableValue = value
        }

    var icon: BitmapDescriptor
        get() = iconValue
        set(value) {
            iconValue = value
            owner.renderer.refresh()
        }

    fun setAnchor(u: Float, v: Float) {
        anchorU = u
        anchorV = v
        owner.renderer.refresh()
    }

    fun showInfoWindow() = owner.infoWindows.show(this)

    fun hideInfoWindow() = owner.infoWindows.hide(this)

    val isInfoWindowShown: Boolean
        get() = owner.infoWindows.isShown(this)

    /** Removes the marker from the map. */
    fun remove() {
        if (removed) return
        removed = true
        owner.markers.remove(this)
        owner.infoWindows.hide(this)
        owner.renderer.refresh()
    }

    internal val isRemoved: Boolean get() = removed
    internal val anchorValue: String
        get() = when {
            anchorV >= 0.75f -> "bottom"
            anchorV <= 0.25f -> "top"
            else -> "center"
        }

    override fun equals(other: Any?): Boolean = other is Marker && other.id == id
    override fun hashCode(): Int = id.hashCode()
    override fun toString(): String = "Marker{id=$id, position=$pos}"
}

/** Polyline: a line through points. Created with [GoogleMap.addPolyline]. */
class Polyline internal constructor(
    internal val owner: GoogleMap,
    internal val id: String,
    options: PolylineOptions,
) {
    private var pts: List<LatLng> = options.points.toList()
    private var widthValue = options.width
    private var colorValue = options.color
    private var zIndexValue = options.zIndex
    private var visibleValue = options.visible
    private var geodesicValue = options.geodesic
    private var patternValue = options.pattern
    private var clickableValue = options.clickable
    private var removed = false

    var tag: Any? = null

    var points: List<LatLng>
        get() = pts
        set(value) {
            pts = value.toList()
            owner.renderer.refresh()
        }

    var width: Float
        get() = widthValue
        set(value) {
            widthValue = value
            owner.renderer.refresh()
        }

    var color: Int
        get() = colorValue
        set(value) {
            colorValue = value
            owner.renderer.refresh()
        }

    var zIndex: Float
        get() = zIndexValue
        set(value) {
            zIndexValue = value
            owner.renderer.refresh()
        }

    var isVisible: Boolean
        get() = visibleValue
        set(value) {
            visibleValue = value
            owner.renderer.refresh()
        }

    var isGeodesic: Boolean
        get() = geodesicValue
        set(value) {
            geodesicValue = value
            owner.renderer.refresh()
        }

    var pattern: List<PatternItem>?
        get() = patternValue
        set(value) {
            patternValue = value
            owner.renderer.refresh()
        }

    var isClickable: Boolean
        get() = clickableValue
        set(value) {
            clickableValue = value
        }

    fun remove() {
        if (removed) return
        removed = true
        owner.polylines.remove(this)
        owner.renderer.refresh()
    }

    internal val isRemoved: Boolean get() = removed

    override fun equals(other: Any?): Boolean = other is Polyline && other.id == id
    override fun hashCode(): Int = id.hashCode()
}

/** Polygon: a filled area with an outline. Created with [GoogleMap.addPolygon]. */
class Polygon internal constructor(
    internal val owner: GoogleMap,
    internal val id: String,
    options: PolygonOptions,
) {
    private var pts: List<LatLng> = options.points.toList()
    private var holesValue: List<List<LatLng>> = options.holes.toList()
    private var strokeWidthValue = options.strokeWidth
    private var strokeColorValue = options.strokeColor
    private var fillColorValue = options.fillColor
    private var zIndexValue = options.zIndex
    private var visibleValue = options.visible
    private var geodesicValue = options.geodesic
    private var clickableValue = options.clickable
    private var removed = false

    var tag: Any? = null

    var points: List<LatLng>
        get() = pts
        set(value) {
            pts = value.toList()
            owner.renderer.refresh()
        }

    var holes: List<List<LatLng>>
        get() = holesValue
        set(value) {
            holesValue = value.map { it.toList() }
            owner.renderer.refresh()
        }

    var strokeWidth: Float
        get() = strokeWidthValue
        set(value) {
            strokeWidthValue = value
            owner.renderer.refresh()
        }

    var strokeColor: Int
        get() = strokeColorValue
        set(value) {
            strokeColorValue = value
            owner.renderer.refresh()
        }

    var fillColor: Int
        get() = fillColorValue
        set(value) {
            fillColorValue = value
            owner.renderer.refresh()
        }

    var zIndex: Float
        get() = zIndexValue
        set(value) {
            zIndexValue = value
            owner.renderer.refresh()
        }

    var isVisible: Boolean
        get() = visibleValue
        set(value) {
            visibleValue = value
            owner.renderer.refresh()
        }

    var isGeodesic: Boolean
        get() = geodesicValue
        set(value) {
            geodesicValue = value
            owner.renderer.refresh()
        }

    var isClickable: Boolean
        get() = clickableValue
        set(value) {
            clickableValue = value
        }

    fun remove() {
        if (removed) return
        removed = true
        owner.polygons.remove(this)
        owner.renderer.refresh()
    }

    internal val isRemoved: Boolean get() = removed

    override fun equals(other: Any?): Boolean = other is Polygon && other.id == id
    override fun hashCode(): Int = id.hashCode()
}

/** Circle: a ring of [radius] metres around [center]. Created with [GoogleMap.addCircle]. */
class Circle internal constructor(
    internal val owner: GoogleMap,
    internal val id: String,
    options: CircleOptions,
) {
    private var centerValue: LatLng = options.center
    private var radiusValue = options.radius
    private var strokeWidthValue = options.strokeWidth
    private var strokeColorValue = options.strokeColor
    private var fillColorValue = options.fillColor
    private var zIndexValue = options.zIndex
    private var visibleValue = options.visible
    private var clickableValue = options.clickable
    private var removed = false

    var tag: Any? = null

    var center: LatLng
        get() = centerValue
        set(value) {
            centerValue = value
            owner.renderer.refresh()
        }

    var radius: Double
        get() = radiusValue
        set(value) {
            radiusValue = value
            owner.renderer.refresh()
        }

    var strokeWidth: Float
        get() = strokeWidthValue
        set(value) {
            strokeWidthValue = value
            owner.renderer.refresh()
        }

    var strokeColor: Int
        get() = strokeColorValue
        set(value) {
            strokeColorValue = value
            owner.renderer.refresh()
        }

    var fillColor: Int
        get() = fillColorValue
        set(value) {
            fillColorValue = value
            owner.renderer.refresh()
        }

    var zIndex: Float
        get() = zIndexValue
        set(value) {
            zIndexValue = value
            owner.renderer.refresh()
        }

    var isVisible: Boolean
        get() = visibleValue
        set(value) {
            visibleValue = value
            owner.renderer.refresh()
        }

    var isClickable: Boolean
        get() = clickableValue
        set(value) {
            clickableValue = value
        }

    fun remove() {
        if (removed) return
        removed = true
        owner.circles.remove(this)
        owner.renderer.refresh()
    }

    internal val isRemoved: Boolean get() = removed

    override fun equals(other: Any?): Boolean = other is Circle && other.id == id
    override fun hashCode(): Int = id.hashCode()
}

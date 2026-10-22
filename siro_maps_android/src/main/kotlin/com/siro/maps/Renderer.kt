package com.siro.maps

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.PointF
import com.google.gson.JsonObject
import org.maplibre.android.maps.Style
import org.maplibre.android.style.expressions.Expression
import org.maplibre.android.style.layers.FillExtrusionLayer
import org.maplibre.android.style.layers.FillLayer
import org.maplibre.android.style.layers.Layer
import org.maplibre.android.style.layers.LineLayer
import org.maplibre.android.style.layers.Property
import org.maplibre.android.style.layers.PropertyFactory
import org.maplibre.android.style.layers.SymbolLayer
import org.maplibre.android.style.sources.GeoJsonSource
import org.maplibre.geojson.Feature
import org.maplibre.geojson.FeatureCollection
import org.maplibre.geojson.LineString
import org.maplibre.geojson.Point
import org.maplibre.geojson.Polygon as GeoPolygon

/**
 * Turns the map's markers, lines, polygons and circles into engine sources and layers.
 *
 * Sources and layers are rebuilt from the current objects on every [refresh]. Lines
 * and fills read their colour and width from each feature, so one layer draws them
 * all. Dash arrays are constant per layer in the engine, so each dashed polyline gets
 * its own source and layer.
 */
internal class Renderer(private val owner: GoogleMap) {

    private var style: Style? = null
    private val dashed = mutableMapOf<String, Polyline>()
    private val addedImages = mutableSetOf<String>()

    /** Attaches to a freshly loaded style. Everything is rebuilt on the next [refresh]. */
    fun attach(style: Style) {
        this.style = style
        addedImages.clear()
        dashed.clear()
        addBaseLayers(style)
        refresh()
    }

    private fun addBaseLayers(style: Style) {
        // Overlays go above the base map and the 3D buildings, and below the labels.
        // Labels are the first symbol layer after the last extrusion, so the buildings stay under overlays.
        val lastExtrusion = style.layers.indexOfLast { it is FillExtrusionLayer }
        val below = style.layers.withIndex()
            .firstOrNull { (index, layer) -> layer is SymbolLayer && index > lastExtrusion }
            ?.value?.id
        style.addSource(GeoJsonSource(FILL_SOURCE, FeatureCollection.fromFeatures(emptyList())))
        style.addSource(GeoJsonSource(LINE_SOURCE, FeatureCollection.fromFeatures(emptyList())))
        style.addSource(GeoJsonSource(MARKER_SOURCE, FeatureCollection.fromFeatures(emptyList())))

        // The colour string carries its alpha, so the fill needs no separate opacity.
        val fill = FillLayer(FILL_LAYER, FILL_SOURCE).withProperties(
            PropertyFactory.fillColor(Expression.toColor(Expression.get("color"))),
            PropertyFactory.fillOpacity(Expression.get("opacity")),
        )
        val line = LineLayer(LINE_LAYER, LINE_SOURCE).withProperties(
            PropertyFactory.lineColor(Expression.toColor(Expression.get("color"))),
            PropertyFactory.lineOpacity(Expression.get("opacity")),
            PropertyFactory.lineWidth(Expression.get("width")),
            PropertyFactory.lineCap(Property.LINE_CAP_ROUND),
            PropertyFactory.lineJoin(Property.LINE_JOIN_ROUND),
        )
        val marker = SymbolLayer(MARKER_LAYER, MARKER_SOURCE).withProperties(
            PropertyFactory.iconImage(Expression.get("icon")),
            PropertyFactory.iconAnchor(Expression.get("anchor")),
            PropertyFactory.iconRotate(Expression.get("rotation")),
            PropertyFactory.iconOpacity(Expression.get("alpha")),
            PropertyFactory.iconAllowOverlap(true),
            PropertyFactory.iconIgnorePlacement(true),
        )
        if (below != null) {
            style.addLayerBelow(fill, below)
            style.addLayerBelow(line, below)
        } else {
            style.addLayer(fill)
            style.addLayer(line)
        }
        style.addLayer(marker)
    }

    /** Rebuilds every source from the current objects. Cheap to call often. */
    fun refresh() {
        val style = style ?: return
        val fills = mutableListOf<Feature>()
        val lines = mutableListOf<Feature>()
        val markers = mutableListOf<Feature>()

        val polygons = owner.polygons.filter { it.isVisible && !it.isRemoved }.sortedBy { it.zIndex }
        for (polygon in polygons) {
            val rings = (listOf(polygon.points) + polygon.holes).filter { it.isNotEmpty() }
            val outline = rings.map { ring -> if (polygon.isGeodesic) geodesicLine(ring + ring.first()) else ring + ring.first() }
            if (polygon.points.size >= 3) {
                if (alphaOf(polygon.fillColor) > 0f) {
                    fills.add(polygonFeature(polygon.id, "polygon", rings, polygon.fillColor))
                }
                if (polygon.strokeWidth > 0 && alphaOf(polygon.strokeColor) > 0f) {
                    outline.forEach { lines.add(lineFeature(polygon.id, "polygon", it, polygon.strokeColor, polygon.strokeWidth)) }
                }
            }
        }

        val circles = owner.circles.filter { it.isVisible && !it.isRemoved && it.radius > 0 }.sortedBy { it.zIndex }
        for (circle in circles) {
            val ring = geodesicCircle(circle.center, circle.radius)
            if (alphaOf(circle.fillColor) > 0f) {
                fills.add(polygonFeature(circle.id, "circle", listOf(ring), circle.fillColor))
            }
            if (circle.strokeWidth > 0 && alphaOf(circle.strokeColor) > 0f) {
                lines.add(lineFeature(circle.id, "circle", ring + ring.first(), circle.strokeColor, circle.strokeWidth))
            }
        }

        // Dashed polylines leave the shared line layer: each gets its own layer below.
        removeDashed(style)
        val polylines = owner.polylines.filter { it.isVisible && !it.isRemoved && it.points.size >= 2 }.sortedBy { it.zIndex }
        for (polyline in polylines) {
            val points = if (polyline.isGeodesic) geodesicLine(polyline.points) else polyline.points
            val pattern = polyline.pattern
            if (pattern.isNullOrEmpty()) {
                lines.add(lineFeature(polyline.id, "polyline", points, polyline.color, polyline.width))
            } else {
                addDashed(style, polyline, points, pattern)
            }
        }

        for (marker in owner.markers.filter { it.isVisible && !it.isRemoved }.sortedBy { it.zIndex }) {
            val name = iconName(style, marker.icon)
            markers.add(
                Feature.fromGeometry(
                    Point.fromLngLat(marker.position.longitude, marker.position.latitude),
                    JsonObject().apply {
                        addProperty("id", marker.id)
                        addProperty("kind", "marker")
                        addProperty("icon", name)
                        addProperty("anchor", marker.anchorValue)
                        addProperty("rotation", marker.rotation.toDouble())
                        addProperty("alpha", marker.alpha.toDouble())
                    },
                ),
            )
        }

        style.getSourceAs<GeoJsonSource>(FILL_SOURCE)?.setGeoJson(FeatureCollection.fromFeatures(fills))
        style.getSourceAs<GeoJsonSource>(LINE_SOURCE)?.setGeoJson(FeatureCollection.fromFeatures(lines))
        style.getSourceAs<GeoJsonSource>(MARKER_SOURCE)?.setGeoJson(FeatureCollection.fromFeatures(markers))
    }

    private fun addDashed(style: Style, polyline: Polyline, points: List<LatLng>, pattern: List<PatternItem>) {
        val id = polyline.id
        val source = "$DASH_SOURCE_PREFIX$id"
        val layer = "$DASH_LAYER_PREFIX$id"
        val feature = Feature.fromGeometry(
            LineString.fromLngLats(points.map { Point.fromLngLat(it.longitude, it.latitude) }),
            JsonObject().apply { addProperty("id", id); addProperty("kind", "polyline") },
        )
        style.addSource(GeoJsonSource(source, feature))
        val width = polyline.width.coerceAtLeast(1f)
        // Dash arrays are in line-width units; Google's pattern is in pixels.
        val dash = dashArrayFor(pattern.map { it.length }, width).toTypedArray()
        val dashLayer = LineLayer(layer, source).withProperties(
            PropertyFactory.lineColor(cssColor(polyline.color)),
            PropertyFactory.lineOpacity(alphaOf(polyline.color)),
            PropertyFactory.lineWidth(width),
            PropertyFactory.lineCap(Property.LINE_CAP_BUTT),
            PropertyFactory.lineDasharray(dash),
        )
        val below = style.layers.firstOrNull { it.id == MARKER_LAYER }?.id
        if (below != null) style.addLayerBelow(dashLayer, below) else style.addLayer(dashLayer)
        dashed[id] = polyline
    }

    private fun removeDashed(style: Style) {
        for (id in dashed.keys.toList()) {
            style.removeLayer("$DASH_LAYER_PREFIX$id")
            style.removeSource("$DASH_SOURCE_PREFIX$id")
        }
        dashed.clear()
    }

    private fun iconName(style: Style, icon: BitmapDescriptor): String {
        val name = when {
            icon.bitmap != null -> "siro-bitmap-${System.identityHashCode(icon.bitmap)}"
            icon.resourceId != null -> "siro-resource-${icon.resourceId}"
            icon.assetPath != null -> "siro-asset-${icon.assetPath}"
            else -> "siro-pin-${icon.hue ?: BitmapDescriptorFactory.HUE_RED}"
        }
        if (addedImages.add(name)) {
            style.addImage(name, decode(icon), false)
        }
        return name
    }

    /** The bitmap behind an icon. Resources and assets are read through the map's context. */
    private fun decode(icon: BitmapDescriptor): Bitmap {
        icon.bitmap?.let { return it }
        icon.resourceId?.let { id ->
            return requireNotNull(BitmapFactory.decodeResource(owner.context.resources, id)) {
                "Resource $id is not an image."
            }
        }
        icon.assetPath?.let { path ->
            return owner.context.assets.open(path).use { stream ->
                requireNotNull(BitmapFactory.decodeStream(stream)) { "Asset $path is not an image." }
            }
        }
        return defaultPinBitmap(icon.hue ?: BitmapDescriptorFactory.HUE_RED)
    }

    /**
     * The object ids of everything drawn under [screen], topmost first.
     *
     * Each layer is queried on its own, in drawing order: markers, dashed lines, lines, fills.
     * One query over all layers returns hits in no fixed order, so a fill could win over a route.
     */
    fun hitTest(screen: PointF, map: org.maplibre.android.maps.MapLibreMap): List<Pair<String, String>> {
        val layers = listOf(MARKER_LAYER) + dashed.keys.map { "$DASH_LAYER_PREFIX$it" } + listOf(LINE_LAYER, FILL_LAYER)
        return layers.flatMap { layer ->
            map.queryRenderedFeatures(screen, layer).mapNotNull { feature ->
                val props = feature.properties() ?: return@mapNotNull null
                val id = props.get("id")?.asString ?: return@mapNotNull null
                val kind = props.get("kind")?.asString ?: return@mapNotNull null
                kind to id
            }
        }
    }

    private fun polygonFeature(id: String, kind: String, rings: List<List<LatLng>>, color: Int): Feature =
        Feature.fromGeometry(
            // GeoJSON polygon rings must be closed: the first point repeats at the end.
            GeoPolygon.fromLngLats(rings.map { ring -> closed(ring).map { Point.fromLngLat(it.longitude, it.latitude) } }),
            JsonObject().apply {
                addProperty("id", id)
                addProperty("kind", kind)
                addProperty("color", cssColor(color))
                addProperty("opacity", alphaOf(color).toDouble())
            },
        )

    private fun closed(ring: List<LatLng>): List<LatLng> =
        if (ring.first() == ring.last()) ring else ring + ring.first()

    private fun lineFeature(id: String, kind: String, points: List<LatLng>, color: Int, width: Number): Feature =
        Feature.fromGeometry(
            LineString.fromLngLats(points.map { Point.fromLngLat(it.longitude, it.latitude) }),
            JsonObject().apply {
                addProperty("id", id)
                addProperty("kind", kind)
                addProperty("color", cssColor(color))
                addProperty("opacity", alphaOf(color).toDouble())
                addProperty("width", width.toDouble())
            },
        )

    companion object {
        const val FILL_SOURCE = "siro-fill-source"
        const val FILL_LAYER = "siro-fill-layer"
        const val LINE_SOURCE = "siro-line-source"
        const val LINE_LAYER = "siro-line-layer"
        const val MARKER_SOURCE = "siro-marker-source"
        const val MARKER_LAYER = "siro-marker-layer"
        const val DASH_SOURCE_PREFIX = "siro-dash-source-"
        const val DASH_LAYER_PREFIX = "siro-dash-layer-"
    }
}

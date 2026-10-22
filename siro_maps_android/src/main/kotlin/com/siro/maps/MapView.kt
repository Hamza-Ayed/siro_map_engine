package com.siro.maps

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.util.AttributeSet
import android.view.Gravity
import android.view.View.GONE
import android.view.View.VISIBLE
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.TextView
import org.maplibre.android.MapLibre
import org.maplibre.android.maps.MapLibreMap

/**
 * A view that shows a map, as Google's `MapView`.
 *
 * Forward the host's lifecycle to it: [onCreate], [onStart], [onResume], [onPause],
 * [onStop], [onLowMemory], [onSaveInstanceState] and [onDestroy]. Get the map with
 * [getMapAsync].
 *
 * The map uses Siro's own style, [GoogleMap.DAY_STYLE_URL] by default. It shows the
 * attribution Siro's data needs in place of Google's logo.
 */
class MapView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {

    private val engineView: org.maplibre.android.maps.MapView
    private var options: GoogleMapOptions? = null
    private val waiting = mutableListOf<OnMapReadyCallback>()
    private var googleMap: GoogleMap? = null
    private val myLocationButton = ImageButton(context).apply {
        setImageResource(android.R.drawable.ic_menu_mylocation)
        setColorFilter(Color.DKGRAY)
        background = android.graphics.drawable.GradientDrawable().apply {
            shape = android.graphics.drawable.GradientDrawable.OVAL
            setColor(Color.WHITE)
        }
        elevation = 6f * resources.displayMetrics.density
        visibility = GONE
        setOnClickListener { googleMap?.onMyLocationButtonClicked() }
    }

    init {
        MapLibre.getInstance(context)
        engineView = org.maplibre.android.maps.MapView(context)
        addView(
            engineView,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        val density = resources.displayMetrics.density
        val size = (44 * resources.displayMetrics.density).toInt()
        val margin = (12 * resources.displayMetrics.density).toInt()
        addView(
            myLocationButton,
            // Bottom end, so it stays clear of the top controls and the attribution.
            FrameLayout.LayoutParams(size, size, Gravity.BOTTOM or Gravity.END).apply { setMargins(margin, margin, margin, margin) },
        )
        addView(
            TextView(context).apply {
                text = ATTRIBUTION
                textSize = 10f
                setTextColor(Color.DKGRAY)
                setBackgroundColor(0xB3FFFFFF.toInt())
                setPadding(
                    (4 * density).toInt(),
                    (2 * density).toInt(),
                    (4 * density).toInt(),
                    (2 * density).toInt(),
                )
            },
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM or Gravity.START,
            ),
        )
    }

    /** Creates a map with [options], as Google's `MapView(Context, GoogleMapOptions)`. */
    constructor(context: Context, options: GoogleMapOptions?) : this(context) {
        this.options = options
    }

    /** Shows or hides the my-location button. Called by the map. */
    internal fun setMyLocationButtonVisible(visible: Boolean) {
        myLocationButton.visibility = if (visible) VISIBLE else GONE
    }

    /** Calls [callback] with the map once it is ready, on the main thread. */
    fun getMapAsync(callback: OnMapReadyCallback) {
        val ready = googleMap
        if (ready != null) {
            callback.onMapReady(ready)
            return
        }
        waiting.add(callback)
        if (waiting.size == 1) {
            engineView.getMapAsync { engine -> onEngineReady(engine) }
        }
    }

    private fun onEngineReady(engine: MapLibreMap) {
        engine.uiSettings.setAttributionEnabled(false)
        engine.uiSettings.setLogoEnabled(false)
        val map = GoogleMap(engine, context, this)
        googleMap = map
        // Marker drags are driven by touches the map view has not consumed yet.
        engineView.setOnTouchListener { _, event -> map.onDragTouch(event) }
        options?.let { applyOptions(map, it) }
        map.setMapStyle(null)
        val callbacks = waiting.toList()
        waiting.clear()
        callbacks.forEach { it.onMapReady(map) }
    }

    private fun applyOptions(map: GoogleMap, options: GoogleMapOptions) {
        options.camera?.let { map.moveCamera(CameraUpdateFactory.newCameraPosition(it)) }
        options.mapType?.let { map.mapType = it }
        val ui = map.uiSettings
        options.compassEnabled?.let { ui.isCompassEnabled = it }
        options.rotateGesturesEnabled?.let { ui.isRotateGesturesEnabled = it }
        options.scrollGesturesEnabled?.let { ui.isScrollGesturesEnabled = it }
        options.tiltGesturesEnabled?.let { ui.isTiltGesturesEnabled = it }
        options.zoomGesturesEnabled?.let { ui.isZoomGesturesEnabled = it }
        options.zoomControlsEnabled?.let { ui.isZoomControlsEnabled = it }
        options.mapToolbarEnabled?.let { ui.isMapToolbarEnabled = it }
        options.minZoom?.let { map.setMinZoomPreference(it) }
        options.maxZoom?.let { map.setMaxZoomPreference(it) }
        options.cameraTargetBounds?.let { map.setLatLngBoundsForCameraTarget(it) }
    }

    fun onCreate(savedInstanceState: Bundle?) = engineView.onCreate(savedInstanceState)

    fun onStart() = engineView.onStart()

    fun onResume() = engineView.onResume()

    fun onPause() = engineView.onPause()

    fun onStop() = engineView.onStop()

    fun onLowMemory() = engineView.onLowMemory()

    fun onSaveInstanceState(outState: Bundle) = engineView.onSaveInstanceState(outState)

    fun onDestroy() = engineView.onDestroy()

    private companion object {
        const val ATTRIBUTION = "© OpenStreetMap contributors · Siro Maps"
    }
}

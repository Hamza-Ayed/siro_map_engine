package com.siro.maps

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.util.AttributeSet
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
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
    private val waiting = mutableListOf<OnMapReadyCallback>()
    private var googleMap: GoogleMap? = null

    init {
        MapLibre.getInstance(context)
        engineView = org.maplibre.android.maps.MapView(context)
        addView(
            engineView,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        val density = resources.displayMetrics.density
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
        map.setMapStyle(null)
        val callbacks = waiting.toList()
        waiting.clear()
        callbacks.forEach { it.onMapReady(map) }
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

package com.siro.maps

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Shows the info window of one marker at a time, above the marker, as Google's SDK does.
 *
 * The window follows its marker when the camera moves. A tap on it calls
 * [GoogleMap.OnInfoWindowClickListener].
 */
internal class InfoWindows(private val owner: GoogleMap) {

    var adapter: GoogleMap.InfoWindowAdapter? = null

    private var shownMarker: Marker? = null
    private var shownView: View? = null

    fun show(marker: Marker) {
        // Opening another window closes the open one; rebuilding the same one does not.
        val previous = shownMarker
        removeShown()
        if (previous != null && previous != marker) owner.notifyInfoWindowClose(previous)
        val view = viewFor(marker)
        view.setOnClickListener { owner.notifyInfoWindowClick(marker) }
        view.setOnLongClickListener {
            owner.notifyInfoWindowLongClick(marker)
            true
        }
        owner.hostView.addView(
            view,
            FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT),
        )
        shownMarker = marker
        shownView = view
        // The size is known only after layout, so place the window once it has one.
        view.post { place() }
    }

    fun isShown(marker: Marker): Boolean = shownMarker == marker

    fun hide(marker: Marker) {
        if (shownMarker == marker) hideAll()
    }

    fun hideAll() {
        val closing = shownMarker
        removeShown()
        closing?.let { owner.notifyInfoWindowClose(it) }
    }

    private fun removeShown() {
        shownView?.let { owner.hostView.removeView(it) }
        shownView = null
        shownMarker = null
    }

    /** Rebuilds the window when the title or snippet of the shown [marker] changes. */
    fun refreshIfShown(marker: Marker) {
        if (shownMarker == marker) show(marker)
    }

    /** Keeps the window above its marker. Called on every camera move. */
    fun onCameraChanged() = place()

    private fun place() {
        val marker = shownMarker ?: return
        val view = shownView ?: return
        val screen = owner.engine.projection.toScreenLocation(marker.position.toEngine())
        val gap = view.resources.displayMetrics.density * MARKER_GAP_DP
        view.x = screen.x - view.width / 2f
        view.y = screen.y - view.height - gap
    }

    private fun viewFor(marker: Marker): View {
        val custom = adapter?.getInfoWindow(marker) ?: adapter?.getInfoContents(marker)
        return custom ?: defaultView(marker)
    }

    private fun defaultView(marker: Marker): View {
        val context = owner.hostView.context
        val density = context.resources.displayMetrics.density
        val padding = (8 * density).toInt()
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, padding, padding, padding)
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = 6 * density
            }
            marker.title?.let { title ->
                addView(TextView(context).apply {
                    text = title
                    textSize = 14f
                    setTextColor(Color.BLACK)
                    setTypeface(null, Typeface.BOLD)
                })
            }
            marker.snippet?.let { snippet ->
                addView(TextView(context).apply {
                    text = snippet
                    textSize = 12f
                    setTextColor(0xFF555555.toInt())
                })
            }
        }
    }

    private companion object {
        const val MARKER_GAP_DP = 40f
    }
}

package com.siro.maps

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment

/**
 * A fragment that shows a [MapView], as Google's `SupportMapFragment`.
 *
 * Call [getMapAsync] when the fragment is set up; the map is created with the fragment.
 */
class SupportMapFragment : Fragment() {

    private var mapView: MapView? = null
    private var options: GoogleMapOptions? = null
    private val waiting = mutableListOf<OnMapReadyCallback>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val view = MapView(requireContext(), options)
        view.onCreate(savedInstanceState)
        mapView = view
        waiting.forEach { view.getMapAsync(it) }
        waiting.clear()
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? = mapView?.apply {
        // The map fills the container, as it does in Google's SupportMapFragment.
        layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
    }

    /** Calls [callback] with the map once it is ready. */
    fun getMapAsync(callback: OnMapReadyCallback) {
        val view = mapView
        if (view != null) view.getMapAsync(callback) else waiting.add(callback)
    }

    override fun onStart() {
        super.onStart()
        mapView?.onStart()
    }

    override fun onResume() {
        super.onResume()
        mapView?.onResume()
    }

    override fun onPause() {
        mapView?.onPause()
        super.onPause()
    }

    override fun onStop() {
        mapView?.onStop()
        super.onStop()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView?.onLowMemory()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        mapView?.onSaveInstanceState(outState)
    }

    override fun onDestroy() {
        mapView?.onDestroy()
        super.onDestroy()
    }

    companion object {
        /** A fragment with the default options, as Google's `SupportMapFragment.newInstance()`. */
        @JvmStatic
        fun newInstance(): SupportMapFragment = SupportMapFragment()

        /** A fragment with [options], as Google's `SupportMapFragment.newInstance(GoogleMapOptions)`. */
        @JvmStatic
        fun newInstance(options: GoogleMapOptions?): SupportMapFragment =
            SupportMapFragment().also { it.options = options }
    }
}

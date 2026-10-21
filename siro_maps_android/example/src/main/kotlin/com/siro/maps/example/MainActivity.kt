package com.siro.maps.example

import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.Toast
import androidx.fragment.app.FragmentActivity
import com.siro.maps.BitmapDescriptorFactory
import com.siro.maps.CameraPosition
import com.siro.maps.CameraUpdateFactory
import com.siro.maps.CircleOptions
import com.siro.maps.GoogleMap
import com.siro.maps.LatLng
import com.siro.maps.MapStyleOptions
import com.siro.maps.MarkerOptions
import com.siro.maps.OnMapReadyCallback
import com.siro.maps.PatternItem
import com.siro.maps.PolygonOptions
import com.siro.maps.PolylineOptions
import com.siro.maps.SupportMapFragment

/**
 * The SDK used the way a Google Maps app uses it: a fragment, markers, lines, a polygon,
 * a circle, taps, info windows, and the day, night and 3D styles.
 */
class MainActivity : FragmentActivity(), OnMapReadyCallback {

    private var map: GoogleMap? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val holder = FrameLayout(this).apply { id = View.generateViewId() }
        setContentView(holder)

        val mapFragment = SupportMapFragment()
        // commitNow so the map view is in place before the controls go on top of it.
        supportFragmentManager.beginTransaction().replace(holder.id, mapFragment).commitNow()
        mapFragment.getMapAsync(this)

        val controls = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(button("Day") { map?.apply { mapType = GoogleMap.MAP_TYPE_NORMAL; setMapStyle(null) } })
            addView(button("Night") { map?.setMapStyle(MapStyleOptions.fromSiroStyleUrl(GoogleMap.NIGHT_STYLE_URL)) })
            addView(button("3D") { map?.mapType = GoogleMap.MAP_TYPE_TERRAIN })
        }
        holder.addView(controls, FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.TOP or Gravity.END))
    }

    override fun onMapReady(map: GoogleMap) {
        this.map = map
        map.moveCamera(CameraUpdateFactory.newCameraPosition(CameraPosition.fromLatLngZoom(AMMAN, 12f)))

        map.addMarker(MarkerOptions().position(AMMAN).title("Amman").snippet("Capital of Jordan"))
        map.addMarker(
            MarkerOptions()
                .position(ZARQA)
                .title("Zarqa")
                .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE)),
        )
        map.addPolyline(
            PolylineOptions()
                .add(AMMAN, ZARQA)
                .width(8f)
                .color(0xFF1976D2.toInt())
                .pattern(listOf(PatternItem.Dash(20f), PatternItem.Gap(10f)))
                .clickable(true),
        )
        map.addPolygon(
            PolygonOptions()
                .add(LatLng(31.97, 35.85), LatLng(31.99, 35.92), LatLng(31.94, 35.93), LatLng(31.93, 35.86))
                .fillColor(0x4400AA00)
                .strokeColor(0xFF00AA00.toInt())
                .strokeWidth(3f)
                .clickable(true),
        )
        map.addCircle(
            CircleOptions()
                .center(AMMAN)
                .radius(2000.0)
                .fillColor(0x22FF0000)
                .strokeColor(0xFFFF0000.toInt())
                .strokeWidth(3f)
                .clickable(true),
        )

        map.setOnMapClickListener { toast("%.4f, %.4f".format(it.latitude, it.longitude)) }
        map.setOnMarkerClickListener { marker ->
            toast(marker.title ?: "Marker")
            false // Not consumed, so the info window opens, as in Google's SDK.
        }
        map.setOnInfoWindowClickListener { marker -> toast("Info: ${marker.title}") }
        map.setOnPolylineClickListener { toast("Route") }
        map.setOnPolygonClickListener { toast("Polygon") }
        map.setOnCircleClickListener { toast("Circle") }
    }

    private fun button(label: String, onClick: () -> Unit): Button =
        Button(this).apply {
            text = label
            setOnClickListener { onClick() }
        }

    private fun toast(text: String) = Toast.makeText(this, text, Toast.LENGTH_SHORT).show()

    private companion object {
        val AMMAN = LatLng(31.9539, 35.9106)
        val ZARQA = LatLng(32.0728, 36.0880)
    }
}

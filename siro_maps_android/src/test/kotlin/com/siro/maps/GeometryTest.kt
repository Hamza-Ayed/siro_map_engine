package com.siro.maps

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

class GeometryTest {

    private val amman = LatLng(31.9539, 35.9106)

    /** Great-circle distance in metres, as the test's independent reference. */
    private fun haversine(a: LatLng, b: LatLng): Double {
        val r = 6_371_000.0
        val dLat = Math.toRadians(b.latitude - a.latitude)
        val dLng = Math.toRadians(b.longitude - a.longitude)
        val h = sin(dLat / 2).pow(2) + cos(Math.toRadians(a.latitude)) * cos(Math.toRadians(b.latitude)) * sin(dLng / 2).pow(2)
        return 2 * r * asin(sqrt(h))
    }

    @Test
    fun geodesicCircle_everyPointIsTheRadiusAway() {
        val ring = geodesicCircle(amman, 2000.0, points = 48)
        assertEquals(48, ring.size)
        ring.forEach { assertEquals(2000.0, haversine(amman, it), 2.0) }
    }

    @Test
    fun geodesicCircle_keepsItsSizeInMetresAtHighLatitude() {
        val north = LatLng(60.0, 10.0)
        geodesicCircle(north, 5000.0).forEach { assertEquals(5000.0, haversine(north, it), 5.0) }
    }

    @Test
    fun geodesicLine_keepsEndpointsAndAddsPointsOnLongSegments() {
        val amanZarqa = listOf(amman, LatLng(32.0728, 36.088))
        val line = geodesicLine(amanZarqa, stepMeters = 5_000.0)
        assertEquals(amman, line.first())
        assertEquals(amanZarqa.last().latitude, line.last().latitude, 1e-9)
        assertTrue("expected intermediate points, got ${line.size}", line.size > 2)
    }

    @Test
    fun cssColor_isHexWithoutAlpha() {
        assertEquals("#112233", cssColor(0xFF112233.toInt()))
        assertEquals("#112233", cssColor(0x80112233.toInt()))
    }

    @Test
    fun alphaOf_readsTheTopByte() {
        assertEquals(1f, alphaOf(0xFF000000.toInt()), 1e-6f)
        assertEquals(128f / 255f, alphaOf(0x80000000.toInt()), 1e-6f)
        assertEquals(0f, alphaOf(0x00FFFFFF), 1e-6f)
    }

    @Test
    fun dashArrayFor_dividesByWidthAndDoublesOddCounts() {
        assertEquals(listOf(2f, 1f), dashArrayFor(listOf(20f, 10f), 10f))
        // An odd-length pattern is doubled, so the on and off segments line up again.
        assertEquals(listOf(2f, 2f), dashArrayFor(listOf(20f), 10f))
        assertTrue(dashArrayFor(emptyList(), 5f).isEmpty())
    }

    @Test
    fun dashArrayFor_dotsGetAMinimumLength() {
        val dash = dashArrayFor(listOf(0f, 0f), 2f)
        assertTrue(dash.all { it > 0f })
    }

    @Test
    fun latLng_rejectsLatitudesOutsideTheGlobe() {
        assertThrows(IllegalArgumentException::class.java) { LatLng(91.0, 0.0) }
        assertThrows(IllegalArgumentException::class.java) { LatLng(-91.0, 0.0) }
    }

    @Test
    fun latLngBounds_containsItsInteriorOnly() {
        val bounds = LatLngBounds(LatLng(31.0, 35.0), LatLng(32.0, 36.0))
        assertTrue(bounds.contains(amman))
        assertFalse(bounds.contains(LatLng(33.0, 35.5)))
    }

    @Test
    fun defaultMarker_hueMustBeOnTheCircle() {
        assertThrows(IllegalArgumentException::class.java) { BitmapDescriptorFactory.defaultMarker(361f) }
        assertThrows(IllegalArgumentException::class.java) { BitmapDescriptorFactory.defaultMarker(-1f) }
    }
}

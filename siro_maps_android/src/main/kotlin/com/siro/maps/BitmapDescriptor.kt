package com.siro.maps

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path

/** An icon for a [Marker], as in the Google Maps SDK. Build it with [BitmapDescriptorFactory]. */
class BitmapDescriptor internal constructor(
    internal val hue: Float?,
    internal val bitmap: Bitmap?,
) {
    override fun equals(other: Any?): Boolean =
        other is BitmapDescriptor && other.hue == hue && other.bitmap === bitmap

    override fun hashCode(): Int = 31 * (hue?.hashCode() ?: 0) + System.identityHashCode(bitmap)
}

/** Creates [BitmapDescriptor]s, as in the Google Maps SDK. */
object BitmapDescriptorFactory {
    const val HUE_RED = 0f
    const val HUE_ORANGE = 30f
    const val HUE_YELLOW = 60f
    const val HUE_GREEN = 120f
    const val HUE_CYAN = 180f
    const val HUE_AZURE = 210f
    const val HUE_BLUE = 240f
    const val HUE_VIOLET = 270f
    const val HUE_MAGENTA = 300f
    const val HUE_ROSE = 330f

    /** The default pin, red. */
    @JvmStatic
    fun defaultMarker(): BitmapDescriptor = BitmapDescriptor(HUE_RED, null)

    /** The default pin tinted by [hue], in degrees from 0 to 360. */
    @JvmStatic
    fun defaultMarker(hue: Float): BitmapDescriptor {
        require(hue in 0f..360f) { "hue must be in 0..360" }
        return BitmapDescriptor(hue, null)
    }

    /** An icon from a bitmap. */
    @JvmStatic
    fun fromBitmap(bitmap: Bitmap): BitmapDescriptor = BitmapDescriptor(null, bitmap)
}

/** Draws the default pin in the given hue. Used by [BitmapDescriptor] when no bitmap is set. */
internal fun defaultPinBitmap(hue: Float): Bitmap {
    val width = 48
    val height = 64
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.HSVToColor(floatArrayOf(hue, 0.85f, 0.9f))
    }
    val head = width / 2f
    val path = Path().apply {
        moveTo(head, height - 2f)
        cubicTo(head - 4f, height - 20f, 2f, height * 0.55f, 2f, head)
        arcTo(2f, 2f, width - 2f, width - 2f, 180f, 180f, false)
        cubicTo(width - 2f, height * 0.55f, head + 4f, height - 20f, head, height - 2f)
        close()
    }
    canvas.drawPath(path, paint)
    canvas.drawCircle(head, head, 7f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE })
    return bitmap
}

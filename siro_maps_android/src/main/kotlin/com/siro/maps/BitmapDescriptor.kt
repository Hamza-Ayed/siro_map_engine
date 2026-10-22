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
    internal val resourceId: Int? = null,
    internal val assetPath: String? = null,
    internal val filePath: String? = null,
    internal val privateFileName: String? = null,
) {
    override fun equals(other: Any?): Boolean =
        other is BitmapDescriptor &&
            other.hue == hue &&
            other.bitmap === bitmap &&
            other.resourceId == resourceId &&
            other.assetPath == assetPath &&
            other.filePath == filePath &&
            other.privateFileName == privateFileName

    override fun hashCode(): Int =
        31 * (31 * (31 * (hue?.hashCode() ?: 0) + System.identityHashCode(bitmap)) + (resourceId ?: 0)) +
            (assetPath?.hashCode() ?: 0) + 17 * (filePath?.hashCode() ?: 0) + 19 * (privateFileName?.hashCode() ?: 0)
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

    /** An icon from a drawable or mipmap resource, as Google's `fromResource`. */
    @JvmStatic
    fun fromResource(resourceId: Int): BitmapDescriptor = BitmapDescriptor(null, null, resourceId = resourceId)

    /** An icon from an image file at an absolute [path], as Google's `fromPath`. */
    @JvmStatic
    fun fromPath(absolutePath: String): BitmapDescriptor = BitmapDescriptor(null, null, filePath = absolutePath)

    /** An icon from a file in the app's private storage, as Google's `fromFile`. */
    @JvmStatic
    fun fromFile(fileName: String): BitmapDescriptor = BitmapDescriptor(null, null, privateFileName = fileName)

    /** An icon from an image in the app's assets, such as `"icons/car.png"`, as Google's `fromAsset`. */
    @JvmStatic
    fun fromAsset(path: String): BitmapDescriptor = BitmapDescriptor(null, null, assetPath = path)
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

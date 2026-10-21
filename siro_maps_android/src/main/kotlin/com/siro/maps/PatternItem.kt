package com.siro.maps

/** One item of a polyline's dash pattern, as in the Google Maps SDK. */
sealed class PatternItem(internal val length: Float) {
    /** A dot: a dash of almost no length. */
    object Dot : PatternItem(0f)

    /** A dash of [length] pixels. */
    class Dash(length: Float) : PatternItem(length)

    /** A gap of [length] pixels. */
    class Gap(length: Float) : PatternItem(length)
}

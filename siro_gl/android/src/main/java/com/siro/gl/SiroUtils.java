package com.siro.gl;

import android.content.Context;
import org.maplibre.android.MapLibre;

abstract class SiroUtils {
  private static final String TAG = "SiroMapController";

  static MapLibre getMapLibre(Context context) {
    return MapLibre.getInstance(context);
  }
}

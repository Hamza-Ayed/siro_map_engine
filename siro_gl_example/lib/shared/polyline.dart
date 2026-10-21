import 'package:siro_gl/siro_gl.dart';

/// Decodes a Google encoded polyline (precision 5) into coordinates.
///
/// Our routing API returns its geometry in this format, the same one the
/// Google Directions API uses, so the decoder works for both.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  int readValue() {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    lat += readValue();
    lng += readValue();
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

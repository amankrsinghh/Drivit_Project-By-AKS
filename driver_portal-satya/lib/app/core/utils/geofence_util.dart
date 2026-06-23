class GeofenceUtil {
  static const List<Map<String, double>> chennaiPolygon = [
    {'lat': 12.824958370672775, 'lng': 80.2429907550401},
    {'lat': 12.90394878589996, 'lng': 80.06652287419979},
    {'lat': 12.984252441867923, 'lng': 80.10772160124424},
    {'lat': 13.022387599307189, 'lng': 80.05828312879093},
    {'lat': 13.23503347281619, 'lng': 80.15784671914828},
    {'lat': 13.23302824185591, 'lng': 80.27114321852045},
    {'lat': 13.269119871915699, 'lng': 80.29105593659193}
  ];

  static bool isInsideChennai(double lat, double lng) {
    if (lat == 0 || lng == 0) return false;

    bool inside = false;
    for (int i = 0, j = chennaiPolygon.length - 1; i < chennaiPolygon.length; j = i++) {
      double xi = chennaiPolygon[i]['lat']!, yi = chennaiPolygon[i]['lng']!;
      double xj = chennaiPolygon[j]['lat']!, yj = chennaiPolygon[j]['lng']!;

      bool intersect = ((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}

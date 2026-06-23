import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_service.dart';

class RoutingService {
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final details = await getRouteDetails(start, end);
    return details['points'] as List<LatLng>? ?? [];
  }

  static Future<Map<String, dynamic>> getRouteDetails(LatLng start, LatLng end) async {
    if (start.latitude == 0 || end.latitude == 0) return {};

    final apiKey = ApiService.googleMapsApiKey;
    if (apiKey == null || apiKey.isEmpty) {
        return {'points': [start, end], 'distance': '0 km', 'duration': 0};
    }

    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polyline = route['overview_polyline']['points'];
          final points = _decodePolyline(polyline);
          
          final leg = route['legs'][0];
          final distance = leg['distance']['text'];
          
          final int seconds = leg['duration']['value'];
          final int minutes = (seconds / 60).ceil();

          return {
            'points': points,
            'distance': distance,
            'duration': minutes,
          };
        }
      }
    } catch (e) {
      print("RoutingService: Error with Google Directions: $e");
    }

    return {'points': [start, end], 'distance': '0 km', 'duration': 0};
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}

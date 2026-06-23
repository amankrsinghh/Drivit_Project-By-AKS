import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/middleware/auth_middleware.dart';
import '../services/api_service.dart';

class RouteInfo {
  final List<LatLng> points;
  final double distance; // meters
  final double duration; // seconds

  RouteInfo({
    required this.points,
    required this.distance,
    required this.duration,
  });
}

class RoutingService {
  static Future<RouteInfo?> getRoute(LatLng start, LatLng end) async {
    if (start.latitude == 0 || end.latitude == 0) return null;

    final apiKey = ApiService.googleMapsApiKey ?? AuthStore.googleMapsApiKey;
    if (apiKey == null || apiKey.isEmpty) {
        // Fallback to straight line if no API key
        return RouteInfo(
          points: [start, end],
          distance: 1000,
          duration: 60,
        );
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
          final distance = (route['legs'][0]['distance']['value'] as num).toDouble();
          final duration = (route['legs'][0]['duration']['value'] as num).toDouble();
          
          final points = _decodePolyline(polyline);
          
          if (points.length >= 2) {
            return RouteInfo(
              points: points,
              distance: distance,
              duration: duration,
            );
          }
        }
      }
    } catch (e) {
      print("RoutingService: Error with Google Directions: $e");
    }

    return RouteInfo(
      points: [start, end],
      distance: 1000,
      duration: 60,
    );
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

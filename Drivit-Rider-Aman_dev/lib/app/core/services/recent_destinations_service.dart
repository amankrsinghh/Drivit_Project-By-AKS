import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentDestination {
  final String name;
  final double lat;
  final double lng;

  RecentDestination({required this.name, required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lng': lng};

  factory RecentDestination.fromJson(Map<String, dynamic> json) =>
      RecentDestination(
        name: json['name'] ?? '',
        lat: (json['lat'] ?? 0).toDouble(),
        lng: (json['lng'] ?? 0).toDouble(),
      );
}

class RecentDestinationsService {
  static const String _key = 'recent_destinations';
  static const int _maxItems = 3;

  static Future<List<RecentDestination>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => RecentDestination.fromJson(e)).toList();
  }

  static Future<void> add(RecentDestination destination) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getRecent();

    // Remove duplicate by name
    existing.removeWhere((d) => d.name == destination.name);

    // Add to front
    existing.insert(0, destination);

    // Keep only last 3
    final trimmed = existing.take(_maxItems).toList();

    final raw = jsonEncode(trimmed.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}

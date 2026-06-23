import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/middleware/auth_middleware.dart';
// import '../../../core/middleware/auth_middleware.dart';

class PlaceSuggestion {
  final String displayName;
  final LatLng latLng;

  PlaceSuggestion({required this.displayName, required this.latLng});

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    // If using Google Places API
    if (json.containsKey('description') && json.containsKey('place_id')) {
        return PlaceSuggestion(
          displayName: json['description'],
          latLng: const LatLng(0,0), // Need to fetch latlng for selection
        );
    }
    // Backward compatibility for old logic if needed, but we'll use Google now
    return PlaceSuggestion(
      displayName: (json['display_name'] ?? '').toString(),
      latLng: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
    );
  }
}

class MapController extends GetxController {
  // The actual GPS location of the user (real-time)
  final userPosition = Rxn<LatLng>();
  // The location currently being 'picked' on the map center
  final pickedLocation = Rxn<LatLng>();

  // Backwards compatibility for UI
  Rxn<LatLng> get currentPosition => pickedLocation;
 
  final isLoadingLocation = false.obs;
  final followUser = true.obs;

  final currentAddressTitle = "Confirm Location".obs;
  final currentAddressSubtitle = "Fetching address...".obs;
  final isLoadingAddress = false.obs;
  final isLoadingCoordinates = false.obs;
 
  final locationError = RxnString();

  // Search
  final searchTextController = TextEditingController();
  final isSearching = false.obs;
  final suggestions = <PlaceSuggestion>[].obs;

  Timer? _searchDebounce;
  Timer? _moveDebounce;
  DateTime? _lastProgrammaticMove;
  LatLng? _lastAddressSentPos;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _moveDebounce?.cancel();
    _positionStream?.cancel();
    super.onClose();
  }

  // ---------- Map move safe ----------
  void moveSafe(GoogleMapController? mc, LatLng pos, double zoom) {
    if (mc == null) return;
    try {
      _lastProgrammaticMove = DateTime.now();
      mc.animateCamera(CameraUpdate.newLatLngZoom(pos, zoom));
    } catch (e) {
      _lastProgrammaticMove = null;
      debugPrint("Map move failed: $e");
    }
  }

  StreamSubscription<Position>? _positionStream;
  bool _isFirstFix = true;

  // ---------- Current Location (REAL) ----------
  Future<void> getCurrentLocation({GoogleMapController? mc}) async {
    try {
      if (isClosed) return;
      isLoadingLocation.value = true;
      followUser.value = true; // Set followUser to true initially

      // 1. Service check
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        isLoadingLocation.value = false;
        locationError.value = "Location service is OFF";
        return;
      }

      // 2. Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        isLoadingLocation.value = false;
        locationError.value = "Location permission denied";
        return;
      }

      // 3. Fast fallback to last known location (Instant 1-2s load)
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          final pos = LatLng(lastPos.latitude, lastPos.longitude);
          userPosition.value = pos;
          if (pickedLocation.value == null || _isFirstFix) {
            pickedLocation.value = pos;
          }
          if (followUser.value && mc != null) moveSafe(mc, pos, 15.5);
          _fetchAddress(pos);
        }
      } catch (e) {
        debugPrint("Rider: Last known position failed: $e");
      }

      // 4. Aggressive initial fix (Same as working Driver app)
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
        ).timeout(const Duration(seconds: 10));
        
        final pos = LatLng(p.latitude, p.longitude);
        userPosition.value = pos;
        if (pickedLocation.value == null || _isFirstFix) {
          pickedLocation.value = pos;
        }
        if (followUser.value && mc != null) moveSafe(mc, pos, 15.5); // Respect followUser
        _fetchAddress(pos);
      } catch (e) {
        debugPrint("Rider: Initial aggressive fix failed: $e");
      }

      // 4. Start real-time stream
      _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen((Position p) {
        if (isClosed) return;
        final pos = LatLng(p.latitude, p.longitude);
        userPosition.value = pos;

        if (pickedLocation.value == null || (followUser.value && _isFirstFix)) {
           pickedLocation.value = pos;
        }
 
        if (followUser.value && mc != null) { // Only animate if followUser is true
          moveSafe(mc, pos, 15.5);
        }
        
        if (_isFirstFix) _isFirstFix = false; // Progress past first fix once data arrives
        
        // Only fetch address if moved significantly to avoid flooding
        bool fetchAddr = false;
        if (_lastAddressSentPos == null) {
          fetchAddr = true;
        } else {
          final d = Geolocator.distanceBetween(
            _lastAddressSentPos!.latitude, _lastAddressSentPos!.longitude,
            pos.latitude, pos.longitude
          );
          if (d > 10) fetchAddr = true;
        }

        if (fetchAddr) {
          _lastAddressSentPos = pos;
          _fetchAddress(pos);
        }
      }, onError: (e) {
        debugPrint("Rider: Stream error: $e");
      });

    } catch (e) {
      debugPrint("Rider: Global location error: $e");
      locationError.value = e.toString();
    } finally {
      if (!isClosed) isLoadingLocation.value = false;
    }
  }

  void moveMapToCurrent(GoogleMapController? mc) {
    if (mc == null) return;
    followUser.value = true;
    final pos = userPosition.value ?? pickedLocation.value;
    if (pos != null) {
      moveSafe(mc, pos, 15.5);
      // Explicitly fetch address for this location to ensure it's fresh
      _fetchAddress(pos);
    } else {
      getCurrentLocation(mc: mc);
    }
  }

  void resetState() {
    pickedLocation.value = null;
    currentAddressSubtitle.value = "Fetching address...";
    currentAddressTitle.value = "Confirm Location";
    _lastProgrammaticMove = null;
  }

  Future<void> refreshAddressForLocation(LatLng pos) async {
    await _fetchAddress(pos);
  }

  // ---------- Search ----------
  void onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      searchPlace(q);
    });
  }

  Future<void> searchPlace(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      suggestions.clear();
      return;
    }

    try {
      isSearching.value = true;
      final apiKey = ApiService.googleMapsApiKey ?? AuthStore.googleMapsApiKey;
      if (apiKey == null || apiKey.isEmpty) {
          debugPrint("Search failed: No API Key available (ApiService or AuthStore)");
          return;
      }

      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(q)}&key=$apiKey&components=country:in", // Assuming India, but we can make it generic
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        suggestions.clear();
        return;
      }

      final data = jsonDecode(res.body);
      if (data['status'] != 'OK') {
           debugPrint("Google Search API Status: ${data['status']}");
           suggestions.clear();
           return;
      }

      final List<dynamic> predictions = data['predictions'];
      final list = predictions.map((json) {
         return PlaceSuggestion(
             displayName: json['description'],
             latLng: const LatLng(0,0), // Placeholder, set on selection after geocoding
         );
      }).toList();
      suggestions.assignAll(list);
    } catch (e) {
      debugPrint("Search failed: $e");
      suggestions.clear();
    } finally {
      isSearching.value = false;
    }
  }

  Future<PlaceSuggestion?> findNearestAirport(LatLng pos) async {
    try {
      final apiKey = ApiService.googleMapsApiKey ?? AuthStore.googleMapsApiKey;
      if (apiKey == null || apiKey.isEmpty) return null;

      // Use keyword=airport to prioritize major airports, and rankby=prominence (default) usually returns the biggest ones first.
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${pos.latitude},${pos.longitude}&radius=50000&keyword=airport&type=airport&key=$apiKey",
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final result = data['results'][0];
        return PlaceSuggestion(
          displayName: result['name'],
          latLng: LatLng(
            result['geometry']['location']['lat'],
            result['geometry']['location']['lng'],
          ),
        );
      }
    } catch (e) {
      debugPrint("Find nearest airport failed: $e");
    }
    return null;
  }

  Future<void> selectSuggestion(PlaceSuggestion s) async {
    final apiKey = ApiService.googleMapsApiKey ?? AuthStore.googleMapsApiKey;
    if (apiKey == null || apiKey.isEmpty) return;

    try {
        isLoadingCoordinates.value = true;
        final url = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(s.displayName)}&key=$apiKey");
        final res = await http.get(url);
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            final loc = data['results'][0]['geometry']['location'];
            final latLng = LatLng(loc['lat'], loc['lng']);
            
            followUser.value = false; // Stop tracking GPS
            suggestions.clear();
            searchTextController.text = s.displayName;
            pickedLocation.value = latLng;
            currentAddressTitle.value = "Selected location";
            currentAddressSubtitle.value = s.displayName;
            // Unfocus the search field
            Get.focusScope?.unfocus();
        }
    } catch (e) {
        debugPrint("Select suggestion failed: $e");
    } finally {
        isLoadingCoordinates.value = false;
    }
  }

  // ---------- Map interaction ----------
  Future<void> pickLocationFromMap(LatLng latLng) async {
    followUser.value = false; // Stop tracking GPS
    suggestions.clear();
    pickedLocation.value = latLng;
    // Unfocus keyboard so we can see the map while choosing
    Get.focusScope?.unfocus();
    await _fetchAddress(latLng);
  }

  void onMapMovedByUser(LatLng center) {
    // Only update picked location, NOT the real GPS userPosition
    pickedLocation.value = center;
    followUser.value = false; // Stop tracking GPS if user moves map manually
    
    if (_lastProgrammaticMove != null && 
        DateTime.now().difference(_lastProgrammaticMove!).inMilliseconds < 1200) {
      return;
    }

    _moveDebounce?.cancel();
    _moveDebounce = Timer(const Duration(milliseconds: 400), () async {
      suggestions.clear();
      await _fetchAddress(center);
    });
  }

  // ---------- Reverse Geocode ----------
  Future<void> _fetchAddress(LatLng pos) async {
    try {
      if (isClosed) return;
      isLoadingAddress.value = true;

      final apiKey = ApiService.googleMapsApiKey ?? AuthStore.googleMapsApiKey;
      if (apiKey == null || apiKey.isEmpty) {
          debugPrint("Geocoding failed: No API Key available (ApiService or AuthStore)");
          // Do not overwrite with raw coordinates if we want to keep addresses readable
          // currentAddressSubtitle.value = "${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}";
          return;
      }
      debugPrint("Geocoding using key ending in: ${apiKey.substring(apiKey.length - 4)}");

      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&key=$apiKey",
      );

      final res = await http.get(url);

      if (isClosed) return;

      if (res.statusCode != 200) {
        debugPrint("Geocoding HTTP Error: ${res.statusCode}");
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          String? readableAddress = result['formatted_address'];

          if (readableAddress != null && readableAddress.isNotEmpty) {
            currentAddressTitle.value = "Confirm Location";
            currentAddressSubtitle.value = readableAddress;
          }
      } else {
          final status = data['status'];
          final errorMsg = data['error_message'] ?? 'Unknown error';
          debugPrint("Google Geocoding API Error: $status - $errorMsg");
      }
    } catch (e) {
      debugPrint("Address fetch failed with exception: $e");
    } finally {
      if (!isClosed) isLoadingAddress.value = false;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';


class DriverFindingController extends GetxController {
  GoogleMapController? mapController;
  final isLoadingLocation = false.obs;
  final isFollowing = true.obs;

  final lat = 28.6139.obs; // default Delhi
  final lng = 77.2090.obs;
  final displayLat = 28.6139.obs;
  final displayLng = 77.2090.obs;
  
  // Custom Icon
  Rxn<BitmapDescriptor> pickupIcon = Rxn<BitmapDescriptor>();
  Rxn<BitmapDescriptor> driverIcon = Rxn<BitmapDescriptor>();
  Timer? _lerpTimer;

  final nearbyRequests = <LatLng>[].obs;
  final rotation = 0.0.obs;

  LatLng get currentPos => LatLng(lat.value, lng.value);

  Timer? _waitTimer;

  @override
  void onInit() {
    super.onInit();
    _loadPickupMarker();
    _loadDriverMarker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCurrentLocation();
    });
  }

  void _loadPickupMarker() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(80, 80)),
        'assets/images/pickup_marker.png', // Assuming this exists or using default
      );
      pickupIcon.value = icon;
    } catch (e) {
      pickupIcon.value = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  void _loadDriverMarker() async {
    try {
      // Manual rescaling logic for large 2000x2000 PNG asset
      final ByteData data = await rootBundle.load('assets/images/driver_location_icon.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 80,
        targetHeight: 80,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? bytes = await fi.image.toByteData(format: ui.ImageByteFormat.png);
      
      if (bytes != null) {
        driverIcon.value = BitmapDescriptor.bytes(bytes.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint("Error loading and rescaling driver PNG icon: $e");
      // Fallback to car icon if rescaling fails
      driverIcon.value = await _getBitmapDescriptorFromIcon(Icons.directions_car);
    }
  }

  Future<BitmapDescriptor> _getBitmapDescriptorFromIcon(IconData iconData) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final iconStr = String.fromCharCode(iconData.codePoint);

    textPainter.text = TextSpan(
      text: iconStr,
      style: TextStyle(
        letterSpacing: 0.0,
        fontSize: 100.0,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: const Color(0xFFF07E23), // Using driver app primary theme color
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(100, 100);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }


  void startWaitingForRequest() {
    // Using real-time Socket.IO via SocketService
  }

  void stopWaiting() {
    _waitTimer?.cancel();
    _waitTimer = null;
  }

  StreamSubscription<Position>? _positionStream;

  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      isFollowing.value = true; // Set isFollowing to true when location is requested

      // Timeout safety
      Future.delayed(const Duration(seconds: 12), () {
        if (!isClosed && isLoadingLocation.value) {
          isLoadingLocation.value = false;
        }
      });

      // 3. Permission & Service Check (Non-blocking for map rendering)
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        isLoadingLocation.value = false;
        // Map is still visible with default values
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        isLoadingLocation.value = false;
        return;
      }

      // 4. Try last known first (Very fast response for UI)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        lat.value = lastPos.latitude;
        lng.value = lastPos.longitude;
        displayLat.value = lastPos.latitude;
        displayLng.value = lastPos.longitude;
        
        // Move camera if map already loaded
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat.value, lng.value), 16),
          );
        }
      }

      // 5. Aggressively fetch current position in background
      Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high))
          .then((currentPos) {
        lat.value = currentPos.latitude;
        lng.value = currentPos.longitude;
        
        if (isFollowing.value && mapController != null) { 
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat.value, lng.value), 16),
          );
        }
        
        // Start live tracking after first location
        _startLiveTracking();
      }).catchError((e) {
        debugPrint("Initial driver getCurrentPosition failed: $e");
      }).whenComplete(() {
        isLoadingLocation.value = false;
      });
    } catch (_) {
      isLoadingLocation.value = false;
    }
  }

  void _startLiveTracking() {
    // Start real-time stream
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((Position pos) {
      if (isClosed) return;
      
      _animateTo(pos.latitude, pos.longitude);
      
      lat.value = pos.latitude;
      lng.value = pos.longitude;
      debugPrint("Driver (Finding): Real-time location: ${pos.latitude}, ${pos.longitude}");

      if (isFollowing.value && mapController != null) { 
        try {
           mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
          );
        } catch (_) {}
      }
    });
  }

  void _animateTo(double targetLat, double targetLng) {
    _lerpTimer?.cancel();
    final startLat = displayLat.value;
    final startLng = displayLng.value;
    int steps = 20;
    int currentStep = 0;
    _lerpTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      currentStep++;
      if (currentStep > steps) {
        timer.cancel();
        displayLat.value = targetLat;
        displayLng.value = targetLng;
        return;
      }
      double t = currentStep / steps;
      displayLat.value = startLat + (targetLat - startLat) * t;
      displayLng.value = startLng + (targetLng - startLng) * t;
    });
  }

  @override
  void onClose() {
    _waitTimer?.cancel();
    _positionStream?.cancel();
    _lerpTimer?.cancel();
    super.onClose();
  }
}

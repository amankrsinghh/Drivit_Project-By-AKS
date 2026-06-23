import 'dart:async';
import 'package:get/get.dart';
import '../../routes/driver_routes.dart';
import './driver_trip_controller.dart';
import '../../../services/api_service.dart';
import '../../../services/routing_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class DriverNewRequestController extends GetxController {
  final secondsLeft = 20.obs;
  Timer? _t;
  final rideData = <String, dynamic>{}.obs;
  
  // Map data
  final driverLat = 0.0.obs;
  final driverLng = 0.0.obs;
  final pickupLat = 0.0.obs;
  final pickupLng = 0.0.obs;
  final routePoints = <LatLng>[].obs;
  final estimatedTime = "Calculating...".obs;
  final driverIcon = Rxn<BitmapDescriptor>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args['ride'] != null) {
      rideData.assignAll(Map<String, dynamic>.from(args['ride']));
      _setupMapData();
    }
    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft.value--;
      if (secondsLeft.value <= 0) {
        timer.cancel();
        _declineRide();
      }
    });
    _loadDriverMarker();
  }

  void _loadDriverMarker() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/driver_location_icon.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 100, // Medium size for this view
        targetHeight: 100,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? bytes = await fi.image.toByteData(format: ui.ImageByteFormat.png);
      
      if (bytes != null) {
        driverIcon.value = BitmapDescriptor.bytes(bytes.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint("Error loading new request driver PNG icon: $e");
    }
  }

  void _setupMapData() async {
    // 1. Set pickup coords
    final pCoords = rideData['pickupCoords'];
    if (pCoords != null) {
      pickupLat.value = (pCoords['lat'] as num).toDouble();
      pickupLng.value = (pCoords['lng'] as num).toDouble();
    }
    
    // 2. Get current driver location
    try {
      final pos = await Geolocator.getCurrentPosition();
      driverLat.value = pos.latitude;
      driverLng.value = pos.longitude;
      
      // 3. Fetch route
      if (pickupLat.value != 0) {
        final dist = Geolocator.distanceBetween(driverLat.value, driverLng.value, pickupLat.value, pickupLng.value);
        if (dist < 20) {
          routePoints.clear();
          estimatedTime.value = "At Pickup";
        } else {
          final details = await RoutingService.getRouteDetails(
            LatLng(driverLat.value, driverLng.value),
            LatLng(pickupLat.value, pickupLng.value),
          );
          final points = details['points'] as List<LatLng>? ?? [];
          routePoints.assignAll(points);
          if (details['duration'] != null) {
             int mins = int.tryParse(details['duration'].toString()) ?? 0;
             if (mins > 60) {
                estimatedTime.value = "${mins ~/ 60}:${(mins % 60).toString().padLeft(2, '0')} hr:min";
             } else {
                estimatedTime.value = "$mins min";
             }
          }
        }
      }
    } catch (e) {
      debugPrint("Error setupMapData: $e");
    }
  }

  void reject() => _declineRide();

  void _declineRide() async {
    _t?.cancel();
    final rideId = rideData['_id']?.toString() ?? '';
    if (rideId.isNotEmpty) {
      // ✅ DRIVER REJECT: Only hide locally, do NOT cancel on backend for the rider
      // await ApiService.updateRideStatus(rideId, 'Cancelled');
      // Persist so SocketService ignores this ride on app restart/reconnect
      await ApiService.addCancelledRideId(rideId);
    }
    // Always  home — never just pop back so cancelled ride cannot be re-entered
    Get.offAllNamed(DriverRoutes.home);
  }

  void accept() {
    final ride = rideData;
    if (ride.isNotEmpty) {
      final ctrl = Get.put(DriverTripController());
      ctrl.loadRide(ride);
      final rideId = ride['_id']?.toString() ?? '';
      if (rideId.isNotEmpty) {
        ctrl.acceptRide(rideId);
      }
      Get.offNamed(DriverRoutes.afterAcceptLocation);
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    _t?.cancel();
    super.onClose();
  }
}

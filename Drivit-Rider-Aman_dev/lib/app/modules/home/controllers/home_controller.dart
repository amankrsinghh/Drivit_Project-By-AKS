

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/api_service.dart';
import '../../../routes/app_routes.dart';
import '../../my_ride/controllers/my_ride_controller.dart';

import '../../my_ride/models/ride_items.dart';
import '../../packages/controllers/package_controller.dart';
import '../../packages/models/package_model.dart';
import '../../../core/utils/geofence_util.dart';
import '../../../core/middleware/auth_middleware.dart';
import '../../map/controllers/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';



class HomeController extends GetxController {
  final selectedIndex = 0.obs;
  DateTime? _lastBackPress;
  final activeRideData = Rxn<Map<String, dynamic>>();
  Timer? _activeRideTimer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['tab'] != null) {
        selectedIndex.value = args['tab'] as int;
      } else if (args['initialIndex'] != null) {
        selectedIndex.value = args['initialIndex'] as int;
      }
      
      if (args['segment'] != null && selectedIndex.value == 1) {
        final ctrl = Get.isRegistered<MyRideController>() ? Get.find<MyRideController>() : Get.put(MyRideController());
        ctrl.setSegment(args['segment'] as RideSegment);
      }
    }
    // ✅ Check for unrated rides on app start
    if (Get.isRegistered<MyRideController>()) {
      Get.find<MyRideController>().fetchMyRides();
    } else {
      Get.put(MyRideController()).fetchMyRides();
    }

    // ✅ CHECK FOR ACTIVE RIDE ON APP LAUNCH
    _checkActiveRideOnLaunch();

    // Refresh active ride for card display
    refreshActiveRideState();

    // Periodically sync/check active ride status as fallback
    _activeRideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (AuthStore.token != null && AuthStore.token!.isNotEmpty) {
        refreshActiveRideState();
      }
    });
  }

  @override
  void onClose() {
    _activeRideTimer?.cancel();
    super.onClose();
  }

  /// Retrieves an ongoing ride or a completed ride with pending payment.
  Future<Map<String, dynamic>?> getActiveOrPendingPaymentRide() async {
    try {
      // Only use the dedicated /active endpoint — it already handles
      // completed+pending-payment rides on the backend side.
      final ride = await ApiService.getActiveRide();
      return ride;
    } catch (e) {
      debugPrint("Error checking active or pending ride: $e");
    }
    return null;
  }

  /// Silently checks for an ongoing ride and redirects the rider if one is found.
  Future<void> _checkActiveRideOnLaunch() async {
    try {
      debugPrint("RIDER_DEBUG: _checkActiveRideOnLaunch started");
      final activeRide = await getActiveOrPendingPaymentRide();
      
      if (activeRide == null) {
        debugPrint("RIDER_DEBUG: activeRide is null, returning.");
        return;
      }

      final rideId = activeRide['_id']?.toString() ?? '';
      if (rideId.isEmpty) {
        debugPrint("RIDER_DEBUG: rideId is empty, returning.");
        return;
      }

      final status = activeRide['status']?.toString() ?? '';
      final paymentStatus = activeRide['paymentStatus']?.toString() ?? 'Pending';
      debugPrint("RIDER_DEBUG: activeRide matches -> status: $status, paymentStatus: $paymentStatus");
      
      if (!['Accepted', 'Arrived', 'Ongoing', 'Completed', 'Cancelled'].contains(status)) {
        debugPrint("RIDER_DEBUG: status is not ongoing/completed/cancelled, returning.");
        return;
      }
      if (status == 'Completed' && paymentStatus == 'Completed') {
        debugPrint("RIDER_DEBUG: Completed and Paid, returning.");
        return;
      }
      if (status == 'Cancelled' && (paymentStatus == 'Completed' || (activeRide['fare'] as num?)?.toDouble() == 0)) {
        debugPrint("RIDER_DEBUG: Cancelled and Paid (or free), returning.");
        return;
      }

      debugPrint("RIDER_DEBUG: Redirecting to FindingDriverView for rideId: $rideId");

      // Small delay so home screen renders before navigating
      await Future.delayed(const Duration(milliseconds: 600));

      final pickup = activeRide['pickupLocation']?.toString() ?? '';
      final destination = activeRide['dropoffLocation']?.toString() ?? '';
      final carType = activeRide['carType']?.toString() ?? '';
      final carModel = activeRide['carModel']?.toString() ?? '';
      final package = (activeRide['carPackage'] ?? activeRide['package'])?.toString() ?? '';

      double pickupLat = 0, pickupLng = 0, dropoffLat = 0, dropoffLng = 0;
      if (activeRide['pickupCoords'] != null) {
        pickupLat = (activeRide['pickupCoords']['lat'] as num?)?.toDouble() ?? 0;
        pickupLng = (activeRide['pickupCoords']['lng'] as num?)?.toDouble() ?? 0;
      }
      if (activeRide['dropoffCoords'] != null) {
        dropoffLat = (activeRide['dropoffCoords']['lat'] as num?)?.toDouble() ?? 0;
        dropoffLng = (activeRide['dropoffCoords']['lng'] as num?)?.toDouble() ?? 0;
      }

      // Navigate to findingDriver with all data so the controller doesn't have to re-fetch everything
      Get.toNamed(
        Routes.findingDriver,
        arguments: {
          'rideId': rideId,
          'pickup': pickup,
          'destination': destination,
          'car': carType,
          'carModel': carModel,
          'package': package,
          'pickupLat': pickupLat,
          'pickupLng': pickupLng,
          'dropoffLat': dropoffLat,
          'dropoffLng': dropoffLng,
        },
      );
    } catch (e) {
      debugPrint("RIDER_DEBUG: Exception in _checkActiveRideOnLaunch: $e");
    }
  }

  void changeTab(int index) {
    if (selectedIndex.value == index) return; // ✅ Avoid redundant clicks
    
    selectedIndex.value = index;
    _lastBackPress = null; 

    refreshActiveRideState();

    // ✅ Refresh My Ride data after the UI frame has switched to ensure maximum responsiveness
    if (index == 1 && Get.isRegistered<MyRideController>()) {
      Future.microtask(() => Get.find<MyRideController>().fetchMyRides(silent: true));
    }
  }

  Future<bool> onWillPop() async {
    // ✅ 1) MyRide Scheduled -> Past
    if (selectedIndex.value == 1 && Get.isRegistered<MyRideController>()) {
      final myRide = Get.find<MyRideController>();
      if (myRide.segment.value == RideSegment.scheduled) {
        myRide.setSegment(RideSegment.past);
        _lastBackPress = null; // ✅ reset
        return false;
      }
    }

    // ✅ 2) Package Outstation -> Hourly
    if (selectedIndex.value == 2 && Get.isRegistered<PackagesController>()) {
      final pkg = Get.find<PackagesController>();
      if (pkg.type.value == PackageType.outstation) {
        pkg.setType(PackageType.hourly);
        _lastBackPress = null; // ✅ reset
        return false;
      }
    }

    // ✅ 3) Any tab -> Home tab
    if (selectedIndex.value != 0) {
      changeTab(0); // (already resets _lastBackPress)
      return false;
    }

    // ✅ 4) Home tab -> silent exit
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      return false;
    }

    SystemNavigator.pop();
    return false;
  }

  Future<void> navigateToSelectRide({Map<String, dynamic>? arguments}) async {
    // Show a single loader for the entire pre-navigation check
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.orange)),
      barrierDismissible: false,
    );

    debugPrint("📍 BOOKNOW [1]: navigateToSelectRide called with args=$arguments");

    try {
      debugPrint("📍 BOOKNOW [2]: Opening loader dialog...");
      
      // Fetch fresh geofence setting from backend first
      try {
        final settings = await ApiService.getPublicSettings();
        if (settings.containsKey('enable_geofence_boundary')) {
          final val = settings['enable_geofence_boundary'];
          AuthStore.enableGeofenceBoundary = (val == true || val.toString().toLowerCase() == 'true');
          debugPrint("📍 BOOKNOW: Updated AuthStore.enableGeofenceBoundary = ${AuthStore.enableGeofenceBoundary}");
        }
      } catch (e) {
        debugPrint("📍 BOOKNOW: Error fetching settings in navigateToSelectRide: $e");
      }

      final activeRide = await getActiveOrPendingPaymentRide();
      debugPrint("📍 BOOKNOW [3]: getActiveOrPendingPaymentRide returned → activeRide=${activeRide == null ? 'null' : activeRide['status']}");

      if (activeRide != null) {
        final status = activeRide['status']?.toString() ?? '';
        final paymentStatus = activeRide['paymentStatus']?.toString() ?? 'Pending';
        debugPrint("📍 BOOKNOW [4]: Active ride found → status=$status, paymentStatus=$paymentStatus");

        if (['Accepted', 'Arrived', 'Ongoing', 'Completed', 'Cancelled'].contains(status) &&
            !(status == 'Completed' && paymentStatus == 'Completed') &&
            !(status == 'Cancelled' && (paymentStatus == 'Completed' || (activeRide['fare'] as num?)?.toDouble() == 0))) {
          debugPrint("📍 BOOKNOW [5]: Redirecting to findingDriver (active/pending-payment/unpaid-cancellation ride)");
          // Close loader before showing snackbar or navigating
          if (Get.isDialogOpen == true) Get.back();

          Get.snackbar(
            "Active Ride / Pending Payment",
            status == 'Completed'
                ? "You have a pending payment for your completed ride. Please complete the payment."
                : (status == 'Cancelled'
                    ? "You have an unpaid cancellation fee. Please complete the payment."
                    : "You have an active ride in progress."),
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );

          final rideId = activeRide['_id']?.toString() ?? '';
          final pickup = activeRide['pickupLocation']?.toString() ?? '';
          final destination = activeRide['dropoffLocation']?.toString() ?? '';
          final carType = activeRide['carType']?.toString() ?? '';
          final carModel = activeRide['carModel']?.toString() ?? '';
          final package =
              (activeRide['carPackage'] ?? activeRide['package'])?.toString() ?? '';

          double pickupLat = 0, pickupLng = 0, dropoffLat = 0, dropoffLng = 0;
          if (activeRide['pickupCoords'] != null) {
            pickupLat = (activeRide['pickupCoords']['lat'] as num?)?.toDouble() ?? 0;
            pickupLng = (activeRide['pickupCoords']['lng'] as num?)?.toDouble() ?? 0;
          }
          if (activeRide['dropoffCoords'] != null) {
            dropoffLat = (activeRide['dropoffCoords']['lat'] as num?)?.toDouble() ?? 0;
            dropoffLng = (activeRide['dropoffCoords']['lng'] as num?)?.toDouble() ?? 0;
          }

          debugPrint("📍 BOOKNOW [6]: Navigating to findingDriver → rideId=$rideId");
          Get.toNamed(
            Routes.findingDriver,
            arguments: {
              'rideId': rideId,
              'pickup': pickup,
              'destination': destination,
              'car': carType,
              'carModel': carModel,
              'package': package,
              'pickupLat': pickupLat,
              'pickupLng': pickupLng,
              'dropoffLat': dropoffLat,
              'dropoffLng': dropoffLng,
            },
          );
          debugPrint("📍 BOOKNOW [7]: Get.toNamed(findingDriver) called ✅");
          return;
        } else {
          debugPrint("📍 BOOKNOW [4b]: Active ride status '$status' does NOT block new booking — proceeding.");
        }
      }

      // No active ride — do location & geofence check
      LatLng? pos;
      if (Get.isRegistered<MapController>()) {
        final mapC = Get.find<MapController>();
        pos = mapC.userPosition.value;
        debugPrint("📍 BOOKNOW [8]: MapController userPosition = $pos");
      } else {
        debugPrint("📍 BOOKNOW [8]: MapController NOT registered.");
      }

      // If location is not yet ready, fetch it now (dialog already showing)
      if (pos == null) {
        debugPrint("📍 BOOKNOW [9]: pos is null — fetching GPS position...");
        try {
          Position p = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          pos = LatLng(p.latitude, p.longitude);
          debugPrint("📍 BOOKNOW [10]: GPS fetched → lat=${p.latitude}, lng=${p.longitude}");
          // Sync back to MapController
          if (Get.isRegistered<MapController>()) {
            Get.find<MapController>().userPosition.value = pos;
          }
        } catch (e) {
          debugPrint("📍 BOOKNOW [10-ERR]: Failed to get location: $e");
        }
      } else {
        debugPrint("📍 BOOKNOW [9]: pos already available from MapController = $pos");
      }

      // Close the loader before navigating
      debugPrint("📍 BOOKNOW [11]: Closing loader dialog (isDialogOpen=${Get.isDialogOpen})");
      if (Get.isDialogOpen == true) Get.back();

      if (pos != null) {
        final bool geofenceEnabled = AuthStore.enableGeofenceBoundary;
        debugPrint("📍 BOOKNOW [12]: Geofence enabled=$geofenceEnabled, pos=${pos.latitude},${pos.longitude}");
        if (geofenceEnabled && !GeofenceUtil.isInsideChennai(pos.latitude, pos.longitude)) {
          debugPrint("📍 BOOKNOW [13]: OUTSIDE Chennai boundary — showing dialog.");
          Get.dialog(
            AlertDialog(
              title: const Text("Service Area Limit"),
              content: const Text(
                  "We currently only offer services within the Chennai city boundary. Bookings are only allowed inside this area."),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("OK", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        } else {
          debugPrint("📍 BOOKNOW [13]: Inside Chennai (or geofence disabled) — proceeding to selectRide.");
        }
      } else {
        final bool geofenceEnabled = AuthStore.enableGeofenceBoundary;
        debugPrint("📍 BOOKNOW [12]: pos is STILL null, geofenceEnabled=$geofenceEnabled");
        if (geofenceEnabled) {
          Get.snackbar(
            "Location Error",
            "Could not verify your location. Please check your GPS.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        } else {
          debugPrint("📍 BOOKNOW [12b]: Geofencing disabled, proceeding without location.");
        }
      }

      debugPrint("📍 BOOKNOW [14]: Calling Get.toNamed(Routes.selectRide)...");
      Get.toNamed(Routes.selectRide, arguments: arguments);
      debugPrint("📍 BOOKNOW [15]: Get.toNamed(selectRide) called ✅");
    } catch (e, stack) {
      debugPrint("📍 BOOKNOW [ERROR]: navigateToSelectRide threw: $e");
      debugPrint("📍 BOOKNOW [STACK]: $stack");
      if (Get.isDialogOpen == true) Get.back();
    }
  }

  Future<void> refreshActiveRideState() async {
    try {
      final ride = await getActiveOrPendingPaymentRide();
      if (ride != null) {
        final status = ride['status']?.toString() ?? '';
        // Only show card for live active stages
        if (['Pending', 'Accepted', 'Arrived', 'Ongoing'].contains(status)) {
          activeRideData.value = ride;
          return;
        }
      }
      activeRideData.value = null;
    } catch (e) {
      debugPrint("Error in refreshActiveRideState: $e");
      activeRideData.value = null;
    }
  }
}
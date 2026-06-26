import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../app/core/utils/geofence_util.dart';
import '../driver_app/routes/driver_routes.dart';
import '../driver_app/home/controllers/driver_home_controller.dart';
import '../driver_app/profile/controllers/driver_profile_controller.dart';
import '../driver_app/trip/views/driver_new_request_popup.dart';
import '../driver_app/trip/controllers/driver_trip_controller.dart';
import '../driver_app/verification/controllers/verification_controller.dart';
import '../driver_app/package/controllers/driver_package_controller.dart';
import '../driver_app/history/controllers/driver_history_controller.dart';

class SocketService extends GetxService {
  static SocketService get to => Get.find();

  io.Socket? socket;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  final isConnected = false.obs;
  Timer? _heartbeatTimer;
  
  // Concurrency and Duplication Locks
  String? currentRideRequestId; 
  bool _isProcessingPopup = false;
  // Set to true when driver accepts a ride; cleared when driver returns to home
  bool isInActiveTrip = false;

  static const String socketUrl =
      'https://backend-production-e76e.up.railway.app';

  @override
  void onInit() {
    super.onInit();
    initSocket();
  }

  void initSocket() async {
    final driverId = await ApiService.getDriverId();
    if (driverId == null) return;

    debugPrint("SocketService: 🔍 Connecting to socket URL: $socketUrl");
    socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket?.connect();

    socket?.onConnect((_) {
      debugPrint("SocketService: 🟢 Connected! Socket ID: ${socket?.id}");
      isConnected.value = true;
      socket?.emit('driver:join', driverId);
      debugPrint("SocketService: 📤 Emitted driver:join for $driverId");

      if (Get.isRegistered<DriverTripController>()) {
        final tripCtrl = Get.find<DriverTripController>();
        final rideId = tripCtrl.currentRideId.value;
        if (rideId.isNotEmpty) {
          socket?.emit('ride:join', rideId);
          debugPrint("SocketService: 📤 Re-joined ride room ride:$rideId on reconnect");
        }
      }

      if (Get.isRegistered<DriverHomeController>()) {
        final hc = Get.find<DriverHomeController>();
        debugPrint("SocketService: ℹ️ HomeController found. isOnline: ${hc.isOnline.value}, current tab index: ${hc.index.value}");
        if (hc.isOnline.value) {
          socket?.emit('driver:online', driverId);
          debugPrint("SocketService: 📤 Emitted driver:online for $driverId");
          _startLocationUpdates();
          _startHeartbeat();
          if (hc.index.value == 2) { // Fix: Finding tab is index 2
            socket?.emit('driver:set_finding', {
              'driverId': driverId,
              'isFinding': true,
            });
            debugPrint("SocketService: 📤 Emitted driver:set_finding true for $driverId");
          }
        }
      }
    });

    socket?.onConnectError((err) {
      debugPrint("SocketService: ❌ Connection Error: $err");
      isConnected.value = false;
    });

    socket?.onDisconnect((_) {
      debugPrint("SocketService: 🔴 Disconnected!");
      isConnected.value = false;
    });

    socket?.onError((err) {
      debugPrint("SocketService: ⚠️ Error event: $err");
    });

    // Ride Request Handler with Concurrency Lock
    socket?.on('ride:new_request', (data) async {
       showRideRequestDialog(data);
    });

    // Listen for cancellation from rider side
    socket?.on('ride:cancelled', (data) {
      final rideId = (data['rideId'] ?? data['_id'])?.toString() ?? '';
      debugPrint("SocketService: 🔴 Received ride:cancelled for ride $rideId");
      
      if (rideId.isNotEmpty) {
        cancelRideRequest(rideId);
      }

      // Instantly clear the active trip card on home screen
      if (Get.isRegistered<DriverHomeController>()) {
        final hc = Get.find<DriverHomeController>();
        if (hc.activeTrip.value != null && (hc.activeTrip.value!['_id']?.toString() == rideId || rideId.isEmpty)) {
          hc.activeTrip.value = null;
        }
      }

      // Also refresh history so the canceled ride shows up correctly in the tabs
      if (Get.isRegistered<DriverHistoryController>()) {
        final hc = Get.find<DriverHistoryController>();
        hc.fetchRides();
        hc.fetchScheduledRides();
      }
    });

    socket?.on('ride:status_changed', (data) {
      if (Get.isRegistered<DriverHistoryController>()) {
        final hc = Get.find<DriverHistoryController>();
        hc.fetchRides();
        hc.fetchScheduledRides();
      }
      if (Get.isRegistered<DriverHomeController>()) {
        final hc = Get.find<DriverHomeController>();
        hc.fetchStats();
        // Instantly clear active trip if status changed to cancelled with 0 fare
        if (data != null) {
          final status = data['status']?.toString();
          final fare = (data['fare'] as num?)?.toDouble() ?? 0.0;
          if (status?.toLowerCase() == 'cancelled' && fare == 0) {
            hc.activeTrip.value = null;
          }
        }
      }
    });

    socket?.on('driver:status_changed', (data) {
      if (data != null && data['isOnline'] == false && data['message'] != null) {
        if (Get.isRegistered<DriverHomeController>()) {
          Get.find<DriverHomeController>().forceOffline(data['message'].toString());
        }
      }
      if (Get.isRegistered<DriverHomeController>()) {
        Get.find<DriverHomeController>().fetchStats();
      }
      if (Get.isRegistered<DriverProfileController>()) {
        Get.find<DriverProfileController>().fetchProfile();
      }
      if (Get.isRegistered<VerificationController>()) {
        Get.find<VerificationController>().checkStatus();
      }
    });

    socket?.on('driver:package_assigned', (data) {
      if (Get.isRegistered<DriverHomeController>()) {
        Get.find<DriverHomeController>().fetchStats();
      }
      try {
        if (Get.isRegistered<DriverPackageController>()) {
          Get.find<DriverPackageController>().fetchCurrentPackage();
        }
      } catch (e) {}
    });

    socket?.on('driver:package_updated', (data) {
      if (Get.isRegistered<DriverHomeController>()) {
        Get.find<DriverHomeController>().fetchStats();
      }
      try {
        if (Get.isRegistered<DriverPackageController>()) {
          Get.find<DriverPackageController>().fetchCurrentPackage();
        }
      } catch (e) {}
      // Snackbars Removed as per request
    });

    // ✅ SUBSCRIPTION EXPIRED — Force driver offline instantly
    socket?.on('driver:package_expired', (data) {
      debugPrint("SocketService: 🔴 Received driver:package_expired — forcing offline");
      if (Get.isRegistered<DriverHomeController>()) {
        Get.find<DriverHomeController>().forceOfflineDueToExpiry();
      }
      try {
        if (Get.isRegistered<DriverPackageController>()) {
          Get.find<DriverPackageController>().fetchCurrentPackage();
        }
      } catch (e) {}
    });

    socket?.on('driver:notification', (data) {
      if (data != null && data is Map) {
        debugPrint("Socket: Driver notification received: ${data['title']}");
        // FCM notification handles the persistent list and system banner
      }
    });

    socket?.on('driver:scheduled_reminder', (data) {
       // Snackbars Removed as per request
    });

    socket?.on('chat:notification', (data) {
      // Snackbars Removed as per request
    });

    socket?.on('rating:updated', (data) {
      debugPrint("Socket: Rating updated: $data");
      if (Get.isRegistered<DriverProfileController>()) {
        Get.find<DriverProfileController>().fetchProfile();
      }
      if (Get.isRegistered<DriverHomeController>()) {
        Get.find<DriverHomeController>().fetchStats();
      }
    });

    socket?.on('settings:updated', (data) async {
      debugPrint("Socket [DRIVER]: Settings updated from admin: $data");
      if (data != null && data is Map) {
        final key = data['key'];
        final val = data['value'];
        if (key == 'enable_geofence_boundary') {
          final bool isEnabled = val == true || val.toString().toLowerCase() == 'true';
          ApiService.enableGeofenceBoundary = isEnabled;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('enable_geofence_boundary', isEnabled);

          debugPrint("Socket [DRIVER]: enable_geofence_boundary updated to $isEnabled");
          if (isEnabled) {
            // Force offline if driver is currently online and outside Chennai
            if (Get.isRegistered<DriverHomeController>()) {
              final hc = Get.find<DriverHomeController>();
              if (hc.isOnline.value) {
                final double lat = hc.driverLat.value;
                final double lng = hc.driverLng.value;
                if (lat != 0 && lng != 0 && !GeofenceUtil.isInsideChennai(lat, lng)) {
                  final trip = hc.activeTrip.value;
                  final bool hasActiveTrip = trip != null && 
                      ['Accepted', 'Arrived', 'Ongoing'].contains(trip['status']);
                  if (!hasActiveTrip) {
                    debugPrint("Socket [DRIVER]: Driver is outside Chennai while geofencing was just enabled! Forcing offline.");
                    hc.forceOffline("Chennai city boundary enforcement has been enabled, and you are outside the service area. You have been taken offline.");
                  } else {
                    debugPrint("Socket [DRIVER]: Geofencing enabled, driver is outside Chennai but on active trip. Bypassing offline.");
                  }
                }
              }
            }
          }
        } else if (key == 'free_rides_count') {
          final int count = int.tryParse(val.toString()) ?? 3;
          ApiService.freeRidesCount = count;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('free_rides_count', count);

          debugPrint("Socket [DRIVER]: free_rides_count updated to $count");
        }
      }
    });

    socket?.on('account_deleted', (data) async {
      if (data != null && data is Map && data['role'] != null) {
        if (data['role'] != 'driver') return;
      }
      debugPrint("SocketService: 🔴 Driver Account Deleted by admin! Instant logout.");
      await ApiService.logout();
      Get.offAllNamed(DriverRoutes.login);
    });

    socket?.onDisconnect((_) {
      isConnected.value = false;
    });
  }

  Future<void> showRideRequestDialog(Map<String, dynamic> data, {bool fromFcmClick = false}) async {
    try {
      if (Get.isDialogOpen == true || _isProcessingPopup) {
        debugPrint("SocketService: [BLOCKED] Popup already open or processing. Skipping request.");
        return;
      }

      final rideId = (data['_id'] ?? data['rideId'])?.toString() ?? '';
      if (rideId.isEmpty) return;

      if (currentRideRequestId == rideId) {
        debugPrint("SocketService: [BLOCKED] Duplicate request for ride $rideId already being shown.");
        return;
      }

      // ── ACTIVE TRIP GUARD (Primary) ──────────────────────────────────────────
      // isInActiveTrip is set to true the moment a driver accepts a ride and
      // is only cleared when the trip fully ends (payment confirmed / home reached).
      if (isInActiveTrip) {
        debugPrint("SocketService: [BLOCKED] isInActiveTrip=true. Driver is in an active trip. Ignoring new ride request $rideId.");
        return;
      }

      // ── ACTIVE TRIP GUARD (Secondary / Fallback) ─────────────────────────────
      // If isInActiveTrip was somehow not set (e.g., app was killed and resumed
      // mid-trip), we double-check the live DriverHomeController.activeTrip.
      if (Get.isRegistered<DriverHomeController>()) {
        final hc = Get.find<DriverHomeController>();
        final trip = hc.activeTrip.value;
        final bool hasLiveActiveTrip = trip != null &&
            ['Accepted', 'Arrived', 'Ongoing'].contains(trip['status']?.toString());
        if (hasLiveActiveTrip) {
          // Sync the flag so future checks are handled by the fast path above
          isInActiveTrip = true;
          debugPrint("SocketService: [BLOCKED] Fallback guard triggered — activeTrip '${trip['status']}' detected. Setting isInActiveTrip=true. Ignoring request $rideId.");
          return;
        }
      }
      // ─────────────────────────────────────────────────────────────────────────

      if (!fromFcmClick) {
        final cancelledIds = await ApiService.getCancelledRideIds();
        if (cancelledIds.contains(rideId)) {
          debugPrint("SocketService: [BLOCKED] Ride $rideId was already rejected/cancelled by this driver.");
          return;
        }
      }

      bool isOnline = true;
      double walletBalance = 500.0; // safe default if controller not ready
      int totalRides = 0;

      if (Get.isRegistered<DriverHomeController>()) {
        final hc = Get.find<DriverHomeController>();
        isOnline = hc.isOnline.value;
        walletBalance = hc.walletBalance.value;
        totalRides = hc.totalRides.value;
        
        hc.addNotification({
          'id': 'request_$rideId',
          'rideId': rideId,
          'title': 'New Ride Request',
          'body': 'You have a new ride request near you!',
        });
      }

      if (!isOnline) {
        debugPrint("SocketService: [BLOCKED] Driver is offline. Skipping request $rideId.");
        return;
      }

      if (totalRides >= ApiService.freeRidesCount && walletBalance < 200) {
        debugPrint("SocketService: [BLOCKED] Insufficient wallet balance (₹$walletBalance) for ride $rideId.");
        return;
      }

      debugPrint("SocketService: [ALLOWED] Showing ride request popup for $rideId.");

      // Lock during dialog presentation
      _isProcessingPopup = true;
      currentRideRequestId = rideId;

      Get.dialog(
        DriverNewRequestPopup(
          ride: data,
          onAccept: () async {
            _isProcessingPopup = false;
            // Keep currentRideRequestId set to prevent the same ride showing again
            if (Get.isDialogOpen == true) Get.back();

            final isSched = data['isScheduled'] == true || data['isScheduled'] == 'true';
            if (isSched) {
              // Scheduled rides: accept silently and remain available for normal rides.
              // Do NOT set isInActiveTrip = true, otherwise driver gets locked out.
              debugPrint("SocketService: Scheduled ride $rideId accepted. Staying available for new requests.");
              await ApiService.updateRideStatus(rideId, 'Accepted');
            } else {
              // Normal ride: lock the driver into this trip immediately.
              isInActiveTrip = true;
              debugPrint("SocketService: Ride $rideId accepted. isInActiveTrip=true. Driver locked from new requests.");
              final ctrl = Get.put(DriverTripController(), permanent: true);
              ctrl.loadRide(data);
              ctrl.acceptRide(rideId);
              Get.toNamed(DriverRoutes.afterAcceptLocation);
            }
          },
          onReject: () async {
            _isProcessingPopup = false;
            currentRideRequestId = null;
            if (Get.isDialogOpen == true) Get.back();
            
            debugPrint("SocketService: Ride $rideId explicitly rejected by driver.");
            // Notify backend of explicit rejection
            await ApiService.rejectRide(rideId);
            await ApiService.addCancelledRideId(rideId);
          },
        ),
        barrierDismissible: false,
      ).then((_) {
        _isProcessingPopup = false;
      });
    } catch (e) {
      _isProcessingPopup = false;
      debugPrint("SocketService: Error showing popup: $e");
    }
  }

  // --- Socket Control Methods ---

  /// Called when driver fully completes/cancels a trip and returns to home.
  /// Resets ALL active-trip guards so new ride requests can flow again.
  void clearActiveTrip() {
    if (isInActiveTrip || currentRideRequestId != null || _isProcessingPopup) {
      debugPrint(
        "SocketService: clearActiveTrip() — isInActiveTrip: $isInActiveTrip, "
        "currentRideRequestId: $currentRideRequestId, _isProcessingPopup: $_isProcessingPopup. "
        "Resetting all flags. Driver is now available for new requests.",
      );
    }
    isInActiveTrip = false;
    currentRideRequestId = null;
    _isProcessingPopup = false;
  }

  /// Cancels an active ride request popup and cleans up related concurrency/popup lock flags.
  void cancelRideRequest(String rideId) {
    if (currentRideRequestId == rideId) {
      if (Get.isDialogOpen == true) {
        Get.back(); // Automatically close the popup
      }
      currentRideRequestId = null;
      _isProcessingPopup = false;
      debugPrint("SocketService: 🛑 Closed active popup and cleared lock flags for cancelled/accepted ride $rideId");
    }
  }

  void goOnline() async {
    final driverId = await ApiService.getDriverId();
    debugPrint("[SOCKET DEBUG] SocketService.goOnline() called. driverId: $driverId, socket connected: ${socket?.connected}");
    if (driverId != null) {
      socket?.emit('driver:online', driverId);
      _startLocationUpdates();
      _startHeartbeat();
    }
  }

  void goOffline() async {
    final driverId = await ApiService.getDriverId();
    debugPrint("[SOCKET DEBUG] SocketService.goOffline() called. driverId: $driverId, socket connected: ${socket?.connected}");
    if (driverId != null) {
      socket?.emit('driver:offline', driverId);
      _stopLocationUpdates();
      _stopHeartbeat();
    }
  }

  void setFindingStatus(bool isFinding) async {
    final driverId = await ApiService.getDriverId();
    if (driverId != null) {
      socket?.emit('driver:set_finding', {
        'driverId': driverId,
        'isFinding': isFinding,
      });
    }
  }

  void joinRide(String rideId) {
    socket?.emit('ride:join', rideId);
  }

  void leaveRide(String rideId) {
    socket?.emit('ride:leave', rideId);
  }

  void updateLocation(String rideId, double lat, double lng) {
    socket?.emit('ride:location_update', {
      'rideId': rideId,
      'type': 'driver',
      'lat': lat,
      'lng': lng,
    });
  }

  // --- Location Helpers ---

  String? _cachedDriverId;

  Future<String?> _getDriverId() async {
    if (_cachedDriverId != null) return _cachedDriverId;
    _cachedDriverId = await ApiService.getDriverId();
    return _cachedDriverId;
  }

  void _startLocationUpdates() async {
    _positionStream?.cancel();
    final driverId = await _getDriverId();

    // Fetch and send current location immediately
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _lastPosition = p;
      if (driverId != null && isConnected.value) {
        socket?.emit('driver:location', {
          'driverId': driverId,
          'lat': p.latitude,
          'lng': p.longitude,
        });
        debugPrint("SocketService: 📤 Emitted initial location: ${p.latitude}, ${p.longitude}");
      }
    } catch (e) {
      debugPrint("SocketService: ⚠️ Error fetching initial location: $e");
    }
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Reduced to 5 meters for better real-time feel
      ),
    ).listen((p) async {
      _lastPosition = p;
      if (driverId != null && isConnected.value) {
        socket?.emit('driver:location', {
          'driverId': driverId,
          'lat': p.latitude,
          'lng': p.longitude,
        });
      }
    });
  }

  void _stopLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void _startHeartbeat() async {
    _heartbeatTimer?.cancel();
    final driverId = await ApiService.getDriverId();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_lastPosition != null && isConnected.value && driverId != null) {
        socket?.emit('driver:location', {
          'driverId': driverId,
          'lat': _lastPosition!.latitude,
          'lng': _lastPosition!.longitude,
        });
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void onClose() {
    _stopLocationUpdates();
    _stopHeartbeat();
    socket?.dispose();
    super.onClose();
  }
}

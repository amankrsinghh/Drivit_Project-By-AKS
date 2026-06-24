import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../routes/driver_routes.dart';
import '../../finding/controllers/driver_finding_controller.dart';

import '../../../services/socket_service.dart';
import '../../../services/api_service.dart';
import '../../../services/notification_service.dart';
import '../../../app/core/utils/geofence_util.dart';


class DriverHomeController extends GetxController {
  final index = 0.obs; // 0 Home, 1 Package, 2 Finding, 3 History, 4 Profile
  final isOnline = false.obs;

  static bool _initialized = false;

  // Real-time stats
  final walletBalance = 0.0.obs;
  final incentiveBalance = 0.0.obs;
  final todayEarning = 0.0.obs;
  final weekEarning = 0.0.obs;
  final monthEarning = 0.0.obs;
  final recentRides = <dynamic>[].obs;
  final totalRecharge = 0.0.obs;
  final isLoadingStats = false.obs;

  // Profile & Notifications
  final profileImageUrl = "".obs;
  final unreadNotificationsCount = 0.obs;
  final notifications = <Map<String, dynamic>>[].obs;
  final deletedNotificationIds = <String>[].obs;

  final isWalletActive = false.obs;
  
  // Real-time location
  final driverLat = 0.0.obs;
  final driverLng = 0.0.obs;
  final displayDriverLat = 0.0.obs;
  final displayDriverLng = 0.0.obs;
  final lastPosition = Rxn<LatLng>();
  
  final totalRides = 0.obs;
  
  // Active Ride status tracking
  final activeTrip = Rxn<Map<String, dynamic>>();
  Timer? _activeTripTimer;
  
  Timer? _lerpTimer;
  StreamSubscription<Position>? _positionStream;

  @override
  void onInit() {
    super.onInit();
    _loadStoredNotifications();
    _loadCachedProfileStats(); // Load cached data instantly
    fetchStats();
    _initLocation();
    // ✅ CHECK FOR ACTIVE TRIP ON APP LAUNCH
    _checkActiveTripOnLaunch();
    _startActiveTripPolling();
  }

  void _loadCachedProfileStats() {
    final cached = ApiService.cachedProfile;
    if (cached != null) {
      walletBalance.value = (cached['walletBalance'] ?? 0.0).toDouble();
      incentiveBalance.value = (cached['incentiveBalance'] ?? 0.0).toDouble();
      isWalletActive.value = cached['isWalletActive'] ?? false;
      totalRides.value = cached['totalRides'] ?? 0;
      if (cached['profileImage'] != null) {
        profileImageUrl.value = cached['profileImage'];
      }
    }
  }

  Future<void> _loadStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load active notifications
      final list = prefs.getStringList('stored_notifications') ?? [];
      final parsed = <Map<String, dynamic>>[];
      for (final item in list) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) {
            parsed.add(Map<String, dynamic>.from(decoded));
          }
        } catch (itemErr) {
          debugPrint("DriverHomeController: Skipping corrupted stored notification: $itemErr");
        }
      }
      notifications.assignAll(parsed);
      
      // Load unread count
      final unread = prefs.getInt('unread_notifications_count') ?? 0;
      unreadNotificationsCount.value = unread;

      // ✅ Tombstones are session-only (not loaded from disk)
      // This prevents notifications from being permanently blocked across sessions.
      deletedNotificationIds.clear();
      // Clean up any stale tombstone data from old app versions
      await prefs.remove('deleted_notification_ids');
    } catch (e) {
      debugPrint("Error loading stored notifications: $e");
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save active notifications
      final list = <String>[];
      for (final n in notifications) {
        try {
          list.add(jsonEncode(n));
        } catch (encodeErr) {
          debugPrint("DriverHomeController: Skipping non-serializable notification payload: $encodeErr");
        }
      }
      await prefs.setStringList('stored_notifications', list);
      
      // Save unread count
      await prefs.setInt('unread_notifications_count', unreadNotificationsCount.value);

      // ✅ Tombstones are session-only — not persisted to disk
      // This prevents permanently blocking new notifications with same IDs in new sessions.
    } catch (e) {
      debugPrint("Error saving notifications: $e");
    }
  }

  Future<void> _initLocation() async {
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        driverLat.value = lastPos.latitude;
        driverLng.value = lastPos.longitude;
        displayDriverLat.value = lastPos.latitude;
        displayDriverLng.value = lastPos.longitude;
        lastPosition.value = LatLng(lastPos.latitude, lastPos.longitude);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      driverLat.value = pos.latitude;
      driverLng.value = pos.longitude;
      displayDriverLat.value = pos.latitude;
      displayDriverLng.value = pos.longitude;
      lastPosition.value = LatLng(pos.latitude, pos.longitude);
      
      _startTracking();
    } catch (e) {
      debugPrint("Error initializing location: $e");
    }
  }

  void _startTracking() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position pos) {
      if (isClosed) return;
      
      _animateTo(pos.latitude, pos.longitude);
      
      driverLat.value = pos.latitude;
      driverLng.value = pos.longitude;
      lastPosition.value = LatLng(pos.latitude, pos.longitude);

      // ✅ Real-time Geofence Enforcement: Force offline if driver leaves Chennai
      if (isOnline.value) {
        final bool geofenceEnabled = ApiService.enableGeofenceBoundary;
        if (geofenceEnabled && !GeofenceUtil.isInsideChennai(pos.latitude, pos.longitude)) {
          debugPrint("Geofence: Driver moved out of Chennai boundary. Forcing offline.");
          forceOffline("You have moved outside the Chennai service area. You have been taken offline.");
        }
      }
    });
  }

  void _animateTo(double targetLat, double targetLng) {
    _lerpTimer?.cancel();
    final startLat = displayDriverLat.value;
    final startLng = displayDriverLng.value;
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
        displayDriverLat.value = targetLat;
        displayDriverLng.value = targetLng;
        return;
      }
      double t = currentStep / steps;
      displayDriverLat.value = startLat + (targetLat - startLat) * t;
      displayDriverLng.value = startLng + (targetLng - startLng) * t;
    });
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    _lerpTimer?.cancel();
    _activeTripTimer?.cancel();
    super.onClose();
  }

  /// Silently checks for an ongoing trip and redirects the driver if one is found.
  Future<void> _checkActiveTripOnLaunch() async {
    try {
      final ride = await ApiService.getActiveTrip();
      if (ride == null) {
        if (!_initialized) {
          await _resetToOffline();
          _initialized = true;
        }
        return;
      }

      final rideId = ride['_id']?.toString() ?? '';
      if (rideId.isEmpty) {
        if (!_initialized) {
          await _resetToOffline();
          _initialized = true;
        }
        return;
      }

      final status = ride['status']?.toString() ?? '';
      final pStatus = ride['paymentStatus']?.toString() ?? '';
      
      // ✅ RESUME FOR ACTIVE STATES OR PENDING PAYMENT COMPLETED RIDES
      bool isResumable = ['Accepted', 'Arrived', 'Ongoing'].contains(status) ||
                         (status == 'Completed' && pStatus == 'Pending') ||
                         (status == 'Cancelled' && pStatus == 'Pending' && (ride['fare'] ?? 0) > 0);
      if (!isResumable) {
        debugPrint("DriverHome: Found ride but status is $status (paymentStatus: $pStatus). Not resuming.");
        if (!_initialized) {
          await _resetToOffline();
          _initialized = true;
        }
        return;
      }

      // ✅ CHECK IF MANUALLY CANCELLED LOCALLY (Stays in local storage)
      final cancelledIds = await ApiService.getCancelledRideIds();
      if (cancelledIds.contains(rideId)) {
        debugPrint("DriverHome: Active ride found but was locally cancelled/rejected ($rideId). Skipping.");
        if (!_initialized) {
          await _resetToOffline();
          _initialized = true;
        }
        return;
      }

      // ✅ Driver has an active trip! Keep/set them online.
      isOnline.value = true;
      await ApiService.saveOnlineStatus(true);
      
      // Sync online state to backend and sockets
      try {
        await ApiService.toggleOnline(
          true,
          lat: driverLat.value != 0.0 ? driverLat.value : null,
          lng: driverLng.value != 0.0 ? driverLng.value : null,
        );
      } catch (_) {}

      if (Get.isRegistered<SocketService>()) {
        final socket = Get.find<SocketService>();
        socket.goOnline();
        socket.setFindingStatus(true);
      }

      _initialized = true;

      // Small delay so home screen renders before navigating
      await Future.delayed(const Duration(milliseconds: 800));

      // ✅ NAVIGATE TO CORRECT SCREEN BASED ON STATUS
      final statusLower = status.toLowerCase();
      if (statusLower == 'completed' || statusLower == 'cancelled') {
        debugPrint("DriverHome: Resuming Earning view for ride $rideId");
        Get.toNamed(
          DriverRoutes.tripEarning,
          parameters: {'rideId': rideId},
        );
      } else if (statusLower == 'ongoing' || statusLower == 'tripstarted') {
        debugPrint("DriverHome: Resuming Ongoing trip $rideId");
        Get.toNamed(
          DriverRoutes.reachDestination,
          parameters: {'rideId': rideId},
        );
      } else if (statusLower == 'arrived') {
        debugPrint("DriverHome: Resuming Arrived (Quick Check) trip $rideId");
        Get.toNamed(
          DriverRoutes.quickCheck,
          parameters: {'rideId': rideId},
        );
      } else {
        // Accepted
        debugPrint("DriverHome: Resuming Accepted trip $rideId");
        Get.toNamed(
          DriverRoutes.afterAcceptLocation,
          parameters: {'rideId': rideId},
        );
      }
    } catch (e) {
      debugPrint("Error checking active trip on launch: $e");
      if (!_initialized) {
        await _resetToOffline();
        _initialized = true;
      }
    }
  }

  void _startActiveTripPolling() {
    _activeTripTimer?.cancel();
    _activeTripTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      checkActiveTrip();
    });
    // Run an initial check
    checkActiveTrip();
  }

  Future<void> checkActiveTrip() async {
    try {
      final ride = await ApiService.getActiveTrip();
      if (ride != null) {
        final rideId = ride['_id']?.toString() ?? '';
        final status = ride['status']?.toString() ?? '';
        final pStatus = ride['paymentStatus']?.toString() ?? '';
        final cancelledIds = await ApiService.getCancelledRideIds();
        
        bool isResumable = ['Accepted', 'Arrived', 'Ongoing'].contains(status) || 
                           (status == 'Completed' && pStatus == 'Pending') ||
                           (status == 'Cancelled' && pStatus == 'Pending' && (ride['fare'] ?? 0) > 0);

        if (isResumable && !cancelledIds.contains(rideId)) {
          activeTrip.value = ride;
          return;
        }
      }
      activeTrip.value = null;
    } catch (e) {
      debugPrint("Error checking active trip in home controller: $e");
      activeTrip.value = null;
    }
  }

  void resumeActiveTrip() {
    final ride = activeTrip.value;
    if (ride == null) return;
    
    final rideId = ride['_id']?.toString() ?? '';
    final status = (ride['status']?.toString() ?? '').toLowerCase();
    
    if (status == 'completed' || status == 'cancelled') {
      Get.toNamed(
        DriverRoutes.tripEarning,
        parameters: {'rideId': rideId},
      );
    } else if (status == 'ongoing' || status == 'tripstarted') {
      Get.toNamed(
        DriverRoutes.reachDestination,
        parameters: {'rideId': rideId},
      );
    } else if (status == 'arrived') {
      Get.toNamed(
        DriverRoutes.quickCheck,
        parameters: {'rideId': rideId},
      );
    } else {
      Get.toNamed(
        DriverRoutes.afterAcceptLocation,
        parameters: {'rideId': rideId},
      );
    }
  }


  Future<void> _resetToOffline() async {
    isOnline.value = false;
    await ApiService.saveOnlineStatus(false);
    
    // Sync with backend to be sure
    await ApiService.toggleOnline(false);

    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.goOffline();
      socket.setFindingStatus(false);
    }
  }

  /// ✅ Force driver offline when subscription expires or geofencing triggers
  Future<void> forceOffline(String message) async {
    debugPrint("DriverHomeController: ⚠️ Force offline — $message");

    // 1. Instant UI update
    isOnline.value = false;

    // 2. Persist locally
    await ApiService.saveOnlineStatus(false);

    // 3. Sync with backend (safety)
    try {
      await ApiService.toggleOnline(false);
    } catch (_) {}

    // 4. Disconnect socket from online/finding rooms
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.goOffline();
      socket.setFindingStatus(false);
    }

    // 5. Stop finding controller if active
    if (Get.isRegistered<DriverFindingController>()) {
      Get.find<DriverFindingController>().stopWaiting();
    }

    // 6. Show alert
    Get.snackbar(
      "Service Alert",
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  /// ✅ Force driver offline when subscription expires
  Future<void> forceOfflineDueToExpiry() async {
    isWalletActive.value = false;
    await forceOffline("Subscription expired — forcing offline");
    // 7. Navigate to Package tab so driver sees renewal options
    setIndex(1);
  }


  void addNotification(Map<String, dynamic> data) {
    // Extract type
    String? type;
    if (data['type'] != null) {
      type = data['type'].toString();
    } else if (data['data'] != null && data['data'] is Map && data['data']['type'] != null) {
      type = data['data']['type'].toString();
    } else if (data['payload'] != null && data['payload'] is Map && data['payload']['type'] != null) {
      type = data['payload']['type'].toString();
    }

    if (type == 'ride_cancelled' || type == 'ride_accepted') {
      debugPrint("AddNotification: Skipping cancellation/acceptance notification ($type) from list.");
      return;
    }

    final String title = (data['title'] ?? 'Notification').toString();
    final String body = (data['body'] ?? '').toString();
    
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty && cleanBody.isEmpty) {
      debugPrint("DriverHomeController: Ignoring empty notification.");
      return;
    }
    if ((cleanTitle == 'Notification' || cleanTitle == 'New Message') && cleanBody.isEmpty) {
      debugPrint("DriverHomeController: Ignoring generic notification with empty body.");
      return;
    }
    
    // Canonical ID detection for Ride Requests
    String? rideId;
    if (data['rideId'] != null) {
      rideId = data['rideId'].toString();
    } else if (data['data'] != null && data['data'] is Map && data['data']['rideId'] != null) {
      rideId = data['data']['rideId'].toString();
    }

    String id = (data['_id'] ?? data['id'] ?? data['messageId'] ?? '').toString();
    
    // If it's a ride request, force a consistent ID based on rideId
    if (title == 'New Ride Request' && rideId != null && rideId.isNotEmpty) {
      id = 'request_$rideId';
    }

    if (id.isEmpty) {
      // Fallback: Use hash of title + body to avoid exact duplicates
      id = "${title}_$body".hashCode.toString();
    }

    // 1. Skip if ID is in deleted tombstones
    if (deletedNotificationIds.contains(id)) {
      debugPrint("AddNotification: Skipping deleted notification $id");
      return;
    }

    // 2. Check for duplicate/old entries for the same request and clear them
    // This ensures that if we get a new update for the same request, we only keep one.
    int existingIndex = notifications.indexWhere((n) => n['id'] == id);
    if (existingIndex != -1) {
      debugPrint("AddNotification: Duplicate ride request $id found. Removing old one.");
      notifications.removeAt(existingIndex);
    }

    notifications.insert(0, {
      'id': id,
      'title': title,
      'body': body,
      'time': DateTime.now().toString(),
      'payload': data['data'] ?? data,
    });
    unreadNotificationsCount.value++;
    _saveNotifications();
  }

  void clearNotifications() {
    // Add all current IDs to tombstone before clearing
    for (var n in notifications) {
      final id = n['id']?.toString() ?? '';
      if (id.isNotEmpty && !deletedNotificationIds.contains(id)) {
        deletedNotificationIds.add(id);
      }
    }
    
    notifications.clear();
    unreadNotificationsCount.value = 0;
    _saveNotifications();
    
    // Clear system tray
    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.cancelAll();
    }
  }

  void removeNotification(int index) {
    if (index >= 0 && index < notifications.length) {
      final id = notifications[index]['id']?.toString() ?? '';
      if (id.isNotEmpty && !deletedNotificationIds.contains(id)) {
        deletedNotificationIds.add(id);
      }
      notifications.removeAt(index);
      _saveNotifications();

      // Clear system tray if no more notifications
      if (notifications.isEmpty && Get.isRegistered<NotificationService>()) {
        NotificationService.to.cancelAll();
      }
    }
  }

  /// Mark all notifications as read — clears the badge without deleting notifications
  void markAllRead() {
    unreadNotificationsCount.value = 0;
    _saveNotifications();
  }

  Future<void> fetchStats() async {
    isLoadingStats.value = true;
    try {
      // 1. Fetch Profile for total balance/earned
      final profile = await ApiService.getDriverProfile();
      if (profile != null && !profile.containsKey('error')) {
        walletBalance.value = (profile['walletBalance'] ?? 0.0).toDouble();
        incentiveBalance.value = (profile['incentiveBalance'] ?? 0.0).toDouble();
        isWalletActive.value = profile['isWalletActive'] ?? false;
        totalRides.value = profile['totalRides'] ?? 0;

        if (profile['profileImage'] != null) {
          profileImageUrl.value = profile['profileImage'];
        }

        // Calculate total recharge from transactions
        double rechargeSum = 0;
        if (profile['transactions'] != null) {
          final txs = profile['transactions'] as List;
          for (var tx in txs) {
            if (tx['title'] == 'Wallet Recharge' && tx['type'] == 'credit') {
              rechargeSum += (tx['amount'] ?? 0).toDouble();
            }
          }
        }
        totalRecharge.value = rechargeSum;
      }

      // 2. Fetch specialized stats for earnings (Optimized)
      final stats = await ApiService.getDriverStats();
      if (stats['error'] == null) {
        todayEarning.value = (stats['today'] ?? 0).toDouble();
        weekEarning.value = (stats['week'] ?? 0).toDouble();
        monthEarning.value = (stats['month'] ?? 0).toDouble();
      }

      // 3. Fetch recent rides for the UI (latest 5)
      final ridesRes = await ApiService.getDriverRides(page: 1, limit: 10);
      final List rides = ridesRes['rides'] ?? [];
      final displayRides = rides
          .where((r) => r['status'] != 'Cancelled' && r['status'] != 'Pending')
          .toList();
      recentRides.assignAll(displayRides.take(5).toList()); 

    } catch (e) {
      print("Error fetching home stats: $e");
    } finally {
      isLoadingStats.value = false;

      // ✅ AUTO-DETECT: If wallet became inactive while driver is online, force offline (only if not on free rides)
      if (isOnline.value && !isWalletActive.value && totalRides.value >= ApiService.freeRidesCount) {
        debugPrint("DriverHomeController: Wallet inactive but driver is online — forcing offline (package likely expired)");
        forceOfflineDueToExpiry();
      }
    }
  }

  Future<void> toggleOnline(bool v) async {
    if (v && totalRides.value >= ApiService.freeRidesCount) {
      if (!isWalletActive.value) {
        setIndex(1); // Navigate to Package tab automatically
        return;
      }
      if (walletBalance.value < 200) {
        setIndex(1); // Navigate to Package tab automatically
        return;
      }
    }

    // ✅ PRE-TOGGLE GEOFENCE CHECK
    double? lat;
    double? lng;

    if (v) {
      lat = driverLat.value;
      lng = driverLng.value;

      // If location is not yet ready, fetch it immediately
      if (lat == 0 || lng == 0) {
        Get.dialog(
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
          barrierDismissible: false,
        );
        try {
          Position p = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          lat = p.latitude;
          lng = p.longitude;
          driverLat.value = lat;
          driverLng.value = lng;
        } catch (e) {
          debugPrint("Geofence Toggle: Failed to get location: $e");
        }
        if (Get.isDialogOpen == true) Get.back();
      }

      debugPrint("Geofence: Checking Driver location: $lat, $lng");
      final bool geofenceEnabled = ApiService.enableGeofenceBoundary;
      if (geofenceEnabled && !GeofenceUtil.isInsideChennai(lat!, lng!)) {
        debugPrint("Geofence: Driver is OUTSIDE Chennai boundary.");
        Get.dialog(
          AlertDialog(
            title: const Text("Access Denied"),
            content: const Text("You are out of Chennai boundary area. You can only go online within Chennai city limits."),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("OK", style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );
        return;
      }
    }

    // ✅ INSTANT UI UPDATE
    final oldStatus = isOnline.value;
    isOnline.value = v;

    try {
      final res = await ApiService.toggleOnline(v, lat: lat, lng: lng);
      
      if (res.containsKey('error')) {
        // Revert UI if backend error
        isOnline.value = oldStatus;
        
        Get.snackbar(
          "Access Denied",
          res['error'] ?? "You are out of chennai boundary area.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );

        if (v == true && !res.containsKey('outOfBoundary')) {
          setIndex(1); // Navigate to Package tab automatically (only if not a boundary error)
        }
        return;
      }

      await ApiService.saveOnlineStatus(v);
      
      // Real-time Online/Offline
      if (Get.isRegistered<SocketService>()) {
        final socket = Get.find<SocketService>();
        if (v) {
          socket.goOnline();
          socket.setFindingStatus(true);
        } else {
          socket.goOffline();
          socket.setFindingStatus(false);
        }
      }

      if (!v && Get.isRegistered<DriverFindingController>()) {
        Get.find<DriverFindingController>().stopWaiting();
      }
    } catch (e) {
      // Revert UI on error
      isOnline.value = oldStatus;
      debugPrint("Error toggling online: $e");
    }
  }

  void setIndex(int i) {
    try {
      index.value = i;

      if (i == 0) {
        fetchStats();
      }

      // Check if finding is i=2 now (0 home, 1 package, 2 finding, 3 history, 4 profile)
      if (i == 2) {
        if (isOnline.value && Get.isRegistered<DriverFindingController>()) {
          Get.find<DriverFindingController>().startWaitingForRequest();
        }
      } else {
        if (Get.isRegistered<DriverFindingController>()) {
          Get.find<DriverFindingController>().stopWaiting();
        }
      }
    } catch (e) {
      print("Error in setIndex: $e");
    }
  }
}

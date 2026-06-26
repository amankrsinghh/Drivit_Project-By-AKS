import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../routes/app_routes.dart';
import '../widgets/end_trip_dialog.dart';
import '../../map/controllers/map_controller.dart';
import '../../../core/services/routing_service.dart';
import '../../../core/services/payment_service.dart';
import '../../my_ride/models/ride_items.dart';
import '../../../widgets/dialogs/driver_rating_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

enum BookingStage { finding, accepted, arrived, tripStarted, tripCompleted }

class FindingDriverController extends GetxController {
  final stage = BookingStage.finding.obs;
  static final Map<String, DateTime> _searchStartTimes = {};

  // booking args
  final pickup = "".obs;
  final destination = "".obs;
  final car = "".obs;
  final carModelRequested = "".obs;
  final package = "".obs;
  final requireCarWash = false.obs;
  final carWashPrice = 0.0.obs;

  // driver info
  final driverName = "".obs;
  final driverRating = "0.0".obs;
  final driverExp = "".obs;
  final carNumber = "".obs;
  final carModel = "".obs;
  final bookingId = "".obs; // Human-readable RID... for display
  final rideDatabaseId = "".obs; // MongoDB ObjectID for API calls
  final driverId = "".obs;
  final driverImage = "".obs;
  final driverMobile = "".obs;

  final driverLat = 0.0.obs;
  final driverLng = 0.0.obs;

  // Smooth movement
  final displayDriverLat = 0.0.obs;
  final displayDriverLng = 0.0.obs;
  final displayDriverRotation = 0.0.obs;
  Timer? _lerpTimer;

  // Custom Icon
  Rxn<BitmapDescriptor> driverIcon = Rxn<BitmapDescriptor>();

  // Flag to prevent repetitive auto-zooms
  bool _boundsFittedForTrip = false;

  final pickupLat = 0.0.obs;
  final pickupLng = 0.0.obs;
  final dropoffLat = 0.0.obs;
  final dropoffLng = 0.0.obs;

  final routeToPickup = <LatLng>[].obs;
  final routeToDropoff = <LatLng>[].obs;
  final actualPath = <LatLng>[].obs; // Record the actual path taken

  final etaToPickup = "".obs;
  final etaToDropoff = "".obs;

  final distanceToDriver = "".obs;

  final otp = "".obs;

  // End Trip reason
  final selectedReason = RxnString();
  final isCancellationPaymentFlow = false.obs;
  final cancellationFeePercent = 10.0.obs;  // default 10%, fetched from settings
  final reasonTextController = TextEditingController();

  // Trip completed data
  final finalFare = 0.0.obs;
  final originalRideFare = 0.0.obs; // preserved original fare for cancellation fee calc
  final hourlyPackage = "".obs;
  final extraTimeUsed = "".obs;
  final estimatedTime = "".obs;
  final hourlyRate = "₹ 150/hour".obs;
  final tripDuration = "".obs;
  final distance = "".obs;
  final paymentMode = "Online".obs;
  final isWaitingForCashConfirmation = false.obs;

  // ✅ New fields for consistency
  final transmission = "".obs;
  final tripType = "".obs;
  final bookingTime = "".obs;
  final scheduledTime = "".obs;
  final isScheduled = false.obs;
  final completionTime = "".obs;
  final arrivalTime = "".obs;
  final tripStartTime = "".obs;
  final carType = "".obs; // Car for today
  final distanceCost = 0.0.obs;
  final hourlyCost = 0.0.obs;

  // safety
  final isClosing = false.obs;
  final isCancelling = false.obs;
  final isPaying = false.obs;
  final isFeedbackShown = false.obs;
  final _paymentService = PaymentService();
  final searchCountdown = 300.obs; // 5 minutes
  final showRetryOption = false.obs;
  Timer? _searchCountdownTimer;

  bool _isOtpShown = false;
  bool _isReachedSnackbarShown = false;

  dynamic _onStatusChanged;
  dynamic _onDriverReached;
  dynamic _onLocationUpdate;

  // Timers
  Timer? _acceptTimer;
  Timer? _tripStartTimer;
  Timer? _locationUpdateTimer;
  Timer? _routeDebounce;
  Timer? _paymentPollTimer;

  bool _boundsFittedOnce = false;
  GoogleMapController? _attachedMapController;

  void attachMapController(GoogleMapController mc) {
    _attachedMapController = mc;
  }

  void detachMapController() {
    stopMapAnimation();
    _attachedMapController = null;
  }

  @override
  void onInit() {
    super.onInit();

    final args = (Get.arguments ?? {}) as Map;
    pickup.value = (args["pickup"] ?? "").toString();
    destination.value = (args["destination"] ?? "").toString();
    car.value = (args["car"] ?? "").toString();
    carModelRequested.value = (args["carModel"] ?? "").toString();
    package.value = (args["package"] ?? "").toString();

    // Check both args and parameters (for direct navigation on app start)
    final rideId = (args["rideId"] ?? Get.parameters["rideId"]);

    pickupLat.value = (args["pickupLat"] as num?)?.toDouble() ?? 0.0;
    pickupLng.value = (args["pickupLng"] as num?)?.toDouble() ?? 0.0;
    dropoffLat.value = (args["dropoffLat"] as num?)?.toDouble() ?? 0.0;
    dropoffLng.value = (args["dropoffLng"] as num?)?.toDouble() ?? 0.0;
    distanceCost.value = (args["distanceCost"] as num?)?.toDouble() ?? 0.0;
    hourlyCost.value = (args["hourlyCost"] as num?)?.toDouble() ?? 0.0;

    if (rideId != null) {
      rideDatabaseId.value = rideId.toString();
      _saveBookingId(rideDatabaseId.value);
      fetchRideDetails(rideDatabaseId.value);
      listenToRideUpdates(rideDatabaseId.value);
    } else {
      _tryRehydrateOrFetch();
    }

    _loadCustomMarker();
    _setupMapWorkers();

    // Start timer if finding
    if (stage.value == BookingStage.finding) {
      _startSearchTimer();
    }

    // Initial zoom once data is loaded
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => _fitBounds(force: true),
    );
  }

  void _loadCustomMarker() async {
    try {
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
      debugPrint("Error loading and rescaling rider-side driver PNG icon: $e");
    }
  }

  void _startSearchTimer() {
    _stopSearchTimer();

    final id = rideDatabaseId.value;
    DateTime? startTime = id.isNotEmpty ? _searchStartTimes[id] : null;

    if (startTime != null) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final remaining = (300 - elapsed).clamp(0, 300);
      searchCountdown.value = remaining;
    } else {
      searchCountdown.value = 300;
      if (id.isNotEmpty) {
        _searchStartTimes[id] = DateTime.now();
      }
    }

    showRetryOption.value = searchCountdown.value == 0;

    _searchCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosing.value || stage.value != BookingStage.finding) {
        timer.cancel();
        return;
      }

      if (searchCountdown.value > 0) {
        searchCountdown.value--;
      } else {
        timer.cancel();
        showRetryOption.value = true;
      }
    });
  }

  void _stopSearchTimer() {
    _searchCountdownTimer?.cancel();
    _searchCountdownTimer = null;
  }

  void _adjustSearchCountdown(DateTime startTime) {
    if (isClosing.value || stage.value != BookingStage.finding) return;

    final id = rideDatabaseId.value;
    if (id.isNotEmpty) {
      _searchStartTimes[id] = startTime;
    }

    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final remaining = (300 - elapsed).clamp(0, 300);
    if (remaining > 0) {
      searchCountdown.value = remaining;
      showRetryOption.value = false;
    } else {
      searchCountdown.value = 0;
      showRetryOption.value = true;
      _stopSearchTimer();
    }
  }

  void startPaymentStatusPolling() {
    if (_paymentPollTimer != null) return;
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (rideDatabaseId.value.isEmpty || isClosing.value || stage.value != BookingStage.tripCompleted) {
        timer.cancel();
        _paymentPollTimer = null;
        return;
      }
      fetchRideDetails(rideDatabaseId.value);
    });
  }

  void retrySearch() {
    if (rideDatabaseId.value.isNotEmpty) {
      _searchStartTimes.remove(rideDatabaseId.value);
    }
    _startSearchTimer();
    // Re-trigger driver search via socket if needed,
    // but the backend usually keeps searching if not cancelled.
    // If backend has a separate timeout, we might need an API call here.
    // Assuming backend keeps it open until 'Cancelled'.
  }

  Future<void> _saveBookingId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_booking_id', id);
  }

  Future<void> _clearBookingId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_booking_id');
  }

  Future<void> _tryRehydrateOrFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('active_booking_id');
    if (savedId != null && savedId.isNotEmpty) {
      rideDatabaseId.value = savedId;
      fetchRideDetails(savedId);
      listenToRideUpdates(savedId);
    } else {
      // ✅ HARD FIX: If no ID is passed and no saved ID exists, DO NOT create a new ride.
      // Simply go back to home to avoid "phantom" ride searches appearing.
      Future.microtask(() => Get.offAllNamed(Routes.home));
    }
  }

  void _setupMapWorkers() {
    // We removed 'ever' workers that were snapping camera bounds on every update.
    // Camera updates should now be manual or triggered only on stage transitions.
    ever(stage, (_) {
      _boundsFittedOnce = false;
      _boundsFittedForTrip = false;
      _fitBounds();
      _fetchRoutes(); // Ensure polylines are refreshed when stage changes
    });
  }

  void _fitBounds({bool force = false}) {
    if (_attachedMapController == null || isClosing.value) return;
    if (_boundsFittedOnce && !force) return;

    List<LatLng> points = [];
    if (stage.value == BookingStage.accepted && routeToPickup.isNotEmpty) {
      points = routeToPickup.toList();
    } else if ((stage.value == BookingStage.arrived || stage.value == BookingStage.tripStarted) &&
        routeToDropoff.isNotEmpty) {
      if (_boundsFittedForTrip && !force) return;
      points = routeToDropoff.toList();
      _boundsFittedForTrip = true;
    } else {
      // Fallback: use user position and pickup if finding
      if (Get.isRegistered<MapController>()) {
        final mapC = Get.find<MapController>();
        if (mapC.currentPosition.value != null) {
          points.add(mapC.currentPosition.value!);
        }
      }
      if (pickupLat.value != 0) {
        points.add(LatLng(pickupLat.value, pickupLng.value));
      }
    }

    if (points.isEmpty) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    try {
      _attachedMapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          70,
        ),
      );
      _boundsFittedOnce = true;
    } catch (e) {
      debugPrint("Error fitting bounds: $e");
    }
  }

  BookingStage _mapStatusToStage(String? status) {
    switch (status) {
      case 'Accepted':
        return BookingStage.accepted;
      case 'Arrived':
        return BookingStage.arrived;
      case 'Ongoing':
        return BookingStage.tripStarted;
      case 'Completed':
        return BookingStage.tripCompleted;
      default:
        return BookingStage.finding;
    }
  }

  Future<void> fetchRideDetails(String id) async {
    try {
      final res = await ApiService.getRideById(id);
      if (res.containsKey('error')) return;

      final ride = res['data'] ?? res;
      if (ride != null) {
        rideDatabaseId.value = ride['_id']?.toString() ?? id;
        final newStatus = ride['status'] as String?;
        final paymentStatus = ride['paymentStatus'] as String? ?? 'Pending';
        final fareValue = (ride['fare'] as num?)?.toDouble() ?? 0.0;

        if (newStatus == 'Cancelled' && paymentStatus == 'Pending' && fareValue > 0) {
          isCancellationPaymentFlow.value = true;
          stage.value = BookingStage.tripCompleted;
        } else {
          stage.value = _mapStatusToStage(newStatus);
        }

        if (stage.value == BookingStage.accepted && !_isOtpShown) {
          _isOtpShown = true;
          // Redundant navigation removed
        }

        if (ride['pickupCoords'] != null) {
          pickupLat.value = (ride['pickupCoords']['lat'] as num).toDouble();
          pickupLng.value = (ride['pickupCoords']['lng'] as num).toDouble();
        }
        if (ride['dropoffCoords'] != null) {
          dropoffLat.value = (ride['dropoffCoords']['lat'] as num).toDouble();
          dropoffLng.value = (ride['dropoffCoords']['lng'] as num).toDouble();
        }
        
        if (ride['pickupLocation'] != null && pickup.isEmpty) {
           pickup.value = ride['pickupLocation'].toString();
        }
        if (ride['dropoffLocation'] != null && destination.isEmpty) {
           destination.value = ride['dropoffLocation'].toString();
        }

        if (ride['fare'] != null) {
          finalFare.value = (ride['fare'] as num).toDouble();
          originalRideFare.value = finalFare.value; // preserve for cancellation fee
        }
        if (ride['otp'] != null) {
          otp.value = ride['otp'].toString();
        }
        if (ride['requireCarWash'] != null) {
          requireCarWash.value = ride['requireCarWash'] == true;
        }
        if (ride['carWashPrice'] != null) {
          carWashPrice.value = (ride['carWashPrice'] as num).toDouble();
        }

        // Fix consistency: carType, transmission, etc.
        carType.value = ride['carType'] ?? "Car";
        transmission.value = ride['transmission'] ?? "Manual";
        tripType.value = ride['tripType'] ?? "Round Trip";
        carModelRequested.value = ride['carModel'] ?? "";
        package.value = ride['carPackage'] ?? "";
        distanceCost.value = (ride['distanceCost'] as num?)?.toDouble() ?? 0.0;
        hourlyCost.value = (ride['hourlyCost'] as num?)?.toDouble() ?? 0.0;

        // Format times
        if (ride['createdAt'] != null) {
          final date = DateTime.parse(ride['createdAt'].toString()).toLocal();
          bookingTime.value =
              "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
        }

        final String? rawTime = ride['updatedAt'] ?? ride['createdAt'];
        if (rawTime != null) {
          final timeDate = DateTime.parse(rawTime).toLocal();
          if (stage.value == BookingStage.finding) {
            _adjustSearchCountdown(timeDate);
          }
        }
        isScheduled.value = ride['isScheduled'] == true;
        if (ride['scheduledAt'] != null) {
          final date = DateTime.parse(ride['scheduledAt'].toString()).toLocal();
          scheduledTime.value =
              "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
        }
        if (ride['completedAt'] != null) {
          final date = DateTime.parse(ride['completedAt'].toString()).toLocal();
          completionTime.value =
              "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
        } else {
          completionTime.value = "";
        }
        if (ride['arrivedAt'] != null) {
          final date = DateTime.parse(ride['arrivedAt'].toString()).toLocal();
          arrivalTime.value =
              "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
        } else {
          arrivalTime.value = "";
        }
        if (ride['startedAt'] != null) {
          final date = DateTime.parse(ride['startedAt'].toString()).toLocal();
          tripStartTime.value =
              "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
        } else {
          tripStartTime.value = "";
        }

        String bId = ride['booking_id']?.toString() ?? "";
        if (bId.isEmpty) {
          final idStr = ride['_id']?.toString() ?? "";
          final last8 = idStr
              .substring((idStr.length - 8).clamp(0, idStr.length))
              .toUpperCase();
          bId = "RID$last8";
        }
        bookingId.value = bId;

        // Real driver details
        final driver = ride['driverId'];
        if (driver != null && driver is Map) {
          driverName.value = driver['name'] ?? "Driver";
          driverId.value = driver['_id']?.toString() ?? "";
          driverImage.value = ApiService.getImageUrl(
            driver['profileImage']?.toString(),
          );
          carNumber.value = driver['vehicleNumber'] ?? "";
          carModel.value = driver['vehicleModel'] ?? "";
          driverMobile.value =
              driver['phone']?.toString() ?? driver['mobile']?.toString() ?? "";
          final double total = (driver['totalRating'] ?? 0.0).toDouble();
          final int count = (driver['ratingCount'] ?? 0).toInt();
          driverRating.value = count > 0 ? (total / count).toStringAsFixed(1) : "0.0";
          driverExp.value = "${driver['expYear'] ?? '0'} year of exp";

          // Try to extract initial driver location from multiple common fields
          double? dLat, dLng;
          if (ride['driverLocation'] != null) {
            dLat = (ride['driverLocation']['lat'] as num?)?.toDouble();
            dLng = (ride['driverLocation']['lng'] as num?)?.toDouble();
          } else if (driver['location'] != null) {
            dLat = (driver['location']['lat'] as num?)?.toDouble();
            dLng = (driver['location']['lng'] as num?)?.toDouble();
          } else if (ride['driverCoords'] != null) {
            dLat = (ride['driverCoords']['lat'] as num?)?.toDouble();
            dLng = (ride['driverCoords']['lng'] as num?)?.toDouble();
          }

          if (dLat != null && dLng != null && dLat != 0) {
            driverLat.value = dLat;
            driverLng.value = dLng;
          }
        }

        // Real pricing details
        if (ride['packageHours'] != null) {
          hourlyPackage.value = "${ride['packageHours']} hours";
        }
        if (ride['extraTimeUsed'] != null) {
          extraTimeUsed.value = "${ride['extraTimeUsed']} min";
        }
        if (ride['estimatedTime'] != null) {
          int mins = int.tryParse(ride['estimatedTime'].toString()) ?? 0;
          estimatedTime.value = mins > 0 ? _formatDuration(mins) : "${ride['estimatedTime']} min";
        }
        if (ride['hourlyRate'] != null) {
          hourlyRate.value = "₹ ${ride['hourlyRate']}/hour";
        }
        if (ride['actualDuration'] != null) {
          int mins = (ride['actualDuration'] as num).toInt();
          tripDuration.value = _formatDuration(mins);
        }

        debugPrint(
          "Rider: Initial Driver Loc Found: ${driverLat.value}, ${driverLng.value}",
        );
        debugPrint(
          "Rider: Pickup Coords: ${pickupLat.value}, ${pickupLng.value}",
        );
        _fetchRoutes();

        if (paymentStatus == 'Completed') {
          isWaitingForCashConfirmation.value = false;
          _paymentPollTimer?.cancel();
          _paymentPollTimer = null;
          if (newStatus == 'Cancelled') {
            _finalCleanupAndGoHome();
          } else {
            _finishRideFlow();
          }
          return;
        }

        if (stage.value == BookingStage.tripCompleted) {
          startPaymentStatusPolling();
        }
      }
    } catch (e) {
      debugPrint("Error fetching ride details: $e");
    }
  }

  void _fetchRoutes() async {
    if (isClosing.value) return;

    final start = LatLng(driverLat.value, driverLng.value);
    final pick = LatLng(pickupLat.value, pickupLng.value);
    final drop = LatLng(dropoffLat.value, dropoffLng.value);

    debugPrint("Rider: _fetchRoutes called Stage=${stage.value}");
    debugPrint("Rider: Coordinates: Start=$start, Pick=$pick, Drop=$drop");

    // PROXIMITY CHECK: If driver and target are extremely close (< 15m), 
    // clear the route to avoid messy or misleading routing lines.
    if (stage.value == BookingStage.accepted && start.latitude != 0 && pick.latitude != 0) {
      double d = Geolocator.distanceBetween(start.latitude, start.longitude, pick.latitude, pick.longitude);
      if (d < 15) {
        routeToPickup.clear();
        etaToPickup.value = "0 min";
        return;
      }
    } else if (stage.value == BookingStage.tripStarted && start.latitude != 0 && drop.latitude != 0) {
      double d = Geolocator.distanceBetween(start.latitude, start.longitude, drop.latitude, drop.longitude);
      if (d < 20) { // Slightly larger threshold for destination
        routeToDropoff.clear();
        etaToDropoff.value = "0 min";
        return;
      }
    }

    if (stage.value == BookingStage.accepted) {
      routeToDropoff.clear(); // Clear any pre-fetched route to destination
      if (start.latitude != 0 && pick.latitude != 0) {
        RoutingService.getRoute(start, pick).then((r) {
          if (!isClosing.value && r != null) {
            routeToPickup.assignAll(r.points);
            final min = (r.duration / 60).ceil();
            etaToPickup.value = _formatDuration(min);
            debugPrint(
              "Rider: Got ROUTE_TO_PICKUP, points=${r.points.length}, duration=$min min",
            );
            _fitBounds(force: true); // Auto-zoom to show the route
          }
        });
      }
    }

    if (stage.value == BookingStage.arrived || stage.value == BookingStage.tripStarted) {
      if (start.latitude != 0 && drop.latitude != 0) {
        RoutingService.getRoute(start, drop).then((r) {
          if (!isClosing.value && r != null) {
            routeToDropoff.assignAll(r.points);
            final min = (r.duration / 60).ceil();
            etaToDropoff.value = _formatDuration(min);
            debugPrint(
              "Rider: Got DYNAMIC_ROUTE_TO_DROPOFF (Driver to Destination), points=${r.points.length}, duration=$min min",
            );
            _fitBounds(force: true); // Auto-zoom to show updated route
          }
        });
      }
    }

    // Only fallback fetch pickup -> dropoff if specifically needed and in correct stage
    if (stage.value != BookingStage.accepted && stage.value != BookingStage.finding &&
        pick.latitude != 0 && drop.latitude != 0 && routeToDropoff.isEmpty) {
      RoutingService.getRoute(pick, drop).then((r) {
        if (!isClosing.value && r != null && routeToDropoff.isEmpty) {
          routeToDropoff.assignAll(r.points);
          final min = (r.duration / 60).ceil();
          etaToDropoff.value = _formatDuration(min);
        }
      });
    }
  }

  void _onDriverLocationUpdate(double lat, double lng) {
    if (lat == 0 || lng == 0) return;

    // Record the actual path for trip history
    if (stage.value != BookingStage.finding && stage.value != BookingStage.tripCompleted) {
       final newPoint = LatLng(lat, lng);
       if (actualPath.isEmpty) {
         actualPath.add(newPoint);
       } else {
         final lastPoint = actualPath.last;
         final distance = Geolocator.distanceBetween(
           lastPoint.latitude, lastPoint.longitude,
           newPoint.latitude, newPoint.longitude
         );
         if (distance > 2) { // Only record if moved significantly (2m)
            actualPath.add(newPoint);
         }
       }
    }

    if (displayDriverLat.value == 0) {
      displayDriverLat.value = lat;
      displayDriverLng.value = lng;
    } else {
      // Update rotation (with 180° correction for the asset orientation)
      double bearing = Geolocator.bearingBetween(
        displayDriverLat.value, displayDriverLng.value, lat, lng
      );
      displayDriverRotation.value = (bearing + 180) % 360;
      _animateTo(lat, lng);
    }

    driverLat.value = lat;
    driverLng.value = lng;

    // No live distance string update (ETA minutes only)


    // Fetch routes with debounce to avoid excessive API calls
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(seconds: 2), () {
      _fetchRoutes();
    });
  }

  void _animateTo(double targetLat, double targetLng) {
    _lerpTimer?.cancel();
    final startLat = displayDriverLat.value;
    final startLng = displayDriverLng.value;

    if (startLat != 0) {
      // Calculate rotation based on travel direction (with 180° correction)
      double b = Geolocator.bearingBetween(
        startLat, startLng, targetLat, targetLng
      );
      displayDriverRotation.value = (b + 180) % 360;
    }

    int steps = 20; // Slightly faster (1 second) for responsiveness
    int currentStep = 0;

    _lerpTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (isClosing.value || !Get.isRegistered<FindingDriverController>()) {
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
      // Linear interpolation (could use ease-in-out for more juice)
      displayDriverLat.value = startLat + (targetLat - startLat) * t;
      displayDriverLng.value = startLng + (targetLng - startLng) * t;
    });
  }

  void stopMapAnimation() {}

  void listenToRideUpdates(String id) {
    if (isClosing.value) return;

    final socketService = Get.find<SocketService>();

    // CRITICAL: Join the ride room to receive updates
    socketService.joinRide(id);
    debugPrint("Rider: Joined Socket Room for Ride: $id");

    if (_onStatusChanged != null)
      socketService.socket?.off('ride:status_changed', _onStatusChanged);
    if (_onDriverReached != null)
      socketService.socket?.off('driver:reached_pickup', _onDriverReached);
    if (_onLocationUpdate != null)
      socketService.socket?.off('ride:location_update', _onLocationUpdate);

    _onStatusChanged = (data) async {
      if (isClosing.value) return;
      print(
        '-- FindingDriverController received ride:status_changed: ${data?["status"]} for ride ${data?["_id"]} --',
      );

      if (data != null &&
          (data['_id'].toString() == id ||
              data['booking_id']?.toString() == id)) {
        final newStatus = data['status'];

        final pStatus = data['paymentStatus'];
        final pMethod = data['paymentMethod'];
        
        if (pMethod != null) {
          paymentMode.value = pMethod.toString();
          if (pMethod == 'Cash') {
            isWaitingForCashConfirmation.value = true;
          } else {
            isWaitingForCashConfirmation.value = false;
          }
        }
        
        if (pStatus == 'Completed') {
          isWaitingForCashConfirmation.value = false;
          _finishRideFlow();
          return;
        }

        if (pStatus == 'Disputed') {
          isWaitingForCashConfirmation.value = false;
          Get.snackbar(
            "Payment Dispute",
            "The driver has raised a dispute. Redirecting to home.",
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          Future.delayed(const Duration(seconds: 3), () {
            _finishRideFlow();
          });
          return;
        }

        // Update display ID if available
        String bId = data['booking_id']?.toString() ?? "";
        if (bId.isNotEmpty) {
          bookingId.value = bId;
        } else if (bookingId.value.isEmpty) {
          final idStr = data['_id']?.toString() ?? "";
          final last8 = idStr
              .substring((idStr.length - 8).clamp(0, idStr.length))
              .toUpperCase();
          bookingId.value = "RID$last8";
        }
        if (newStatus == 'Pending' || newStatus?.toString().toLowerCase() == 'cancelled_by_driver') {
          stage.value = BookingStage.finding;
          driverId.value = "";
          driverName.value = "";
          driverImage.value = "";
          carNumber.value = "";
          carModel.value = "";
          driverMobile.value = "";
          driverRating.value = "0.0";
          driverExp.value = "";
          driverLat.value = 0;
          driverLng.value = 0;
          displayDriverLat.value = 0;
          displayDriverLng.value = 0;
          routeToPickup.clear();
          etaToPickup.value = "";
          
          if (rideDatabaseId.value.isNotEmpty) {
            _searchStartTimes.remove(rideDatabaseId.value);
          }
          _startSearchTimer();

          Get.snackbar(
            "Driver Update",
            "Your driver cancelled. We are looking for another driver.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );

          debugPrint("Rider: Driver cancelled, ride returned to Pending/cancelled_by_driver stage. Restarting search UI.");
        } else if (newStatus == 'Accepted') {
          stage.value = BookingStage.accepted;

          if (data['otp'] != null) {
            otp.value = data['otp'].toString();
          }
          if (data['requireCarWash'] != null) {
            requireCarWash.value = data['requireCarWash'] == true;
          }
          if (data['carWashPrice'] != null) {
            carWashPrice.value = (data['carWashPrice'] as num).toDouble();
          }

          // Populate pricing/details
          carType.value = data['carType'] ?? "Car";
          transmission.value = data['transmission'] ?? "";
          tripType.value = data['tripType'] ?? "";
          carModelRequested.value = data['carModel'] ?? "";
          package.value = data['carPackage'] ?? "";

          if (data['createdAt'] != null) {
            final date = DateTime.parse(data['createdAt'].toString()).toLocal();
            bookingTime.value =
                "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
          }
          if (data['isScheduled'] != null) {
            isScheduled.value = data['isScheduled'] == true;
          }
          if (data['scheduledAt'] != null) {
            final date = DateTime.parse(
              data['scheduledAt'].toString(),
            ).toLocal();
            scheduledTime.value =
                "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
          }

          // Redundant OTP page navigation removed as per user request

          if (data['driverId'] != null) {
            // FORCE: Re-fetch everything properly to get driver coordinates etc.
            fetchRideDetails(id);
            
            // Initial self-location update immediately
            if (Get.isRegistered<MapController>()) {
               final m = Get.find<MapController>();
               if (m.currentPosition.value != null) {
                  ApiService.updateRideLocation(
                    id, 'customer', 
                    m.currentPosition.value!.latitude, 
                    m.currentPosition.value!.longitude
                  ).catchError((e) {
                    debugPrint("Error updating rider loc on Accept: $e");
                    return <String, dynamic>{};
                  });
               }
            }
            
            _stopSearchTimer();
            _fetchRoutes();
          }
          debugPrint(
            "Rider: Status Changed to Accepted. Driver Loc: ${driverLat.value}, ${driverLng.value}",
          );
        } else if (newStatus == 'Arrived') {
          debugPrint("Rider: status_changed to Arrived");
          stage.value = BookingStage.arrived;
          fetchRideDetails(id);
        } else if (newStatus == 'Ongoing') {
          debugPrint("Rider: status_changed to Ongoing (Trip Started)");
          stage.value = BookingStage.tripStarted;
          fetchRideDetails(id);
          
          // Force UI refresh and route update
          _boundsFittedForTrip = false;
          _fetchRoutes();
          _fitBounds(force: true);
        } else if (newStatus == 'Completed') {
          if (data['fare'] != null) {
            finalFare.value = (data['fare'] as num).toDouble();
          }
          if (data['distance'] != null) {
            distance.value = "${data['distance']} km";
          }
          if (data['packageHours'] != null) {
            hourlyPackage.value = "${data['packageHours']} hours";
          }
          if (data['extraTimeUsed'] != null) {
            extraTimeUsed.value = "${data['extraTimeUsed']} min";
          }
          if (data['estimatedTime'] != null) {
            int mins = int.tryParse(data['estimatedTime'].toString()) ?? 0;
            estimatedTime.value = mins > 0 ? _formatDuration(mins) : "${data['estimatedTime']} min";
          }
          if (data['hourlyRate'] != null) {
            hourlyRate.value = "₹ ${data['hourlyRate']}/hour";
          }
          if (data['actualDuration'] != null) {
            int mins = (data['actualDuration'] as num).toInt();
            tripDuration.value = _formatDuration(mins);
          }
          if (data['completedAt'] != null) {
            final date = DateTime.parse(
              data['completedAt'].toString(),
            ).toLocal();
            completionTime.value =
                "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
          }
          stage.value = BookingStage.tripCompleted;
          fetchRideDetails(id); // Get all timestamps updated
          // ✅ HARD FIX: Clear local saved ID because the ride is finished
          _clearBookingId();
        } else if (newStatus?.toString().toLowerCase() == 'cancelled') {
          try {
            final res = await ApiService.getRideById(id);
            final ride = res['data'] ?? res;
            if (ride != null) {
              final pStatus = ride['paymentStatus'] as String? ?? 'Pending';
              final fareVal = (ride['fare'] as num?)?.toDouble() ?? 0.0;
              if (pStatus == 'Pending' && fareVal > 0) {
                isCancellationPaymentFlow.value = true;
                stage.value = BookingStage.tripCompleted;
                finalFare.value = fareVal;
                
                try {
                  final settings = await ApiService.getPublicSettings();
                  final percent = double.tryParse(settings['cancellation_fee_percent']?.toString() ?? '') ?? 10.0;
                  cancellationFeePercent.value = percent;
                } catch (_) {}

                if (ride['packageHours'] != null) {
                  hourlyPackage.value = "${ride['packageHours']} hours";
                }
                if (ride['hourlyRate'] != null) {
                  hourlyRate.value = "₹ ${ride['hourlyRate']}/hour";
                }
                bookingId.value = ride['bookingId']?.toString() ?? '';
                carType.value = ride['carType']?.toString() ?? '';
                carModelRequested.value = ride['carModel']?.toString() ?? '';
                tripType.value = ride['tripType']?.toString() ?? '';
                
                stopAll(); 
                _clearBookingId();
                return;
              }
            }
          } catch (e) {
            debugPrint("Error checking cancellation details: $e");
          }

          if (!isClosing.value && !isCancelling.value) {
            Get.snackbar(
              "Ride Cancelled",
              "Your driver has cancelled this ongoing ride.",
              snackPosition: SnackPosition.TOP,
              backgroundColor: const Color(0xFFB84B4B),
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
            // Clean up and go home without calling API again
            _clearBookingId();
            isClosing.value = true;
            stopAll();
            Future.delayed(const Duration(milliseconds: 1500), () {
              Get.offAllNamed(Routes.home);
            });
          }
        }
      }
    };

    socketService.socket?.on('ride:status_changed', _onStatusChanged);

    _onDriverReached = (data) {
      if (isClosing.value) return;
      if (data != null &&
          data['rideId'].toString() == id &&
          !_isReachedSnackbarShown) {
        _isReachedSnackbarShown = true;
      }
    };
    socketService.socket?.on('driver:reached_pickup', _onDriverReached);

    _startLocationUpdates(id);

    _onLocationUpdate = (data) {
      if (isClosing.value) return;
      if (data != null && data['rideId'].toString() == id) {
        if (data['type'] == 'driver') {
          _onDriverLocationUpdate(
            (data['lat'] as num).toDouble(),
            (data['lng'] as num).toDouble(),
          );
        }
      }
    };
    socketService.socket?.on('ride:location_update', _onLocationUpdate);
  }

  void _startLocationUpdates(String id) {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      if (isClosing.value) {
        timer.cancel();
        return;
      }
      if (Get.isRegistered<MapController>()) {
        final mapC = Get.find<MapController>();
        final pos = mapC.currentPosition.value;
        if (pos != null) {
          try {
            await ApiService.updateRideLocation(
              id,
              'customer',
              pos.latitude,
              pos.longitude,
            );
          } catch (e) {}
        }
      }
    });
  }

  Future<void> createRealRide() async {
    final res = await ApiService.createRide(
      pickupLocation: pickup.value,
      dropoffLocation: destination.value,
      fare: 250.0,
      distance: 5.0,
      carType: car.value,
      package: package.value,
      pickupCoords: pickupLat.value != 0
          ? {'lat': pickupLat.value, 'lng': pickupLng.value}
          : null,
      dropoffCoords: dropoffLat.value != 0
          ? {'lat': dropoffLat.value, 'lng': dropoffLng.value}
          : null,
    );

    if (res.containsKey('error')) {
      Get.back();
      Get.snackbar(
        "Service Unavailable",
        res['error'] ?? "You are out of chennai boundary area.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final id = res['_id'] ?? res['data']?['_id'];
    if (id != null) {
      rideDatabaseId.value = id.toString();
      await _saveBookingId(rideDatabaseId.value);
      _searchStartTimes.remove(rideDatabaseId.value);
      _startSearchTimer();
      listenToRideUpdates(id.toString());
    }
  }

  @override
  void onClose() {
    isClosing.value = true;
    stopAll();
    reasonTextController.dispose();
    super.onClose();
  }

  void stopAll() {
    _acceptTimer?.cancel();
    _tripStartTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _routeDebounce?.cancel();
    _paymentPollTimer?.cancel();
    _acceptTimer = null;
    _tripStartTimer = null;
    _locationUpdateTimer = null;
    _routeDebounce = null;
    _paymentPollTimer = null;
    _stopSearchTimer();

    if (Get.isRegistered<SocketService>()) {
      final ss = Get.find<SocketService>();
      if (_onStatusChanged != null)
        ss.socket?.off('ride:status_changed', _onStatusChanged);
      if (_onDriverReached != null)
        ss.socket?.off('driver:reached_pickup', _onDriverReached);
      if (_onLocationUpdate != null)
        ss.socket?.off('ride:location_update', _onLocationUpdate);
    }
  }

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      int hrs = minutes ~/ 60;
      int mins = minutes % 60;
      return "$hrs:${mins.toString().padLeft(2, '0')} hr";
    }
    return "$minutes min";
  }

  void _finalCleanupAndGoHome() {
    _clearBookingId();
    isClosing.value = true;
    stopAll();

    // Clear all ride-specific observables
    rideDatabaseId.value = "";
    bookingId.value = "";
    driverId.value = "";
    driverName.value = "";
    stage.value = BookingStage.finding;

    // Close ANY open snackbars or dialogs safely
    if (Get.isOverlaysOpen) {
      Get.closeAllSnackbars();
      if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
        Get.back();
      }
    }

    // Small delay to ensure snackbars/dialogs finish closing animations
    // before we do a massive stack reset (offAllNamed).
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.offAllNamed(Routes.home);
    });
  }

  Future<void> cancelRequest({String? reason}) async {
    if (isClosing.value || isCancelling.value) return;

    // Safety check: if rideDatabaseId is still empty, we might be in the middle of creation
    if (rideDatabaseId.value.isEmpty) {
      // Wait a bit to see if rideDatabaseId appears (max 5 seconds)
      isCancelling.value = true;
      int retry = 0;
      while (rideDatabaseId.value.isEmpty && retry < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        retry++;
      }
      if (rideDatabaseId.value.isEmpty) {
        isCancelling.value = false;
        return;
      }
    }

    isCancelling.value = true;

    try {
      // Clear old snackbars/toasts before showing cancel feedback
      Get.closeAllSnackbars();

      final res = await ApiService.updateRideStatus(
        rideDatabaseId.value,
        'Cancelled',
        reason: reason,
      );

      if (res.containsKey('error')) {
        // Error handling: FCM handles it
      } else {
        _finalCleanupAndGoHome();
      }
    } catch (e) {
      debugPrint("Error cancelling ride: $e");
    } finally {
      isCancelling.value = false;
    }
  }

  void openCancelReasonDialog() {
    if (isClosing.value) return;

    // If ride has not started yet, cancel directly without showing reason dialog
    if (stage.value == BookingStage.finding ||
        stage.value == BookingStage.accepted) {
      cancelRequest();
      return;
    }

    Get.dialog(
      EndTripReasonDialog(
        selectedReason: selectedReason,
        reasonController: reasonTextController,
        onClose: () => Get.back(),
        onSubmit: () => submitCancelReason(),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> submitCancelReason() async {
    if (isClosing.value) return;

    final reasonText = reasonTextController.text.trim();
    // Enforce reason validation ONLY IF the ride has already started (tripStarted)
    if (stage.value == BookingStage.tripStarted) {
      if (selectedReason.value == null && reasonText.isEmpty) {
        Get.snackbar(
          "Required",
          "Please select or write a reason for cancelling this trip",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
        );
        return;
      }
    }

    if (Get.isDialogOpen == true) Get.back();

    isCancellationPaymentFlow.value = true;

    if (stage.value == BookingStage.arrived || stage.value == BookingStage.tripStarted) {
      if (stage.value == BookingStage.arrived) {
        // Driver has arrived — cancellation charge applies.
        // Fetch the configured percentage from public settings.
        try {
          final settings = await ApiService.getPublicSettings();
          final percent = double.tryParse(settings['cancellation_fee_percent']?.toString() ?? '') ?? 10.0;
          cancellationFeePercent.value = percent;
          // Use the preserved original fare (not finalFare which might already be 0 or overwritten)
          final originalFare = originalRideFare.value > 0 ? originalRideFare.value : finalFare.value;
          final cancelCharge = (percent / 100.0) * originalFare;
          finalFare.value = cancelCharge.roundToDouble();
          debugPrint('[Cancel] Driver arrived — cancellation fee: ₹${finalFare.value} (${percent.toStringAsFixed(0)}% of ₹$originalFare)');
        } catch (e) {
          debugPrint('[Cancel] Could not fetch cancellation fee setting: $e. Defaulting to 10%.');
          final originalFare = originalRideFare.value > 0 ? originalRideFare.value : finalFare.value;
          finalFare.value = (originalFare * 0.10).roundToDouble();
        }
      }

      // Show loader
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.orange)),
        barrierDismissible: false,
      );

      try {
        final res = await ApiService.updateRideStatus(
          rideDatabaseId.value,
          'Cancelled',
          reason: selectedReason.value ?? reasonText,
        );
        if (!res.containsKey('error')) {
          final ride = res['data'] ?? res;
          if (ride != null && ride['fare'] != null) {
            finalFare.value = (ride['fare'] as num).toDouble();
          }
        }
      } catch (e) {
        debugPrint("Error updating ride status to Cancelled on backend: $e");
      } finally {
        if (Get.isDialogOpen == true) Get.back();
      }
    } else {
      finalFare.value = 0;
    }

    stage.value = BookingStage.tripCompleted;
  }

  Future<void> selectCashPayment() async {
    if (isClosing.value) return;
    isPaying.value = true;
    try {
      final res = await ApiService.updateRidePaymentMethod(
        rideDatabaseId.value,
        paymentMethod: 'Cash',
      );
      if (!res.containsKey('error')) {
        paymentMode.value = 'Cash';
        isWaitingForCashConfirmation.value = true;
        Get.snackbar(
          "Payment Method",
          "Cash payment selected. Please pay the driver ₹${finalFare.value.toStringAsFixed(0)} and wait for confirmation.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          "Error",
          res['error'] ?? "Failed to update payment method",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Error selecting cash payment: $e");
    } finally {
      isPaying.value = false;
    }
  }

  Future<void> selectOnlinePayment() async {
    if (isClosing.value) return;
    isPaying.value = true;
    try {
      final res = await ApiService.updateRidePaymentMethod(
        rideDatabaseId.value,
        paymentMethod: 'Online',
      );
      if (!res.containsKey('error')) {
        paymentMode.value = 'Online';
        isWaitingForCashConfirmation.value = false;
      } else {
        Get.snackbar(
          "Error",
          res['error'] ?? "Failed to update payment method",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Error selecting online payment: $e");
    } finally {
      isPaying.value = false;
    }
  }

  Future<void> makePayment() async {
    if (isClosing.value) return;
    if (isPaying.value) return;

    if (paymentMode.value == "Cash") {
      await selectCashPayment();
      return;
    }

    if (isCancellationPaymentFlow.value && finalFare.value <= 0) {
      _finalCleanupAndGoHome();
      return;
    }

    isPaying.value = true;
    try {
      final customerId = await ApiService.getCustomerId();
      if (customerId == null) {
        return;
      }

      final profile = await ApiService.getCustomerProfile(customerId);
      if (profile.containsKey('error')) {
        return;
      }

      final String phone = profile['phone'] ?? "";
      final String email = profile['email'] ?? "";

      // Initialize payment
      await _paymentService.startPayment(
        amount: finalFare.value.toDouble(),
        description: "Ride Payment for ${bookingId.value}",
        userPhone: phone,
        userEmail: email,
        onSuccess: (paymentId) async {
          Get.dialog(
            const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
            barrierDismissible: false,
          );

          // Update payment status on backend
          final updateRes = await ApiService.updateRidePayment(
            rideDatabaseId.value,
            paymentId: paymentId,
            paymentStatus: 'Completed',
          );

          Get.back(); // close loading

          if (updateRes.containsKey('error')) {
            // Background notification handles failure
          }

          if (isCancellationPaymentFlow.value) {
            _finalCleanupAndGoHome();
          } else {
            _finishRideFlow();
          }
        },
        onFailure: (error) {
          // Failure handled by FCM
        },
      );
    } catch (e) {
      // Failure handled by FCM
    } finally {
      isPaying.value = false;
    }
  }

  void _finishRideFlow() {
    isClosing.value = true;
    _clearBookingId();

    // Create RideItem object for dialog
    final rideObj = RideItem(
      section: "",
      dateText: "",
      timeText: "",
      address: pickup.value,
      driverName: driverName.value,
      driverProfileImage: driverImage.value.isEmpty ? null : driverImage.value,
      amount: finalFare.value,
      status: RideStatus.completed,
      paymentMode: paymentMode.value,
      rawId: rideDatabaseId.value,
      rawDriverId: driverId.value,
    );

    stopAll();

    // Show rating dialog after a short delay
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (isFeedbackShown.value) return;

      if (rideObj.rawId != null &&
          rideObj.rawDriverId != null &&
          rideObj.rawDriverId!.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final isLocallyRated = prefs.getBool('rated_${rideObj.rawId}') ?? false;

        if (!rideObj.isDriverRated && !isLocallyRated) {
          isFeedbackShown.value = true;
          Get.dialog(
            DriverRatingDialog(
              ride: rideObj,
              onComplete: () {
                Get.offAllNamed(Routes.home);
              },
            ),
            barrierDismissible: false,
          );
        } else {
          Get.offAllNamed(Routes.home);
        }
      } else {
        Get.offAllNamed(Routes.home);
      }
    });
  }

  void callDriver() async {
    if (driverMobile.value.isEmpty) {
      return;
    }
    final Uri url = Uri(scheme: 'tel', path: driverMobile.value);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
    }
  }

  void shareTrip() {
    final text =
        "My Ride Details:\n"
        "Booking ID: ${bookingId.value}\n"
        "Driver: ${driverName.value}\n"
        "Vehicle: ${carNumber.value} (${carModel.value})\n"
        "Pickup: ${pickup.value}\n"
        "Destination: ${destination.value}";
    Share.share(text, subject: 'Rider Trip Info');
  }

  void showOtpPage() {
    // Disabled navigation to full-screen OTP page; OTP is visible in bottom sheet
    // Get.toNamed(Routes.rideOtp);
  }
}

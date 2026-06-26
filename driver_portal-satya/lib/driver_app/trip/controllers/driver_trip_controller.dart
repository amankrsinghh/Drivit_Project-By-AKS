import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../routes/driver_routes.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../views/enter_otp_dialog.dart';
import '../views/reason_dialog.dart';
import '../../../services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/customer_rating_dialog.dart';
import '../../../services/routing_service.dart';
import '../../../services/socket_service.dart';

class DriverTripController extends GetxController {
  // Current trip data (set when ride is accepted)
  final pickup = "Adyar, 4th Main Road...".obs;
  final drop = "T Nagar, Chennai...".obs;
  final bookingId = "".obs;
  final status = "".obs; // Add status tracking

  // State Getters
  bool get isAccepted => status.value.toLowerCase() == 'accepted' || status.value.toLowerCase() == 'arrived';
  bool get isOngoing => status.value.toLowerCase() == 'tripstarted' || status.value.toLowerCase() == 'ongoing';
  bool get isCompleted => status.value.toLowerCase() == 'completed';
  final customerName = "Customer".obs;
  final customerId = "".obs;
  final customerImage = "".obs;
  final customerRating = "0.0".obs;
  final customerPhone = "".obs;
  final carNumber = "TG10A9856".obs;
  final finalFare = 0.0.obs;
  final tripDuration = "".obs;
  final distance = "".obs;
  final paymentMode = "Cash".obs;
  final requireCarWash = false.obs;
  final isScheduled = false.obs;
  final scheduledAt = "".obs;
  final tripStartTime = "".obs;
  final tripEndTime = "".obs;
  final arrivalTime = "".obs;

  // Real pricing details
  final hourlyPackage = "0 hours".obs;
  final extraTimeUsed = "0 min".obs;
  final estimatedTime = "0 min".obs;
  final hourlyRate = "₹ 0/hour".obs;
  final carWashPrice = 0.0.obs;
  final distanceCost = 0.0.obs;
  final hourlyCost = 0.0.obs;
  final platformCharge = 0.0.obs;
  final gst = 0.0.obs;

  // Car/Vehicle Details
  final carModel = "SUV".obs;
  final carType = "Standard".obs;
  final transmission = "Automatic".obs;
  final tripType = "One Way".obs;

  // Real coordinates for the map
  final pickupLat = 0.0.obs;
  final pickupLng = 0.0.obs;
  final dropoffLat = 0.0.obs;
  final dropoffLng = 0.0.obs;
  final driverLat = 0.0.obs;
  final driverLng = 0.0.obs;
  
  // Smooth movement
  final displayDriverLat = 0.0.obs;
  final displayDriverLng = 0.0.obs;
  final rotation = 0.0.obs;
  Timer? _lerpTimer;
  Timer? _paymentPollTimer;

  // Real routes
  final routeToPickup = <LatLng>[].obs;
  final routeToDropoff = <LatLng>[].obs;

  final distanceToUser = "".obs;

  // Backend ride ID (for API calls)
  final currentRideId = "".obs;
  
  // Custom marker for map
  final driverIcon = Rxn<BitmapDescriptor>();

  // Socket listener callbacks to prevent memory leaks and duplicate triggers
  Function(dynamic)? _statusChangedHandler;
  Function(dynamic)? _paymentMethodChangedHandler;
  Function(dynamic)? _riderLocationHandler;


  // Quick Check toggles
  final qcCleanCar = true.obs;
  final qcDentScratch = true.obs;
  final qcConfirmDamage = true.obs;
  final qcDamageImages = <String>[].obs; // paths

  final otpC = TextEditingController();
  final otpFocusNode = FocusNode();
  final isUpdating = false.obs;
  final isCancelling = false.obs;

  final isVerifyingOtp = false.obs;
  final isStartingTrip = false.obs; // true from Start Trip tap → OTP dialog shown
  final isCompletingRide = false.obs;
  final isPaymentCollected = false.obs;
  final isFeedbackShown = false.obs;
  bool _isNavigatingHome = false;
  
  StreamSubscription<Position>? _positionStream;
  DateTime? _lastRouteFetchTime;
  Position? _lastSentPos;

  bool get isQuickCheckValid {
    // 1. Clean the car check must be true
    if (!qcCleanCar.value) return false;
    
    // 2. If dent/scratch is found, image must be uploaded
    if (qcDentScratch.value && qcDamageImages.isEmpty) return false;

    // 3. Confirm damage with customer must be true
    if (!qcConfirmDamage.value) return false;

    return true;
  }

  Future<void> pickQCImage() async {
    if (qcDamageImages.length >= 3) {
      return;
    }

    Get.bottomSheet(
      Container(
        color: Colors.white,
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Get.back();
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.camera);
                if (image != null && qcDamageImages.length < 3) {
                  qcDamageImages.add(image.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Get.back();
                final picker = ImagePicker();
                final List<XFile> images = await picker.pickMultiImage();
                for (var img in images) {
                  if (qcDamageImages.length < 3) {
                    qcDamageImages.add(img.path);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void removeQCImage(int index) {
    if (index >= 0 && index < qcDamageImages.length) {
      qcDamageImages.removeAt(index);
    }
  }

  @override
  void onInit() {
    super.onInit();
    final paramRideId = Get.parameters['rideId'];
    if (paramRideId != null && paramRideId.isNotEmpty) {
      _fetchAndLoadRide(paramRideId);
    }
    _loadDriverMarker();
  }

  @override
  void onClose() {
    otpC.dispose();
    _positionStream?.cancel();
    _lerpTimer?.cancel();
    _paymentPollTimer?.cancel();
    
    final socketService = Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;
    if (socketService != null && socketService.socket != null) {
      if (_statusChangedHandler != null) {
        socketService.socket!.off('ride:status_changed', _statusChangedHandler);
      }
      if (_paymentMethodChangedHandler != null) {
        socketService.socket!.off('ride:payment_method_changed', _paymentMethodChangedHandler);
      }
      if (_riderLocationHandler != null) {
        socketService.socket!.off('ride:location_update', _riderLocationHandler);
      }
      if (currentRideId.value.isNotEmpty) {
        socketService.leaveRide(currentRideId.value);
      }
    }
    super.onClose();
  }


  void _loadDriverMarker() async {
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
      debugPrint("Error loading trip driver PNG icon: $e");
    }
  }

  Future<void> _fetchAndLoadRide(String rideId) async {
    isUpdating.value = true;
    try {
      final ride = await ApiService.getRide(rideId);
      
      if (ride['error'] == null) {
        final status = ride['status']?.toString() ?? '';
        final pStatus = ride['paymentStatus']?.toString() ?? '';
        final statusLower = status.toLowerCase();
        final pStatusLower = pStatus.toLowerCase();
        final double fareVal = (ride['fare'] as num?)?.toDouble() ?? 0.0;

        bool isResumable = ['accepted', 'arrived', 'ongoing', 'tripstarted'].contains(statusLower) ||
                           (statusLower == 'completed' && pStatusLower == 'pending') ||
                           (statusLower == 'cancelled' && pStatusLower == 'pending' && fareVal > 0);

        if (!isResumable) {
          debugPrint("DriverTripController: Ride $rideId is already $status with payment status $pStatus. Ignoring.");
          goHomeTab(); 
          return;
        }
        loadRide(ride);

        if (statusLower == 'completed' || statusLower == 'cancelled') {
          startPaymentStatusPolling();
        }

        // Ensure we have initial locations for display
        if (driverLat.value != 0 && displayDriverLat.value == 0) {
            displayDriverLat.value = driverLat.value;
            displayDriverLng.value = driverLng.value;
        }
      } else {
        debugPrint("DriverTripController: Ride not found or error. Going home.");
        goHomeTab();
      }
    } catch (e) {
      debugPrint("Error fetching persisted ride: $e");
    } finally {
      isUpdating.value = false;
    }
  }


  /// Load trip data from a ride object (from API or elsewhere)
  void loadRide(Map<String, dynamic> ride) {
    // Reset ALL operational flags for a fresh trip state
    isVerifyingOtp.value = false;
    isStartingTrip.value = false;
    isCompletingRide.value = false;
    isPaymentCollected.value = false;
    isUpdating.value = false;
    isFeedbackShown.value = false;
    _isNavigatingHome = false;

    currentRideId.value = ride['_id']?.toString() ?? '';
    status.value = ride['status']?.toString() ?? '';
    
    // Fix bookingId consistency: prioritize booking_id field, then fallback to RID+last8
    String bId = ride['booking_id']?.toString() ?? "";
    if (bId.isEmpty) {
      bId = currentRideId.value.substring((currentRideId.value.length - 8).clamp(0, currentRideId.value.length)).toUpperCase();
    }
    bookingId.value = bId.startsWith("RID") ? bId : "RID$bId";

    pickup.value = ride['pickupLocation'] as String? ?? 'Unknown pickup';
    drop.value = ride['dropoffLocation'] as String? ?? 'Unknown dropoff';
    finalFare.value = (ride['fare'] ?? 0.0).toDouble();
    distance.value = ride['distance'] != null ? '${ride['distance']} km' : '--';
    tripType.value = ride['tripType']?.toString() ?? 'One Way';

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
    distanceCost.value = (ride['distanceCost'] ?? 0.0).toDouble();
    hourlyCost.value = (ride['hourlyCost'] ?? 0.0).toDouble();
    platformCharge.value = (ride['platformCharge'] ?? 0.0).toDouble();
    gst.value = (ride['gst'] ?? 0.0).toDouble();
    if (ride['actualDuration'] != null) {
      int mins = (ride['actualDuration'] as num).toInt();
      tripDuration.value = _formatDuration(mins);
    }

    paymentMode.value = ride['paymentMethod']?.toString() ?? 'Online';
    isPaymentCollected.value = ride['paymentStatus']?.toString() == 'Completed';
    requireCarWash.value = ride['requireCarWash'] == true;
    carWashPrice.value = (ride['carWashPrice'] ?? 0.0).toDouble();
    
    // Load Car/Vehicle Details from ride
    carType.value = ride['carType']?.toString() ?? 'Standard';
    carModel.value = ride['carModel']?.toString() ?? 'SUV';
    transmission.value = ride['transmission']?.toString() ?? 'Automatic';

    isScheduled.value = ride['isScheduled'] == true;
    if (ride['scheduledAt'] != null) {
      final date = DateTime.parse(ride['scheduledAt'].toString()).toLocal();
      scheduledAt.value = "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    if (ride['arrivedAt'] != null) {
      final date = DateTime.parse(ride['arrivedAt'].toString()).toLocal();
      arrivalTime.value = "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else {
      arrivalTime.value = "";
    }
    if (ride['startedAt'] != null) {
      final date = DateTime.parse(ride['startedAt'].toString()).toLocal();
      tripStartTime.value = "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else {
      tripStartTime.value = "";
    }
    if (ride['completedAt'] != null) {
      final date = DateTime.parse(ride['completedAt'].toString()).toLocal();
      tripEndTime.value = "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else {
      tripEndTime.value = "";
    }

    final customer = ride['customerId'];
    if (customer is Map) {
      customerName.value = customer['name']?.toString() ?? 'Customer';
      customerId.value = customer['_id']?.toString() ?? '';
      customerImage.value = customer['profileImage']?.toString() ?? '';
      customerPhone.value = customer['phone']?.toString() ?? '';
      
      // Fallback vehicle/car values if not explicitly on ride
      if (ride['carType'] == null) {
        carType.value = customer['carType']?.toString() ?? 'Standard';
      }
      if (ride['carModel'] == null) {
        carModel.value = customer['carModel']?.toString() ?? 'SUV';
      }
      if (ride['transmission'] == null) {
        transmission.value = customer['transmission']?.toString() ?? 'Automatic';
      }

      final double ratingVal = (customer['rating'] ?? 0.0).toDouble();
      if (ratingVal > 0) {
        customerRating.value = ratingVal.toStringAsFixed(1);
      } else {
        final double total = (customer['totalRating'] ?? 0.0).toDouble();
        final int count = (customer['ratingCount'] ?? 0).toInt();
        customerRating.value = count > 0 ? (total / count).toStringAsFixed(1) : "0.0";
      }
    }

    // Load coordinates with robust key handling and DEEP LOGGING
    double pLat = 0, pLng = 0, dLat = 0, dLng = 0;

    if (ride['pickupCoords'] != null) {
      pLat = (ride['pickupCoords']['lat'] as num).toDouble();
      pLng = (ride['pickupCoords']['lng'] as num).toDouble();
    } else if (ride['pickupLat'] != null) {
      pLat = (ride['pickupLat'] as num).toDouble();
      pLng = (ride['pickupLng'] as num).toDouble();
    }
    
    if (ride['dropoffCoords'] != null) {
      dLat = (ride['dropoffCoords']['lat'] as num).toDouble();
      dLng = (ride['dropoffCoords']['lng'] as num).toDouble();
    } else if (ride['dropoffLat'] != null) {
      dLat = (ride['dropoffLat'] as num).toDouble();
      dLng = (ride['dropoffLng'] as num).toDouble();
    }

    pickupLat.value = pLat;
    pickupLng.value = pLng;
    dropoffLat.value = dLat;
    dropoffLng.value = dLng;

    debugPrint("🔥[DEBUG_BUG] === DRIVER TRIP LOAD RIDE ===");
    debugPrint("🔥[DEBUG_BUG] ride status: ${status.value}");
    debugPrint("🔥[DEBUG_BUG] pickupCoords parsed: pLat=$pLat, pLng=$pLng");
    debugPrint("🔥[DEBUG_BUG] dropoffCoords parsed: dLat=$dLat, dLng=$dLng");
    debugPrint("🔥[DEBUG_BUG] ==================================");

    debugPrint("DriverTrip: [COORDINATES_LOADED] Setup for Ride: ${ride['_id']}");
    debugPrint("DriverTrip: -> Pickup:  $pLat, $pLng");
    debugPrint("DriverTrip: -> Dropoff: $dLat, $dLng");
    debugPrint("DriverTrip: -> Status:  ${status.value}");

    // Clear existing routes to prevent visually 'flickering' previous trip data
    routeToPickup.clear();
    routeToDropoff.clear();


    _startLocationUpdates();
    _fetchInitialRoute();
    _listenToRideStatus();
    _listenToRiderLocation(); // NEW: Listen for rider movement
  }

  void _listenToRiderLocation() {
    try {
      final socketService = Get.find<SocketService>();
      if (_riderLocationHandler != null && socketService.socket != null) {
        socketService.socket!.off('ride:location_update', _riderLocationHandler);
      }
      _riderLocationHandler = (data) {
        if (isClosed) return;
        if (data != null && data['rideId'].toString() == currentRideId.value) {
          if (data['type'] == 'customer') {
            // BUG FIX: Do NOT overwrite the static 'pickupLat' with the customer's live GPS.
            // If the customer physically moves (or is tested on an emulator that jumps to the destination),
            // it causes the Driver App to move the Orange Pickup Pin to the Destination,
            // making it look like the Driver is navigating to the Destination instead of the Pickup.
            
            // We can store live tracking in a separate variable if needed, but the pickup route 
            // and orange pin must remain strictly bound to the original requested pickup coordinates.
            final liveLat = (data['lat'] as num).toDouble();
            final liveLng = (data['lng'] as num).toDouble();
            debugPrint("Driver App: Rider physically moved to $liveLat, $liveLng (Ignoring for static pickup pin)");
          }
        }
      };
      socketService.socket?.on('ride:location_update', _riderLocationHandler!);
    } catch (e) {
      debugPrint("Error setting up rider location listener: $e");
    }
  }

  void _listenToRideStatus() {
    try {
      final socketService = Get.find<SocketService>();
      socketService.joinRide(currentRideId.value);
      
      if (_statusChangedHandler != null && socketService.socket != null) {
        socketService.socket!.off('ride:status_changed', _statusChangedHandler);
      }
      if (_paymentMethodChangedHandler != null && socketService.socket != null) {
        socketService.socket!.off('ride:payment_method_changed', _paymentMethodChangedHandler);
      }

      _statusChangedHandler = (data) {
        if (isClosed) return;
        if (data != null && data['_id'].toString() == currentRideId.value) {
          final oldStatusVal = status.value;
          final newStatus = data['status']?.toString();
          if (newStatus != null) {
            status.value = newStatus;
          }
          final pMethod = data['paymentMethod']?.toString();
          if (pMethod != null) {
            paymentMode.value = pMethod;
          }
          final pStatus = data['paymentStatus']?.toString();
          if (pStatus == 'Completed') {
            isPaymentCollected.value = true;
          }
          if (newStatus?.toLowerCase() == 'cancelled') {
            // If we are already on the Earning screen, just update the ride details
            // (e.g. to show the correct cancellation fee if it changed) and return.
            if (Get.currentRoute == DriverRoutes.tripEarning) {
              loadRide(data);
              return;
            }

            final wasArrived = oldStatusVal.toLowerCase() == 'arrived';
            final wasOngoing = oldStatusVal.toLowerCase() == 'tripstarted' || oldStatusVal.toLowerCase() == 'ongoing';
            final fareValue = (data['fare'] as num?)?.toDouble() ?? 0.0;

            if ((wasArrived || wasOngoing) && fareValue > 0) {
              loadRide(data);
              goEarning();
            } else {
              // Clear active trip so driver can receive new ride requests
              if (Get.isRegistered<SocketService>()) {
                Get.find<SocketService>().clearActiveTrip();
              }
              goHomeTab();
            }
          }
        }
      };

      _paymentMethodChangedHandler = (data) {
        if (isClosed) return;
        if (data != null && data['_id'].toString() == currentRideId.value) {
          final pMethod = data['paymentMethod']?.toString();
          if (pMethod != null) {
            paymentMode.value = pMethod;
          }
        }
      };

      socketService.socket?.on('ride:status_changed', _statusChangedHandler!);
      socketService.socket?.on('ride:payment_method_changed', _paymentMethodChangedHandler!);
    } catch (e) {
      debugPrint("Error setting up ride status listener: $e");
    }
  }

  Future<void> _fetchInitialRoute() async {
    try {
      bool isOngoing = status.value.toLowerCase() == 'tripstarted' || status.value.toLowerCase() == 'ongoing';
      
      Position? pos;
      try {
        pos = await Geolocator.getLastKnownPosition();
        pos ??= await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              timeLimit: Duration(seconds: 5),
            ),
          );
      } catch (e) {
        debugPrint("Error getting initial position: $e");
      }
      
      if (pos != null) {
        driverLat.value = pos.latitude;
        driverLng.value = pos.longitude;
        // Initial backend update immediately
        await ApiService.updateRideLocation(
          currentRideId.value,
          'driver',
          pos.latitude,
          pos.longitude,
        );
      }

      // [STAGE GUARD] Only fetch pickup route if in Accepted/Arrived stage
      if (isAccepted && pickupLat.value != 0 && pickupLat.value != 1) {
        // Hard clear for safety
        routeToDropoff.clear();

        final dist = Geolocator.distanceBetween(driverLat.value, driverLng.value, pickupLat.value, pickupLng.value);
        if (dist < 20) {
          debugPrint("🔥[DEBUG_BUG] distToRider is $dist (< 20). CLEARING routeToPickup.");
          routeToPickup.clear();
          estimatedTime.value = "0 min";
        } else {
          debugPrint("🔥[DEBUG_BUG] distToRider is $dist (> 20). FETCHING Route Driver->Pickup...");
          final details = await RoutingService.getRouteDetails(
            LatLng(driverLat.value, driverLng.value),
            LatLng(pickupLat.value, pickupLng.value),
          );
          final points = details['points'] as List<LatLng>? ?? [];
          debugPrint("🔥[DEBUG_BUG] RoutingService returned ${points.length} points for Driver->Pickup.");
          
          // CRITICAL CHECK: Look at the last point of the route (which should be the pickup location)
          if (points.isNotEmpty) {
             final lastPt = points.last;
             final distToDropoff = Geolocator.distanceBetween(lastPt.latitude, lastPt.longitude, dropoffLat.value, dropoffLng.value);
             debugPrint("🔥[DEBUG_BUG] CHECK: The fetched route ends at (${lastPt.latitude}, ${lastPt.longitude}).");
             debugPrint("🔥[DEBUG_BUG] CHECK: Distance from route end to DROPOFF is: $distToDropoff meters.");
             if (distToDropoff < 500) {
                 debugPrint("🔥[SEVERE_BUG] WARNING: The Driver->Pickup route actually ends near the DROPOFF location! API or Geocoding is swapping coordinates!");
             }
          }

          routeToPickup.assignAll(points);
          if (details['duration'] != null) {
            final int dur = int.tryParse(details['duration'].toString()) ?? 0;
            estimatedTime.value = _formatDuration(dur);
          }
        }
      } else {
        // Clear if not in correct stage
        routeToPickup.clear();
      }


      // Final safety: if not ongoing, routeToDropoff must be empty
      if (!isOngoing) {
        routeToDropoff.clear();
      }



      
    } catch (e) {
      debugPrint("Route fetch error: $e");
    }
  }

  Future<void> fetchRouteToDropoff({bool force = false}) async {
    try {
      final now = DateTime.now();
      if (!force && _lastRouteFetchTime != null && now.difference(_lastRouteFetchTime!) < const Duration(seconds: 5)) {
        return;
      }
      _lastRouteFetchTime = now;

      // [STAGE GUARD] Only fetch destination route if trip has officially started
      if (!isOngoing) {
        routeToDropoff.clear();
        return;
      }

      // Hard clear pickup route for safety
      routeToPickup.clear();

      if (dropoffLat.value == 0) {
        debugPrint("Driver: Missing coordinates for dropoff route fetch!");
        return;
      }

      final dist = Geolocator.distanceBetween(driverLat.value, driverLng.value, dropoffLat.value, dropoffLng.value);

      if (dist < 20) {
         routeToDropoff.clear();
         estimatedTime.value = "0 min";
      } else {
        debugPrint("DriverTrip: [FETCHING_DROPOFF_ROUTE] Driver -> ${dropoffLat.value}");
        final details = await RoutingService.getRouteDetails(
          LatLng(driverLat.value != 0 ? driverLat.value : pickupLat.value, 
                 driverLng.value != 0 ? driverLng.value : pickupLng.value),
          LatLng(dropoffLat.value, dropoffLng.value),
        );
        final r2 = details['points'] as List<LatLng>? ?? [];
        routeToDropoff.assignAll(r2);
        if (details['duration'] != null) {
          final int dur = int.tryParse(details['duration'].toString()) ?? 0;
          estimatedTime.value = _formatDuration(dur);
        }
      }
    } catch (e) {
      debugPrint("Route fetch error: $e");
    }
  }


  void _startLocationUpdates() async {
    _positionStream?.cancel();

    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best));
      if (displayDriverLat.value == 0) {
        displayDriverLat.value = p.latitude;
        displayDriverLng.value = p.longitude;
      }
      driverLat.value = p.latitude;
      driverLng.value = p.longitude;
      
      // Force initial push to backend so DB has the precise starting location
      if (currentRideId.value.isNotEmpty) {
        ApiService.updateRideLocation(
          currentRideId.value,
          'driver',
          p.latitude,
          p.longitude,
        ).catchError((_) => <String, dynamic>{});
      }
    } catch (e) {
      debugPrint("Error getting immediate position: $e");
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0, 
      ),
    ).listen((Position pos) async {
       if (currentRideId.value.isEmpty || isClosed) return;

       try {
          if (displayDriverLat.value == 0) {
            displayDriverLat.value = pos.latitude;
            displayDriverLng.value = pos.longitude;
          } else {
            double bearing = Geolocator.bearingBetween(
              displayDriverLat.value,
              displayDriverLng.value,
              pos.latitude,
              pos.longitude,
            );
            rotation.value = (bearing + 180) % 360;
            _animateTo(pos.latitude, pos.longitude);
          }
          
          driverLat.value = pos.latitude;
          driverLng.value = pos.longitude;

          bool isOngoing = status.value.toLowerCase() == 'tripstarted' || status.value.toLowerCase() == 'ongoing';

          // REAL-TIME PROXIMITY CLEARING (Outside the throttle timer for immediate UI response)
          if (!isOngoing) {
            if (pickupLat.value != 0) {
              double distToPickup = Geolocator.distanceBetween(pos.latitude, pos.longitude, pickupLat.value, pickupLng.value);
              if (distToPickup < 20) {
                routeToPickup.clear();
                estimatedTime.value = "0 min";
              }
              // No live distance string update (ETA minutes only)

            }
            routeToDropoff.clear(); // Safety: always clear destination route if not ongoing
          } else {
            if (dropoffLat.value != 0) {
              double distToDrop = Geolocator.distanceBetween(pos.latitude, pos.longitude, dropoffLat.value, dropoffLng.value);
              if (distToDrop < 20) {
                routeToDropoff.clear();
                estimatedTime.value = "0 min";
              }
            }
            routeToPickup.clear(); // Safety: always clear pickup route if ongoing
          }

          // Backend update throttle
          bool shoudUpdateBackend = true;
          if (_lastSentPos != null) {
            final d = Geolocator.distanceBetween(
              _lastSentPos!.latitude, _lastSentPos!.longitude,
              pos.latitude, pos.longitude
            );
            if (d < 3) shoudUpdateBackend = false;
          }

          if (shoudUpdateBackend) {
            _lastSentPos = pos;
            
            // 1. Instant Socket Update (Best for real-time admin tracking)
            if (Get.isRegistered<SocketService>()) {
              SocketService.to.updateLocation(
                currentRideId.value,
                pos.latitude,
                pos.longitude,
              );
            }

            // 2. Persistent REST Update
            await ApiService.updateRideLocation(
              currentRideId.value,
              'driver',
              pos.latitude,
              pos.longitude,
            );
          }
          
          // Route fetch throttle (Heavy API calls)
          final now = DateTime.now();
          if (_lastRouteFetchTime == null || now.difference(_lastRouteFetchTime!).inSeconds > 5) {
            _lastRouteFetchTime = now;
            
            if (!isOngoing) {
              // Only update route to pickup if in accepted/arrived stages
              if (['accepted', 'arrived'].contains(status.value.toLowerCase()) && pickupLat.value != 0) {
                double distToPickup = Geolocator.distanceBetween(pos.latitude, pos.longitude, pickupLat.value, pickupLng.value);
                if (distToPickup >= 20) {
                   _fetchInitialRoute();
                } else {
                   routeToPickup.clear();
                }
              } else {
                routeToPickup.clear();
              }
            } else {
              // Update route to dropoff if started
              if (dropoffLat.value != 0) {
                 double distToDrop = Geolocator.distanceBetween(pos.latitude, pos.longitude, dropoffLat.value, dropoffLng.value);
                 if (distToDrop >= 20) {
                    fetchRouteToDropoff();
                 } else {
                    routeToDropoff.clear();
                 }
              }
            }

          }
       } catch (e) {
         debugPrint("Error in trip location listener: $e");
       }
    });
  }

  // ─────────────── Navigation ───────────────

  void goAtLocation() => Get.toNamed(DriverRoutes.atLocation);
  void goQuickCheck() => Get.toNamed(DriverRoutes.quickCheck);
  void goReachDestination() => Get.toNamed(DriverRoutes.reachDestination);
  void goEarning() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    Get.offNamed(DriverRoutes.tripEarning);
    startPaymentStatusPolling();
  }

  void startPaymentStatusPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (currentRideId.value.isEmpty || isPaymentCollected.value) {
        timer.cancel();
        return;
      }
      try {
        final ride = await ApiService.getRide(currentRideId.value);
        if (ride['error'] == null) {
          final pMethod = ride['paymentMethod']?.toString();
          final pStatus = ride['paymentStatus']?.toString();
          
          if (pMethod != null) {
            paymentMode.value = pMethod;
          }
          if (pStatus == 'Completed') {
            isPaymentCollected.value = true;
            timer.cancel();
            showCustomerRatingDialog();
          } else if (pStatus == 'Disputed') {
            timer.cancel();
            goHomeTab();
          }
        }
      } catch (e) {
        debugPrint("Error polling payment status: $e");
      }
    });
  }

  void goHomeTab() {
    if (_isNavigatingHome) return;
    _isNavigatingHome = true;

    if (Get.isDialogOpen == true) {
      Get.back();
    }
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    final wasCancelled = status.value.toLowerCase() == 'cancelled';

    // Notify SocketService that driver is no longer in a trip
    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().clearActiveTrip();
    }

    // Instantly clear the active trip card on home screen
    if (Get.isRegistered<DriverHomeController>()) {
      Get.find<DriverHomeController>().activeTrip.value = null;
    }

    Get.offAllNamed(DriverRoutes.home);

    if (wasCancelled) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.dialog(
          AlertDialog(
            title: const Text("Ride Cancelled"),
            content: const Text("The rider has cancelled this ride request."),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("OK", style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );
      });
    }

    Future.delayed(const Duration(milliseconds: 250), () {
      if (Get.isRegistered<DriverHomeController>()) {
        final hc = Get.find<DriverHomeController>();
        hc.setIndex(0);
        hc.fetchStats();
      }
      Get.delete<DriverTripController>(force: true);
    });
  }

  void continueFinding() {
    // Clear active trip guard in SocketService so driver can receive new requests
    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().clearActiveTrip();
    }

    // Instantly clear the active trip card on home screen
    if (Get.isRegistered<DriverHomeController>()) {
      Get.find<DriverHomeController>().activeTrip.value = null;
    }

    // We navigate home first. The binding will ensure DriverHomeController exists.
    Get.offAllNamed(DriverRoutes.home);
    
    // Use a small delay or post-frame callback to ensure binding has finished
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.isRegistered<DriverHomeController>()) {
        final h = Get.find<DriverHomeController>();
        h.activeTrip.value = null;
        h.toggleOnline(true);
        h.setIndex(2);
      }
      Get.delete<DriverTripController>(force: true);
    });
  }

  // ─────────────── OTP (Start Trip) ───────────────

  void openOtpDialog() async {
    if (!isQuickCheckValid) {
      return;
    }

    if (Get.isDialogOpen == true) return;

    // Show loading on button immediately
    isStartingTrip.value = true;

    // Save check to backend first
    isUpdating.value = true;
    try {
      await ApiService.saveTripCheck(
        rideId: currentRideId.value,
        isClean: qcCleanCar.value,
        hasDamage: qcDentScratch.value,
        customerConfirmed: qcConfirmDamage.value,
        damageImagePaths: qcDamageImages.toList(),
      );
    } catch (e) {
      debugPrint("Error saving trip check: $e");
    } finally {
      isUpdating.value = false;
      // Keep isStartingTrip true — the dialog is about to open
    }

    otpC.clear();
    // Reset loading AFTER dialog frame is scheduled so there's no visual gap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isStartingTrip.value = false;
    });
    Get.dialog(
      EnterOtpDialog(
        onClose: () {
          otpFocusNode.unfocus();
          isStartingTrip.value = false;
          Get.back();
        },
        onVerify: () async {
          final otp = otpC.text.trim();
          if (otp.isEmpty || otp.length != 4) {
            return;
          }

          // Mark ride as Ongoing in backend with OTP
          isVerifyingOtp.value = true;
          try {
            // INSTANT UI UPDATE
            status.value = 'Ongoing';
            routeToPickup.clear(); // Important: Trip started, no longer need pickup route
            
            final response = await _updateRideStatus('Ongoing', otp: otp);

            if (response != null && response['error'] != null) {
              // Snackbar removed: Backend handles errors via FCM if needed
            } else {
              if (response != null) {
                loadRide(response);
              }
              Get.back(); // close dialog immediately
              routeToPickup.clear(); // Important: Trip started, no longer need pickup route
              goReachDestination();
              // Fetch route in background so UI doesn't hang
              unawaited(fetchRouteToDropoff(force: true));
            }
          } finally {
            isVerifyingOtp.value = false;
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  // ─────────────── Cancel Ride ───────────────

  Future<bool> openReasonDialog() async {
    if (Get.isDialogOpen == true) return false;

    final result = await Get.dialog<bool>(
      ReasonDialog(
        onClose: () => Get.back(result: false),
        onSubmit: () async {
          Get.back(result: true);
          await cancelRideByDriver();
        },
      ),
      barrierDismissible: true,
    );
    return result ?? false;
  }

  Future<void> callRider() async {
    if (customerPhone.value.isNotEmpty) {
      final url = Uri.parse("tel:${customerPhone.value}");
      try {
        await launchUrl(url); // Assumes url_launcher is available
      } catch (e) {
        Get.snackbar("Error", "Could not launch dialer");
      }
    } else {
      Get.snackbar("Error", "Phone number not available");
    }
  }

  void shareTrip() {
    // ignore: deprecated_member_use
    Share.share(
      "Track my Divanex trip! Rider: ${customerName.value}, Pickup: ${pickup.value}, Drop: ${drop.value}. Booking ID: ${bookingId.value}",
    );
  }

  Future<void> openGoogleMapsForPickup() async {
    if (pickupLat.value != 0 && pickupLng.value != 0) {
      final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=${pickupLat.value},${pickupLng.value}",
      );
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        Get.snackbar("Error", "Could not open map: $e");
      }
    } else {
      Get.snackbar("Error", "Pickup coordinates not available");
    }
  }

  Future<void> openGoogleMapsForDropoff() async {
    if (dropoffLat.value != 0 && dropoffLng.value != 0) {
      final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=${dropoffLat.value},${dropoffLng.value}",
      );
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        Get.snackbar("Error", "Could not open map: $e");
      }
    } else {
      Get.snackbar("Error", "Dropoff coordinates not available");
    }
  }

  Future<void> cancelRideByDriver() async {
    if (currentRideId.value.isNotEmpty) {
      isCancelling.value = true;
      try {
        await ApiService.addCancelledRideId(currentRideId.value);
        await _updateRideStatus('cancelled_by_driver');
        // Notify SocketService trip is over before navigating home
        if (Get.isRegistered<SocketService>()) {
          Get.find<SocketService>().clearActiveTrip();
        }
        goHomeTab();
      } catch (e) {
        Get.snackbar("Error", "Failed to cancel ride: $e");
      } finally {
        isCancelling.value = false;
      }
    }
  }

  // ─────────────── Complete Trip ───────────────

  Future<bool> completeRide() async {
    isCompletingRide.value = true;
    try {
      final response = await _updateRideStatus('Completed');
      if (response != null && response['error'] == null) {
        loadRide(response); // ✅ Populate completedAt and startedAt
        isPaymentCollected.value = false; // Reset for the new earning screen
        isCompletingRide.value = false; // RESET HERE
        goEarning();
        return true;
      } else {
        Get.snackbar("Error", response?['message'] ?? "Could not complete ride");
        isCompletingRide.value = false;
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Error completing ride: $e");
      isCompletingRide.value = false;
      debugPrint("Error completing ride: $e");
      return false;
    }
  }

  void confirmPayment() {
    isPaymentCollected.value = true;
    showCustomerRatingDialog();
  }

  Future<void> confirmCashCollected() async {
    if (currentRideId.value.isEmpty) return;
    isCompletingRide.value = true;
    try {
      final response = await ApiService.confirmCashPayment(currentRideId.value);
      if (response['error'] == null) {
        confirmPayment();
      } else {
        Get.snackbar("Error", response['error'] ?? "Failed to confirm cash payment");
      }
    } catch (e) {
      Get.snackbar("Error", "Error: $e");
    } finally {
      isCompletingRide.value = false;
    }
  }

  Future<void> raiseDispute({
    required String issueType,
    required String description,
  }) async {
    if (currentRideId.value.isEmpty) return;
    isCompletingRide.value = true;
    try {
      final response = await ApiService.raisePaymentDispute(
        currentRideId.value,
        issueType: issueType,
        description: description,
      );
      if (response['error'] == null) {
        Get.snackbar(
          "Dispute Raised",
          "Payment dispute has been registered successfully. Admin will review.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        // Clear active trip guard so driver can receive new requests
        if (Get.isRegistered<SocketService>()) {
          Get.find<SocketService>().clearActiveTrip();
        }
        goHomeTab();
      } else {
        Get.snackbar("Error", response['error'] ?? "Failed to raise dispute");
      }
    } catch (e) {
      Get.snackbar("Error", "Error: $e");
    } finally {
      isCompletingRide.value = false;
    }
  }

  void showCustomerRatingDialog() {
    if (isFeedbackShown.value) return;
    if (currentRideId.value.isEmpty || customerId.value.isEmpty) return;

    isFeedbackShown.value = true;
    Get.dialog(
      CustomerRatingDialog(
        rideId: currentRideId.value,
        customerId: customerId.value,
        customerName: customerName.value,
        customerImage: customerImage.value,
        onComplete: () {
          // No additional action needed
        },
      ),
      barrierDismissible: false,
    );
  }

  // ─────────────── Accept Ride ───────────────

  Future<void> acceptRide(String rideId) async {
    currentRideId.value = rideId;
    status.value = 'Accepted'; // INSTANT UI UPDATE
    isUpdating.value = true;
    try {
      final response = await ApiService.updateRideStatus(rideId, 'Accepted');
      if (response['error'] != null) {
        // Show error and return to home
        Get.snackbar(
          "Ride Not Available",
          response['message'] ?? response['error'] ?? "This ride has already been accepted by another driver.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        goHomeTab();
        return;
      }
    } catch (e) {
      // If network fails, we still have the local state, but it's better to log it
      debugPrint("Error accepting ride: $e");
    } finally {
      isUpdating.value = false;
    }
  }

  // ─────────────── Arrive At Location ───────────────

  Future<bool> arriveAtLocation() async {
    isUpdating.value = true;
    try {
      final response = await _updateRideStatus('Arrived');
      if (response != null && response['error'] == null) {
        loadRide(response);
        status.value = 'Arrived';
        return true;
      } else {
        Get.snackbar("Error", response?['message'] ?? "Could not update arrival status");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Error updating arrival: $e");
      debugPrint("Error updating arrival: $e");
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // ─────────────── Internal helper ───────────────

  Future<Map<String, dynamic>?> _updateRideStatus(
    String status, {
    String? otp,
  }) async {
    if (currentRideId.value.isEmpty) return null;
    isUpdating.value = true;
    try {
      final response = await ApiService.updateRideStatus(
        currentRideId.value,
        status,
        otp: otp,
      );
      return response;
    } catch (e) {
      // Fail silently - don't crash the user experience
      debugPrint('Failed to update ride status: $e');
      return {'error': e.toString()};
    } finally {
      isUpdating.value = false;
    }
  }
  void _animateTo(double targetLat, double targetLng) {
    _lerpTimer?.cancel();
    final startLat = displayDriverLat.value;
    final startLng = displayDriverLng.value;
    int steps = 20;
    int currentStep = 0;
    _lerpTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
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
  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      int hrs = minutes ~/ 60;
      int mins = minutes % 60;
      return "$hrs:${mins.toString().padLeft(2, '0')} hr:min";
    }
    return "$minutes min";
  }
}

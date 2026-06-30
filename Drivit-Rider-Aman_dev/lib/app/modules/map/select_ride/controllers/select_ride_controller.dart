import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/middleware/auth_middleware.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../controllers/map_controller.dart';
import '../../../../core/services/routing_service.dart';
import '../../../../core/services/recent_destinations_service.dart';
import '../widgeets/schedule_ride_dialog.dart';
import '../../../finding_drivers/controllers/finding_driver_controller.dart';
import '../../widgets/not_serviceable_bottom_sheet.dart';
import '../../../../core/utils/geofence_util.dart';

class SelectRideController extends GetxController {
  final tripOpen = false.obs;
  final carOpen = false.obs;
  final packageOpen = false.obs;
  final isAirportFlow = false.obs;

  final pickup = "".obs;
  final destination = "".obs;

  final destinationTextController = TextEditingController();
  final destinationFocusNode = FocusNode();
  final pickupFocusNode = FocusNode();
  final sheetController = DraggableScrollableController();
  final isSearchingDestination = false.obs;
  final destinationSuggestions = <PlaceSuggestion>[].obs;
  final dropoffLat = 0.0.obs;
  final dropoffLng = 0.0.obs;
  final pickupLat = 0.0.obs;
  final pickupLng = 0.0.obs;
  Timer? _destSearchDebounce;

  final carCategoriesRaw = <dynamic>[].obs;
  final carCategories = <String>[].obs;
  final carModelsList = <String>[].obs;
  final selectedCar = "Manual".obs;
  final selectedCarModel = "".obs;
  final profileCarModel = "".obs;
  final selectedCarNumber = "".obs;
  final profileCarNumber = "".obs;
  final selectedCarInfo = "".obs;
  final transmission = "Both".obs;
  final hasProfileTransmission = false.obs;
  final tripType = "One Way".obs; // Default to One Way
  final isOutstationFlow = false.obs;
  final selectedPackage = "".obs; // Start empty to avoid default price
  final selectedHourPrice = 0.0.obs;
  final selectedDayPrice = 0.0.obs;
  final totalPrice = 0.0.obs;
  final numberOfDays = 1.obs;
  final travelPlanController = TextEditingController();
  final travelPlanFocusNode = FocusNode();
  final tripTypesList = <dynamic>[].obs;
  final isLoadingTripTypes = false.obs;
  final _paymentService = PaymentService();

  final scheduleDate = Rxn<DateTime>();
  final scheduleTime = Rxn<TimeOfDay>();

  final basePricePerKm = 10.0.obs;
  final outstationReturnChargeRate = 10.0.obs;
  
  // New Trip Configuration Rx Settings
  final localEnableReturnCharge = false.obs;
  final localReturnChargeRate = 10.0.obs;
  final localShowEstimatedHours = true.obs;
  
  final outstationRoundUseEstimatedHours = false.obs;
  final outstationRoundEnableReturnCharge = false.obs;
  final outstationRoundReturnChargeRate = 10.0.obs;
  
  final outstationOneWayShowEstimatedHours = true.obs;
  final outstationOneWayEnableReturnCharge = true.obs;

  bool get shouldShowEstimatedHours {
    if (!isOutstationFlow.value) {
      return localShowEstimatedHours.value;
    } else {
      if (tripType.value == "One Way") {
        return outstationOneWayShowEstimatedHours.value;
      } else {
        return outstationRoundUseEstimatedHours.value;
      }
    }
  }

  final returnCharge = 0.0.obs;
  final carWashPriceSetting = 150.0.obs;
  final platformCharge = 20.0.obs;
  final gstPercentage = 5.0.obs;
  final subtotal = 0.0.obs;
  final gstAmount = 0.0.obs;
  final requireCarWash = false.obs;
  final sheetExtent = 0.6.obs;

  final isPickupFocused = false.obs;
  final isRideBooked = false.obs; // Tracks if we just finished a ride
  final activePackage = Rxn<Map<String, dynamic>>();

  // New flags for UI logic: manual typing vs map-based updates
  final isManualTypingPickup = false.obs;
  final isManualTypingDestination = false.obs;
  
  // Controls when to show the "Confirm Location" card (only after map interaction)
  final showLocationCardPickup = false.obs;
  final showLocationCardDestination = false.obs;

  // Scheduled Wait Logic
  Timer? _scheduleWaitTimer;
  final scheduleWaitTime = 120.obs;

  final hasTappedPickupField = false.obs;
  final estimatedTime = 0.0.obs;

  final polylines = <Polyline>{}.obs;
  final markers = <Marker>{}.obs;
  
  final isFetchingRoute = false.obs;
  final recentDestinations = <RecentDestination>[].obs;

  bool get isBothLocationsSelected => 
    pickup.value.isNotEmpty && 
    pickup.value != "Pickup Location" &&
    destination.value.isNotEmpty &&
    destination.value != "Destination" &&
    pickupLat.value != 0.0 && 
    dropoffLat.value != 0.0;

  int _fetchRouteRequestId = 0;

  Future<void> _fetchRouteWithDebounce() async {}

  Future<void> fetchRoute() async {
    if (isBothLocationsSelected) {
      final start = LatLng(pickupLat.value, pickupLng.value);
      final end = LatLng(dropoffLat.value, dropoffLng.value);
      
      markers.assignAll({
        Marker(markerId: const MarkerId('pickup'), position: start, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
        Marker(markerId: const MarkerId('dropoff'), position: end, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
      });

      try {
        isFetchingRoute.value = true;
        _fetchRouteRequestId++;
        final currentRequestId = _fetchRouteRequestId;
        
        final route = await RoutingService.getRoute(start, end);
        
        if (currentRequestId != _fetchRouteRequestId) {
          // A newer request has been made, discard this result to prevent old routes overwriting new ones
          return;
        }

        if (route != null) {
          routedDistance.value = route.distance;
          routedDuration.value = route.duration;
          polylines.assignAll({
            Polyline(
              polylineId: const PolylineId('route'),
              points: route.points,
              color: Colors.orange,
              width: 4,
            )
          });
        }
      } finally {
        isFetchingRoute.value = false;
        calculateTotalPrice();
      }
    } else {
      routedDistance.value = 0.0;
      routedDuration.value = 0.0;
      polylines.clear();
      markers.clear();
      calculateTotalPrice();
    }
  }

  @override
  void onInit() {
    super.onInit();
    
    // Explicitly reset coordinates and locations to ensure fresh state 
    // even if the controller instance is reused between bookings.
    pickup.value = "";
    destination.value = "";
    pickupLat.value = 0.0;
    pickupLng.value = 0.0;
    dropoffLat.value = 0.0;
    dropoffLng.value = 0.0;
    totalPrice.value = 0.0;
    destinationTextController.clear();
    isAirportFlow.value = false;

    final args = Get.arguments;
    if (args is Map) {
      if (args["fromSuccess"] == true) {
        isRideBooked.value = true;
      }
      if (args["tripType"] == "Outstation") {
        isOutstationFlow.value = true;
        tripType.value = "One Way";
      } else if (args["tripType"] != null && args["tripType"] != "airport") {
        tripType.value = args["tripType"];
      }
    }
    
    if (Get.isRegistered<MapController>()) {
      final mapC = Get.find<MapController>();
      mapC.resetState(); // Clear stale location/address from previous bookings
      mapC.searchTextController.clear();
      mapC.suggestions.clear();
      
      if (args is Map && args["tripType"] == "airport") {
        _handleAirportFlow(mapC);
      }
    }
    
    isManualTypingPickup.value = false;
    isManualTypingDestination.value = false;
    showLocationCardPickup.value = false;
    showLocationCardDestination.value = false;
    destinationSuggestions.clear();
    
    travelPlanFocusNode.addListener(() {
      if (travelPlanFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (sheetController.isAttached) {
            sheetController.animateTo(
              0.72,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    fetchCarCategories().then((_) => _prefillTransmissionFromProfile());
    fetchTripTypes();
    fetchPricingSettings();
    checkActivePackage();
    _loadRecentDestinations();
    
    // ✅ Add focus listeners to ensure we only update the relevant location field
    pickupFocusNode.addListener(() {
      if (pickupFocusNode.hasFocus) {
        isPickupFocused.value = true;
        isDestinationFocused.value = false;
        // When focusing pickup, clear map suggestions and reset flags
        if (Get.isRegistered<MapController>()) {
          Get.find<MapController>().suggestions.clear();
        }
        isManualTypingPickup.value = false;
        showLocationCardPickup.value = false;
      } else {
        isPickupFocused.value = false;
      }
    });

    destinationFocusNode.addListener(() {
      if (destinationFocusNode.hasFocus) {
        isDestinationFocused.value = true;
        isPickupFocused.value = false;
        // When focusing destination, clear map suggestions and reset flags
        destinationSuggestions.clear();
        isManualTypingDestination.value = false;
        showLocationCardDestination.value = false;
      } else {
        isDestinationFocused.value = false;
      }
    });

    // Auto-update models when category changes (transmission stays "Both" to match all drivers)
    ever(selectedCar, (String val) {
      updateModelsForSelectedCategory();
      if (!hasProfileTransmission.value) {
        transmission.value = val;
      }
    });
    
    // Auto-update price when essential parameters change
    ever(selectedCarModel, (_) => updatePriceAndDetailsFromModel());
    ever(numberOfDays, (int days) {
      selectedPackage.value = "$days Day${days > 1 ? 's' : ''}";
    });
    ever(selectedPackage, (_) => calculateTotalPrice());
    ever(tripType, (String val) {
      if (val == "Round Trip") {
        int initialDays = (requiredHours.value / 24.0).ceil();
        numberOfDays.value = initialDays > 1 ? initialDays : 1;
        selectedPackage.value = "${numberOfDays.value} Day${numberOfDays.value > 1 ? 's' : ''}";
      }
      fetchRoute();
      calculateTotalPrice();
    });
    ever(requireCarWash, (_) => calculateTotalPrice());
    
    // Recalculate billing when coordinates OR address text changes.
    // Address text changes are the definitive signal that a location is "Selected" in the UI.
    ever(pickupLat, (double lat) {
      routedDistance.value = 0.0;
      calculateTotalPrice();
    });
    ever(pickupLng, (double lng) {
      // No overrides for Round Trip coordinates
    });
    ever(dropoffLat, (_) {
      routedDistance.value = 0.0;
      calculateTotalPrice();
    });
    ever(pickup, (String val) {
      // Only reset if we don't have coordinates yet (e.g. typing)
      if (pickupLat.value == 0) routedDistance.value = 0.0;
      calculateTotalPrice();
    });
    ever(destination, (_) {
      // Only reset if we don't have coordinates yet (e.g. typing)
      if (dropoffLat.value == 0) routedDistance.value = 0.0;
      calculateTotalPrice();
    });
    
    if (Get.isRegistered<MapController>()) {
      final mapC = Get.find<MapController>();
      
      // Auto-set initial coordinates if they are 0 and map has a position
      if (pickupLat.value == 0 && mapC.pickedLocation.value != null) {
        pickupLat.value = mapC.pickedLocation.value!.latitude;
        pickupLng.value = mapC.pickedLocation.value!.longitude;
      }
      
      ever(mapC.pickedLocation, (_) => calculateTotalPrice());
      
      // Update coordinates whenever the map is moved and field is focused
      ever(mapC.pickedLocation, (LatLng? pos) {
        if (pos == null) return;
        
        // If map moves, we assume user is choosing from map, so stop showing typing suggestions
        // BUT only if they are not actively typing a search query
        if (isPickupFocused.value && !isManualTypingPickup.value) {
          showLocationCardPickup.value = true; // Show card because user moved map
          pickupLat.value = pos.latitude;
          pickupLng.value = pos.longitude;
        } else if (isDestinationFocused.value && !isManualTypingDestination.value) {
          showLocationCardDestination.value = true; // Show card because user moved map
          dropoffLat.value = pos.latitude;
          dropoffLng.value = pos.longitude;
        }

        // If nothing is focused but pickup is still 0, sync to map center (initial load case)
        if (!isPickupFocused.value && !isDestinationFocused.value && pickupLat.value == 0) {
           pickupLat.value = pos.latitude;
           pickupLng.value = pos.longitude;
        }
      });
      
      // Sync map selection to the focused field (Pickup or Destination)
      ever(mapC.currentAddressSubtitle, (String addr) {
        // Skip if address looks like raw coordinates
        if (isPickupFocused.value && !isManualTypingPickup.value && !mapC.isSearching.value) {
          showLocationCardPickup.value = true;
        } else if (isDestinationFocused.value && !isManualTypingDestination.value && !isSearchingDestination.value) {
          showLocationCardDestination.value = true;
        }
      });

      // Automatically slide up the bottom sheet when both locations are confirmed 
      everAll([pickup, destination, pickupLat, pickupLng, dropoffLat, dropoffLng], (_) {
        if (isBothLocationsSelected) {
          fetchRoute(); // Calculate and display route on map once both locations are filled/confirmed
          calculateTotalPrice(); // Ensure price is updated instantly using Haversine
          
          // Only auto-expand if the user is NOT actively typing/focusing a field
          if (sheetController.isAttached && 
              !isAirportFlow.value && 
              !isPickupFocused.value && 
              !isDestinationFocused.value) {
            sheetController.animateTo(
              0.72,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          }
        } else {
          polylines.clear();
          markers.clear();
          routedDistance.value = 0.0;
          totalPrice.value = 0.0;
        }
      });
    }
  }

  final isDestinationFocused = false.obs;

  Future<void> _handleAirportFlow(MapController mapC) async {
    isAirportFlow.value = true;
    // 1. Wait for user position
    if (mapC.userPosition.value == null) {
      await mapC.getCurrentLocation();
    }
    
    final pos = mapC.userPosition.value ?? mapC.pickedLocation.value;
    if (pos == null) return;

    // 2. Set pickup to current location
    await mapC.refreshAddressForLocation(pos);
    pickup.value = mapC.currentAddressSubtitle.value;
    pickupLat.value = pos.latitude;
    pickupLng.value = pos.longitude;
    mapC.searchTextController.text = pickup.value;

    // 3. Find nearest airport
    final airport = await mapC.findNearestAirport(pos);
    if (airport != null) {
      destination.value = airport.displayName;
      destinationTextController.text = airport.displayName;
      dropoffLat.value = airport.latLng.latitude;
      dropoffLng.value = airport.latLng.longitude;
      
      // Auto select defaults for Airport
      tripType.value = "One Way";
      
      // Select first available car and model if none selected
      if (carCategories.isNotEmpty && selectedCar.value.isEmpty) {
        selectedCar.value = carCategories.first;
        updateModelsForSelectedCategory();
      }
      
      // Instantly calculate price via Haversine
      calculateTotalPrice();
      
      // Fetch accurate route and refine price in background 
      fetchRoute(); 
      
      // For Airport flow, keep the sheet at a moderate height (0.4) 
      // instead of 0.72 so user can see the routing clearly. 
      if (sheetController.isAttached) {
        sheetController.animateTo(
          0.4,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  Timer? _refreshTimer;

  Future<void> fetchCarCategories() async {
    final categories = await ApiService.getCarCategories();
    if (categories.isNotEmpty) {
      carCategoriesRaw.value = categories;
      final List<String> newCategories = categories
          .map((e) => e['name'].toString().trim())
          .toList();
      
      // Only update if changed to prevent unnecessary reactive triggers
      if (carCategories.length != newCategories.length || 
          !carCategories.every((cat) => newCategories.contains(cat))) {
        carCategories.assignAll(newCategories);
      }

      if (selectedCar.value.isEmpty || !carCategories.contains(selectedCar.value)) {
        selectedCar.value = carCategories.isNotEmpty ? carCategories.first : "";
      }
      
      // Initial populate if models list is empty
      if (carModelsList.isEmpty) {
        updateModelsForSelectedCategory();
      }
    } else {
      // Fallback
      if (carCategories.isEmpty) {
        carCategories.assignAll(["Manual", "Automatic"]);
        selectedCar.value = "Manual";
        transmission.value = "Both";
        carModelsList.assignAll(["Swift (Manual)", "Hatchback (Manual)", "Sedan (Manual)"]);
        selectedCarModel.value = "Swift (Manual)";
      }
    }
  }

  Future<void> _prefillTransmissionFromProfile() async {
    var profile = ApiService.cachedProfile;
    if (profile == null || profile['transmission'] == null || profile['transmission'].toString().isEmpty) {
      final customerId = await ApiService.getCustomerId();
      if (customerId != null) {
        final res = await ApiService.getCustomerProfile(customerId);
        if (!res.containsKey('error')) {
          profile = res;
          await ApiService.saveCustomerProfile(res);
        }
      }
    }

    if (profile == null) {
      hasProfileTransmission.value = false;
      // Fallback: sync transmission to selected category if not available in profile
      transmission.value = selectedCar.value;
      return;
    }

    final profileTransmission = profile['transmission']?.toString();
    if (profileTransmission != null &&
        profileTransmission.isNotEmpty &&
        carCategories.contains(profileTransmission)) {
      selectedCar.value = profileTransmission;
    }
    // Use profile's transmission — don't ask again during booking
    final profileTrans = profile['transmission']?.toString();
    if (profileTrans != null && profileTrans.isNotEmpty) {
      transmission.value = profileTrans;
      hasProfileTransmission.value = true;
    } else {
      hasProfileTransmission.value = false;
      transmission.value = selectedCar.value;
    }

    final profileCarModelVal = profile['carModel']?.toString();
    if (profileCarModelVal != null && profileCarModelVal.isNotEmpty) {
      selectedCarModel.value = profileCarModelVal;
      profileCarModel.value = profileCarModelVal;
    }
    final profileCarNumberVal = profile['carNumber']?.toString();
    if (profileCarNumberVal != null && profileCarNumberVal.isNotEmpty) {
      selectedCarNumber.value = profileCarNumberVal;
      profileCarNumber.value = profileCarNumberVal;
    }
  }

  Future<void> _loadRecentDestinations() async {
    // Load locally saved recent destinations
    final local = await RecentDestinationsService.getRecent();

    // Also load from past trips
    final customerId = await ApiService.getCustomerId();
    List<RecentDestination> fromTrips = [];
    if (customerId != null) {
      final rides = await ApiService.getCustomerRides(customerId);
      final seen = <String>{};
      for (final r in rides) {
        final status = (r['status'] ?? '').toString().toLowerCase();
        if (status != 'completed') continue;
        final name = r['dropoffLocation']?.toString();
        final coords = r['dropoffCoords'];
        if (name != null && name.isNotEmpty && coords != null) {
          final lat = (coords['lat'] as num?)?.toDouble();
          final lng = (coords['lng'] as num?)?.toDouble();
          if (lat != null && lng != null && lat != 0 && lng != 0 && !seen.contains(name)) {
            seen.add(name);
            fromTrips.add(RecentDestination(name: name, lat: lat!, lng: lng!));
          }
        }
      }
    }

    // Merge: local first, then trip destinations (deduplicated), keep max 3
    final merged = <RecentDestination>[...local];
    for (final t in fromTrips) {
      if (!merged.any((m) => m.name == t.name)) {
        merged.add(t);
      }
    }
    recentDestinations.assignAll(merged.take(3));
  }

  Future<void> saveRecentDestination(String name, double lat, double lng) async {
    await RecentDestinationsService.add(RecentDestination(name: name, lat: lat, lng: lng));
    recentDestinations.assignAll(await RecentDestinationsService.getRecent());
  }

  void selectRecentDestination(RecentDestination d) {
    destinationTextController.text = d.name;
    destination.value = d.name;
    dropoffLat.value = d.lat;
    dropoffLng.value = d.lng;
    isDestinationFocused.value = false;
    isManualTypingDestination.value = false;
    showLocationCardDestination.value = false;
    Get.focusScope?.unfocus();
    calculateTotalPrice();
    fetchRoute();
  }

  void updateModelsForSelectedCategory() {
    final category = carCategoriesRaw.firstWhereOrNull(
      (c) => c['name'].toString().trim().toLowerCase() == selectedCar.value.trim().toLowerCase(),
    );
    if (category != null) {
      if (category['cars'] != null && (category['cars'] as List).isNotEmpty) {
        final List carsList = category['cars'] as List;
        final List<String> models = carsList
            .map((e) => e['modelName'].toString().trim())
            .where((m) => m.isNotEmpty)
            .toSet()
            .toList();
        
        // Only assign if relevant content changed to avoid unnecessary Obx rebuilds
        if (carModelsList.length != models.length || 
            !carModelsList.every((m) => models.contains(m))) {
          carModelsList.assignAll(models);
        }
        
        // Only reset selection if current model is not part of this category's valid models
        if (selectedCarModel.value.isEmpty || !carModelsList.contains(selectedCarModel.value)) {
          if (carModelsList.isNotEmpty) {
            selectedCarModel.value = carModelsList.first;
          } else {
            selectedCarModel.value = "";
          }
        }
      } else {
        if (carModelsList.length != 1 || carModelsList.first != "Any Model") {
          carModelsList.assignAll(["Any Model"]);
          selectedCarModel.value = "Any Model";
        }
      }
    }
  }

  void updatePriceAndDetailsFromModel() {
    if (profileCarModel.value.isNotEmpty && 
        selectedCarModel.value.trim().toLowerCase() == profileCarModel.value.trim().toLowerCase()) {
      selectedCarNumber.value = profileCarNumber.value;
    } else {
      final category = carCategoriesRaw.firstWhereOrNull(
        (c) => c['name'].toString().trim().toLowerCase() == selectedCar.value.trim().toLowerCase(),
      );
      if (category != null && category['cars'] != null) {
        final List cars = category['cars'] as List;
        final selectedCarObj = cars.firstWhereOrNull(
          (c) => c['modelName'].toString().trim() == selectedCarModel.value.trim(),
        );
        
        if (selectedCarObj != null) {
          selectedCarNumber.value = selectedCarObj['carNumber'] ?? "";
        } else {
          selectedCarNumber.value = "";
        }
      } else {
        selectedCarNumber.value = "";
      }
    }
    calculateTotalPrice();
  }

  final usageCost = 0.0.obs;
  final distanceCost = 0.0.obs;
  final hourlyCost = 0.0.obs;
  final calculatedDistance = 0.0.obs;
  final routedDistance = 0.0.obs; // Distance from Google Directions in meters
  final routedDuration = 0.0.obs; // Duration from Google Directions in seconds
  final requiredHours = 0.0.obs;
  final carWashCharge = 0.0.obs;
  final rideRequestRadius = 50.0.obs; // Defaults to 50km
  final outstationMaxRange = 1000.0.obs; // Defaults to 1000km
  final isCalculatingPrices = false.obs;
  bool _hasShownTimeExceededSnack = false;

  int get maxAllowedHours {
    if (tripType.value == "Round Trip" && !outstationRoundUseEstimatedHours.value) {
      return numberOfDays.value * 24;
    }
    int max = 12;
    final selectedType = tripTypesList.firstWhereOrNull(
      (t) => t['name'].toString().trim().toLowerCase() == tripType.value.trim().toLowerCase(),
    );
    if (selectedType != null && selectedType['hourOptions'] != null) {
      List options = selectedType['hourOptions'] as List;
      if (options.isNotEmpty) {
        max = options.cast<num>().reduce((curr, next) => curr > next ? curr : next).toInt();
      }
    }
    return max;
  }

  void calculateTotalPrice() {
    try {
      isCalculatingPrices.value = true;
      final typeName = tripType.value.trim().toLowerCase();
      if (typeName == "one way" || typeName == "round trip") {
        isOutstationFlow.value = true;
      } else {
        isOutstationFlow.value = false;
      }
    double pLat = pickupLat.value;
    double pLng = pickupLng.value;
    
    // Explicitly removed map-center-sync logic from here as it caused "drifting"
    // Coordinates are now only synced via focus-aware listeners in onInit.

    final selectedType = tripTypesList.firstWhereOrNull(
      (t) => t['name'].toString().trim().toLowerCase() == tripType.value.trim().toLowerCase(),
    );

    double dist = 0.0;
    if (pLat != 0 && dropoffLat.value != 0) {
      if (routedDistance.value > 0) {
        dist = routedDistance.value / 1000.0; // convert meters to km
      } else {
        dist = _calculateDistance(pLat, pLng, dropoffLat.value, dropoffLng.value);
      }
    }
    calculatedDistance.value = dist;
    // Estimate travel time
    if (routedDuration.value > 0) {
      estimatedTime.value = (routedDuration.value / 60.0).roundToDouble(); // convert seconds to minutes
    } else {
      estimatedTime.value = (dist * 4).roundToDouble(); // fallback roughly 4 mins per km
    }

    double reqHrs;
    if (routedDuration.value > 0) {
      reqHrs = (routedDuration.value / 3600.0).ceilToDouble();
    } else {
      double speed = isOutstationFlow.value ? 50.0 : 30.0;
      reqHrs = (dist / speed).ceilToDouble();
    }
    requiredHours.value = reqHrs;

    if (dist > 0 && reqHrs > maxAllowedHours && !_hasShownTimeExceededSnack) {
      if (!isPickupFocused.value && !isDestinationFocused.value) {
        _hasShownTimeExceededSnack = true;
        if (Get.isDialogOpen == true) Get.back();
      }
    } else if (dist == 0 || reqHrs <= maxAllowedHours) {
      _hasShownTimeExceededSnack = false; // Reset when back in range
    }

    if (selectedType != null) {
      selectedHourPrice.value = (selectedType['pricePerHour'] ?? 0.0).toDouble();
      selectedDayPrice.value = (selectedType['pricePerDay'] ?? 0.0).toDouble();
      
      double multiplier = 1.0;
      if (selectedCarModel.value.toLowerCase().contains("sedan")) multiplier = 1.2;
      else if (selectedCarModel.value.toLowerCase().contains("suv")) multiplier = 1.5;
      else if (selectedCarModel.value.toLowerCase().contains("premium")) multiplier = 2.0;

      // Always calculate distance cost if we have a valid distance
      distanceCost.value = (dist * basePricePerKm.value * multiplier).roundToDouble();

      double hours = 0.0;
      if (isAirportFlow.value) {
        selectedPackage.value = "";
        hours = 0.0;
      } else if (tripType.value == "Round Trip" && !outstationRoundUseEstimatedHours.value) {
        hours = numberOfDays.value * 24.0;
        selectedPackage.value = "${numberOfDays.value} Day${numberOfDays.value > 1 ? 's' : ''}";
      } else if (!shouldShowEstimatedHours) {
        selectedPackage.value = "";
        hours = 0.0;
      } else {
        if (selectedPackage.value.isNotEmpty) {
          if (selectedPackage.value.toLowerCase().contains("day")) {
            hours = (double.tryParse(selectedPackage.value.split(" ")[0]) ?? 0.0) * 24.0;
          } else {
            hours = double.tryParse(selectedPackage.value.split(" ")[0]) ?? 0.0;
          }
        }
        
        // Auto-update hours if current selection is insufficient for distance
        // but only if a package is already selected or we want to suggest a minimum
        if (hours < reqHrs && reqHrs > 0 && reqHrs <= maxAllowedHours) {
          List options = selectedType['hourOptions'] ?? [1, 2, 4, 8, 12];
          final validOption = options.firstWhere((h) => (h is num && h >= reqHrs), orElse: () => null);
          if (validOption != null) {
            hours = validOption.toDouble();
            String newPkg;
            if (validOption == 24 && tripType.value == "Round Trip") {
              newPkg = "1 Day";
            } else {
              newPkg = "${validOption.toInt()} Hr${validOption > 1 ? 's' : ''}";
            }
            // Only update if changed to avoid unnecessary cycles
            if (selectedPackage.value != newPkg) {
              selectedPackage.value = newPkg;
            }
          }
        }
      }

      if (tripType.value == "Round Trip") {
        if (outstationRoundUseEstimatedHours.value) {
          hourlyCost.value = hours * selectedHourPrice.value;
        } else {
          hourlyCost.value = (hours / 24) * selectedDayPrice.value;
        }
      } else {
        hourlyCost.value = hours * selectedHourPrice.value;
      }
      
      double returnChg = 0.0;
      if (isOutstationFlow.value) {
        if (tripType.value == "One Way") {
          if (outstationOneWayEnableReturnCharge.value) {
            returnChg = (dist * outstationReturnChargeRate.value * multiplier).roundToDouble();
          }
        } else if (tripType.value == "Round Trip") {
          if (outstationRoundEnableReturnCharge.value) {
            returnChg = (dist * outstationRoundReturnChargeRate.value * multiplier).roundToDouble();
          }
        }
      } else {
        if (localEnableReturnCharge.value) {
          returnChg = (dist * localReturnChargeRate.value * multiplier).roundToDouble();
        }
      }
      returnCharge.value = returnChg;
      
      if (isAirportFlow.value) {
        usageCost.value = distanceCost.value;
        carWashCharge.value = 0.0;
        hourlyCost.value = 0.0;
      } else {
        if (tripType.value == "Round Trip") {
          usageCost.value = hourlyCost.value + returnCharge.value;
        } else {
          usageCost.value = distanceCost.value + hourlyCost.value + returnCharge.value;
        }
        if (requireCarWash.value) {
          carWashCharge.value = carWashPriceSetting.value;
        } else {
          carWashCharge.value = 0.0;
        }
      }
      
      totalPrice.value = (usageCost.value + carWashCharge.value).roundToDouble();
      
      subtotal.value = totalPrice.value;
      gstAmount.value = ((subtotal.value + platformCharge.value) * (gstPercentage.value / 100.0)).roundToDouble();
      totalPrice.value = (subtotal.value + platformCharge.value + gstAmount.value).roundToDouble();
    } else {
      double multiplier = 1.0;
      if (selectedCarModel.value.toLowerCase().contains("sedan")) multiplier = 1.2;
      else if (selectedCarModel.value.toLowerCase().contains("suv")) multiplier = 1.5;
      else if (selectedCarModel.value.toLowerCase().contains("premium")) multiplier = 2.0;

      distanceCost.value = (dist * basePricePerKm.value * multiplier).roundToDouble();
      hourlyCost.value = 0.0;
      
      double returnChg = 0.0;
      if (isOutstationFlow.value) {
        if (tripType.value == "One Way") {
          if (outstationOneWayEnableReturnCharge.value) {
            returnChg = (dist * outstationReturnChargeRate.value * multiplier).roundToDouble();
          }
        } else if (tripType.value == "Round Trip") {
          if (outstationRoundEnableReturnCharge.value) {
            returnChg = (dist * outstationRoundReturnChargeRate.value * multiplier).roundToDouble();
          }
        }
      } else {
        if (localEnableReturnCharge.value) {
          returnChg = (dist * localReturnChargeRate.value * multiplier).roundToDouble();
        }
      }
      returnCharge.value = returnChg;
      
      usageCost.value = distanceCost.value + returnCharge.value;
      carWashCharge.value = 0.0;
      totalPrice.value = usageCost.value.roundToDouble();
      
      subtotal.value = totalPrice.value;
      gstAmount.value = ((subtotal.value + platformCharge.value) * (gstPercentage.value / 100.0)).roundToDouble();
      totalPrice.value = (subtotal.value + platformCharge.value + gstAmount.value).roundToDouble();
    }
    } finally {
      isCalculatingPrices.value = false;
    }
  }

  Future<void> checkActivePackage() async {
    try {
      final res = await ApiService.getActivePackage();
      if (res.containsKey('active') && res['active'] == true) {
        activePackage.value = res['package'];
      } else {
        activePackage.value = null;
      }
    } catch (e) {
      debugPrint("Error checking active package: $e");
    }
  }

  Future<void> fetchTripTypes() async {
    try {
      isLoadingTripTypes.value = true;
      final List<dynamic> types = await ApiService.getTripTypes();
      if (types.isNotEmpty) {
        tripTypesList.value = types;
        // set default to first one if compatible or if currently at default
        if (tripTypesList.isNotEmpty) {
          final defaultName = isOutstationFlow.value ? "One Way" : "Local";
          final existingType = tripTypesList.firstWhereOrNull(
            (t) => t['name'].toString().trim().toLowerCase() == tripType.value.trim().toLowerCase(),
          );
          if (tripType.value.isEmpty || existingType == null || (isOutstationFlow.value && tripType.value == "Local") || (!isOutstationFlow.value && tripType.value != "Local")) {
            final target = tripTypesList.firstWhereOrNull((t) => t['name'].toString().trim().toLowerCase() == defaultName.toLowerCase());
            tripType.value = target != null ? target['name'] : tripTypesList.first['name'];
          }
        }
      }
      calculateTotalPrice();
    } catch (e) {
      debugPrint("Error fetching trip types: $e");
    } finally {
      isLoadingTripTypes.value = false;
    }
  }

  Future<void> fetchPricingSettings() async {
    final settings = await ApiService.getPublicSettings();
    if (settings.containsKey('enable_geofence_boundary')) {
      final val = settings['enable_geofence_boundary'];
      AuthStore.enableGeofenceBoundary = (val == true || val.toString().toLowerCase() == 'true');
      debugPrint("SelectRideController: Updated AuthStore.enableGeofenceBoundary = ${AuthStore.enableGeofenceBoundary}");
    }
    if (settings.containsKey('base_price_per_km')) {
      basePricePerKm.value =
          double.tryParse(settings['base_price_per_km'].toString()) ?? 10.0;
    }
    if (settings.containsKey('outstation_one_way_return_charge_rate')) {
      outstationReturnChargeRate.value =
          double.tryParse(settings['outstation_one_way_return_charge_rate'].toString()) ?? 10.0;
    }
    if (settings.containsKey('ride_request_radius')) {
      rideRequestRadius.value =
          double.tryParse(settings['ride_request_radius'].toString()) ?? 50.0;
    }
    if (settings.containsKey('outstation_max_range')) {
      outstationMaxRange.value =
          double.tryParse(settings['outstation_max_range'].toString()) ?? 500.0;
    }
    if (settings.containsKey('car_wash_price')) {
      carWashPriceSetting.value =
          double.tryParse(settings['car_wash_price'].toString()) ?? 150.0;
    }
    if (settings.containsKey('platform_charge')) {
      platformCharge.value =
          double.tryParse(settings['platform_charge'].toString()) ?? 20.0;
    }
    if (settings.containsKey('gst_percentage')) {
      gstPercentage.value =
          double.tryParse(settings['gst_percentage'].toString()) ?? 5.0;
    }

    // Parse new trip configuration settings
    if (settings.containsKey('local_enable_return_charge')) {
      final val = settings['local_enable_return_charge'];
      localEnableReturnCharge.value = (val == true || val.toString().toLowerCase() == 'true');
    }
    if (settings.containsKey('local_return_charge_rate')) {
      localReturnChargeRate.value = double.tryParse(settings['local_return_charge_rate'].toString()) ?? 10.0;
    }
    if (settings.containsKey('local_show_estimated_hours')) {
      final val = settings['local_show_estimated_hours'];
      localShowEstimatedHours.value = (val == true || val.toString().toLowerCase() == 'true');
    }
    if (settings.containsKey('outstation_round_use_estimated_hours')) {
      final val = settings['outstation_round_use_estimated_hours'];
      outstationRoundUseEstimatedHours.value = (val == true || val.toString().toLowerCase() == 'true');
    }
    if (settings.containsKey('outstation_round_enable_return_charge')) {
      final val = settings['outstation_round_enable_return_charge'];
      outstationRoundEnableReturnCharge.value = (val == true || val.toString().toLowerCase() == 'true');
    }
    if (settings.containsKey('outstation_round_return_charge_rate')) {
      outstationRoundReturnChargeRate.value = double.tryParse(settings['outstation_round_return_charge_rate'].toString()) ?? 10.0;
    }
    if (settings.containsKey('outstation_one_way_show_estimated_hours')) {
      final val = settings['outstation_one_way_show_estimated_hours'];
      outstationOneWayShowEstimatedHours.value = (val == true || val.toString().toLowerCase() == 'true');
    }
    if (settings.containsKey('outstation_one_way_enable_return_charge')) {
      final val = settings['outstation_one_way_enable_return_charge'];
      outstationOneWayEnableReturnCharge.value = (val == true || val.toString().toLowerCase() == 'true');
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Basic Haversine for simple distance
    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // km
  }


  void toggleTrip() {
    tripOpen.toggle();
    if (tripOpen.value) {
      carOpen.value = false;
      packageOpen.value = false;
    }
  }

  void toggleCar() {
    carOpen.toggle();
    if (carOpen.value) {
      tripOpen.value = false;
      packageOpen.value = false;
    }
  }

  void togglePackage() {
    packageOpen.toggle();
    if (packageOpen.value) {
      tripOpen.value = false;
      carOpen.value = false;
    }
  }



  void showNotServiceableBottomSheet({
    required double distance,
    required double maxRadius,
    String? errorText,
  }) {
    Get.bottomSheet(
      NotServiceableBottomSheet(
        distance: distance,
        maxRadius: maxRadius,
        errorText: errorText,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
    );
  }

  void openScheduleDialog() {
    if (Get.isDialogOpen == true) return;
    _actuallyOpenScheduleDialog();
  }

  void _actuallyOpenScheduleDialog() {
    final bool isOneWay = tripType.value == "One Way";

    final bool geofenceEnabled = AuthStore.enableGeofenceBoundary;
    if (geofenceEnabled &&
        pickupLat.value != 0 &&
        pickupLng.value != 0 &&
        !GeofenceUtil.isInsideChennai(pickupLat.value, pickupLng.value)) {
      Get.dialog(
        AlertDialog(
          title: const Text("Service Area Limit"),
          content: const Text(
              "We currently only offer services within the Chennai city boundary. Your selected pickup location is outside this area."),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("OK", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    if (!isAirportFlow.value && requiredHours.value > maxAllowedHours) {
      Get.snackbar("Time Limit Exceeded", "The selected route exceeds the maximum allowed time limit.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final double maxRange = isOutstationFlow.value ? outstationMaxRange.value : rideRequestRadius.value;
    if (calculatedDistance.value > maxRange) {
      Get.snackbar("Service Unavailable", "The selected destination is beyond our serviceable range from your pickup location.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (destination.value == "Destination" || destination.value.isEmpty) {
      Get.snackbar("Destination Required", "Please select a destination location.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    String finalPickup = pickup.value.trim();
    if (finalPickup == "Pickup Location" || finalPickup.isEmpty) {
      Get.snackbar("Pickup Required", "Please select a pickup location.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // 2. Schedule-Specific Mandatory Validations (Treats defaults as valid)
    if (selectedCar.value.isEmpty) {
      Get.snackbar("Vehicle Required", "Please select a vehicle category.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (selectedCarModel.value.isEmpty) {
      Get.snackbar("Model Required", "Please select a vehicle model.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (tripType.value.isEmpty) {
      Get.snackbar("Trip Type Required", "Please select a trip type.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    // Airport flow does not require a package. Local and Outstation (One Way and Round Trip) require a package, unless disabled by setting.
    final bool doesNotRequirePackage = isAirportFlow.value || !shouldShowEstimatedHours;
    if (!doesNotRequirePackage && selectedPackage.value.isEmpty) {
      Get.snackbar("Package Required", "Please select estimated usage hours.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // ✅ Stable context (avoid “unmounted context”)
    final ctx = Get.context ?? Get.overlayContext;
    if (ctx == null) return;

    String timeText(TimeOfDay t) =>
        MaterialLocalizations.of(ctx).formatTimeOfDay(t);

    Get.dialog(
      Obx(() {
        final dateText = scheduleDate.value == null
            ? "Select Date"
            : "${scheduleDate.value!.day}/${scheduleDate.value!.month}/${scheduleDate.value!.year}";

        final t = scheduleTime.value;
        final tText = t == null ? "Select Time" : timeText(t);

        return ScheduleRideDialog(
          dateText: dateText,
          timeText: tText,
          onClose: () => Get.back(),
          onPickDate: () async {
            final d = await showDatePicker(
              context: ctx,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDate: scheduleDate.value ?? DateTime.now(),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(1.0),
                  ),
                  child: child!,
                );
              },
            );
            if (isClosed) return;
            if (d != null) scheduleDate.value = d;
          },
          onPickTime: () async {
            final t = await showTimePicker(
              context: ctx,
              initialTime: scheduleTime.value ?? TimeOfDay.now(),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(1.0),
                  ),
                  child: child!,
                );
              },
            );
            if (isClosed) return;
            if (t != null) scheduleTime.value = t;
          },
          onConfirm: () {
            if (scheduleDate.value == null || scheduleTime.value == null) {
              return;
            }
            
            final now = DateTime.now();
            final scheduledDateTime = DateTime(
              scheduleDate.value!.year,
              scheduleDate.value!.month,
              scheduleDate.value!.day,
              scheduleTime.value!.hour,
              scheduleTime.value!.minute,
            );
            
            if (scheduledDateTime.isBefore(now)) {
              return;
            }
            
            Get.back();
            bookNow(isScheduled: true);
          },
        );
      }),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
    );
  }

  Future<void> bookNow({bool isScheduled = false}) async {
    debugPrint("🚕 BN[1]: bookNow() called — isScheduled=$isScheduled");
    try {
    if (destination.value == "Destination" || destination.value.isEmpty) {
      debugPrint("🚕 BN[BAIL]: destination empty/unset = '${destination.value}'");
      return;
    }

    final bool geofenceEnabled = AuthStore.enableGeofenceBoundary;
    if (geofenceEnabled &&
        pickupLat.value != 0 &&
        pickupLng.value != 0 &&
        !GeofenceUtil.isInsideChennai(pickupLat.value, pickupLng.value)) {
      Get.dialog(
        AlertDialog(
          title: const Text("Service Area Limit"),
          content: const Text(
              "We currently only offer services within the Chennai city boundary. Your selected pickup location is outside this area."),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("OK", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final bool doesNotRequirePackage = isAirportFlow.value || !shouldShowEstimatedHours;
    if (!doesNotRequirePackage && selectedPackage.value.isEmpty) {
      debugPrint("🚕 BN[BAIL]: package required but empty. tripType=${tripType.value}");
      return;
    }

    if (selectedCar.value.isEmpty) {
      debugPrint("🚕 BN[BAIL]: selectedCar is empty");
      return;
    }

    if (tripType.value.isEmpty) {
      debugPrint("🚕 BN[BAIL]: tripType is empty");
      return;
    }

    String finalPickup = pickup.value.trim();
    if (finalPickup == "Pickup Location" || finalPickup.isEmpty) {
      debugPrint("🚕 BN[BAIL]: pickup empty/default = '$finalPickup'");
      return;
    }
    debugPrint("🚕 BN[2]: Validation OK — pickup='$finalPickup', dest='${destination.value}', car='${selectedCar.value}', tripType='${tripType.value}', pkg='${selectedPackage.value}'");

    // 2. Loading State
    debugPrint("🚕 BN[3]: Opening loading dialog");
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.orange)),
      barrierDismissible: false,
    );
    debugPrint("🚕 BN[4]: Dialog opened, isDialogOpen=${Get.isDialogOpen}");

      // 2. FETCH COORDINATES & DISTANCE
      double pLat = pickupLat.value;
      double pLng = pickupLng.value;
      double dLat = dropoffLat.value;
      double dLng = dropoffLng.value;

      // Final aggressive sync from map if pickup is still 0
      if (pLat == 0 && Get.isRegistered<MapController>()) {
        final mapC = Get.find<MapController>();
        if (mapC.pickedLocation.value != null) {
          pLat = mapC.pickedLocation.value!.latitude;
          pLng = mapC.pickedLocation.value!.longitude;
          pickupLat.value = pLat;
          pickupLng.value = pLng;
        }
      }
      
      // Capture the instant fare before routing refinement to ensure consistency
      // The user wants "The same bill must propagate consistently"
      final double finalFare = totalPrice.value;
      final double finalDistance = calculatedDistance.value;
      final double finalDistanceCost = distanceCost.value;
      final double finalHourlyCost = hourlyCost.value;
      final double finalSubtotal = subtotal.value;
      final double finalGst = gstAmount.value;
      final double finalEstimatedTime = estimatedTime.value;

      debugPrint("🚕 BN[5]: Coords — pickup=($pLat,$pLng), dropoff=($dLat,$dLng), fare=$finalFare, dist=$finalDistance");
      // GENERATE ROUTING ONLY NOW (After clicking Book Now)
      debugPrint("🚕 BN[6]: Fetching route...");
      await fetchRoute();
      debugPrint("🚕 BN[7]: fetchRoute() done");
      
      final Map<String, double>? pCoords = pLat != 0 ? {'lat': pLat, 'lng': pLng} : null;
      final Map<String, double>? dCoords = dLat != 0 ? {'lat': dLat, 'lng': dLng} : null;

      // Use the captured 'instant' values for the booking to keep it consistent
      final double distance = finalDistance > 0 ? finalDistance : 10.0;
      final double fare = finalFare;

      // Time Options Check
      if (requiredHours.value > maxAllowedHours) {
        debugPrint("🚕 BN[BAIL]: requiredHours=${requiredHours.value} > maxAllowedHours=$maxAllowedHours");
        if (Get.isDialogOpen == true) Get.back();
        return;
      }

      // Range check
      final double maxRange = isOutstationFlow.value ? outstationMaxRange.value : rideRequestRadius.value;
      if (distance > maxRange) {
        debugPrint("🚕 BN[BAIL]: distance=$distance > maxRange=$maxRange");
        if (Get.isDialogOpen == true) Get.back();
        Get.snackbar("Service Unavailable", "The selected destination is beyond our serviceable range from your pickup location.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // 3. FETCH FARE FROM BACKEND (Dynamic package based calculation)
      debugPrint("🚕 BN[8]: Calling calculateRideFare — carType=${selectedCar.value}, pkg=${selectedPackage.value}, dist=$distance");
      final fareRes = await ApiService.calculateRideFare(
        carType: selectedCar.value,
        packageDuration: selectedPackage.value,
        tripType: tripType.value,
        distance: distance,
      );

      debugPrint("🚕 BN[9]: calculateRideFare result → $fareRes");
      if (fareRes.containsKey('error')) {
        debugPrint("🚕 BN[BAIL]: calculateRideFare error → ${fareRes['error']}");
        if (Get.isDialogOpen == true) Get.back();
        return;
      }

      // We use the captured fare from before routing refinement for consistency
      // final double fare = totalPrice.value; // REPLACED by finalFare captured above
      final double packageHours = ((fareRes['packageHours'] ?? 0) as num).toDouble();
      final double hourlyRate = ((fareRes['hourlyRate'] ?? 0) as num).toDouble();

      debugPrint("🚕 BN[10]: Calling bookRide — fare=$fare, dist=$distance, pCoords=$pCoords, dCoords=$dCoords");
      final res = await ApiService.bookRide(
        pickupLocation: finalPickup,
        dropoffLocation: destination.value,
        fare: fare,
        distance: distance,
        carType: selectedCar.value,
        carModel: selectedCarModel.value,
        package: selectedPackage.value,
        tripType: tripType.value,
        transmission: transmission.value,
        travelPlanDetails: travelPlanController.text.trim(),
        requireCarWash: requireCarWash.value,
        carWashPrice: carWashPriceSetting.value,
        pickupCoords: pCoords,
        dropoffCoords: dCoords,
        isScheduled: isScheduled,
        scheduledAt:
            isScheduled &&
                scheduleDate.value != null &&
                scheduleTime.value != null
            ? DateTime(
                scheduleDate.value!.year,
                scheduleDate.value!.month,
                scheduleDate.value!.day,
                scheduleTime.value!.hour,
                scheduleTime.value!.minute,
              ).toUtc().toIso8601String()
            : null,
        hourlyRate: hourlyRate, 
        packageHours: packageHours, 
        estimatedTime: finalEstimatedTime > 0 ? finalEstimatedTime : (distance * 4).roundToDouble(), 
        distanceCost: finalDistanceCost,
        hourlyCost: finalHourlyCost,
        subtotal: finalSubtotal,
        platformCharge: platformCharge.value,
        gst: finalGst,
        isOutstation: isOutstationFlow.value,
        returnCharge: returnCharge.value,
      );

      debugPrint("🚕 BN[11]: bookRide response keys=${res.keys.toList()}, hasError=${res.containsKey('error')}");
      if (Get.isDialogOpen == true) {
        debugPrint("🚕 BN[12]: Closing loading dialog");
        Get.back();
      }

      if (res.containsKey('error')) {
        debugPrint("🚕 BN[13-ERR]: bookRide returned error → ${res['error']}");
        if (Get.isDialogOpen == true) Get.back();
        final errorMsg = res['error']?.toString() ?? "";
        if (errorMsg.contains("exceeds the service range limit") ||
            errorMsg.contains("Out of range") ||
            errorMsg.contains("serviced area") ||
            errorMsg.contains("boundary")) {
          Get.snackbar(
            "Service Unavailable",
            errorMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            "Service Unavailable",
            res['error'] ?? "You are out of chennai boundary area.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        final rideId =
            res['_id']?.toString() ?? res['data']?['_id']?.toString();
        debugPrint("🚕 BN[13]: bookRide SUCCESS → rideId=$rideId");

        if (isScheduled) {
          debugPrint("🚕 BN[14]: Starting scheduled wait for rideId=$rideId");
          _startScheduledWait(rideId!);
        } else {
          debugPrint("🚕 BN[14]: Navigating to findingDriver → rideId=$rideId");

          // ✅ KEY FIX: Force-delete any stale FindingDriverController so the
          // FindingDriverBinding creates a FRESH instance for this new ride.
          // Without this, Get.lazyPut returns the OLD controller (with stage=tripCompleted
          // from a previous ride) which causes a white screen / wrong UI state.
          if (Get.isRegistered<FindingDriverController>()) {
            debugPrint("🚕 BN[14b]: Deleting stale FindingDriverController before navigation");
            Get.delete<FindingDriverController>(force: true);
          }

          Get.toNamed(
            Routes.findingDriver,
            arguments: {
              "rideId": rideId,
              "status": "Pending",
              "car": selectedCar.value,
              "carModel": selectedCarModel.value,
              "package": selectedPackage.value,
              "pickup": finalPickup,
              "destination": destination.value,
              "fare": fare,
              "pickupLat": pCoords?['lat'],
              "pickupLng": pCoords?['lng'],
              "dropoffLat": dCoords?['lat'],
              "dropoffLng": dCoords?['lng'],
              "isScheduled": isScheduled,
              "distanceCost": distanceCost.value,
              "hourlyCost": hourlyCost.value,
            },
          );
          debugPrint("🚕 BN[15]: Get.toNamed(findingDriver) called ✅");
        }
      }
    } catch (e, stack) {
      debugPrint("🚕 BN[ERROR]: bookNow threw → $e");
      debugPrint("🚕 BN[STACK]: $stack");
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }





  Future<void> cancelScheduledRide(String rideId) async {
    if (rideId.isEmpty) return;

    try {
      // 1. Stop wait timer
      _scheduleWaitTimer?.cancel();
      _scheduleWaitTimer = null;

      // 2. Call API to cancel
      final res = await ApiService.updateRideStatus(rideId, 'Cancelled');

      if (res.containsKey('error')) {
        // Failure handled by FCM
      } else {
        // Success handled by FCM
      }
      
      // 3. Close dialog and go home
      if (Get.isDialogOpen == true) Get.back();
      Get.offAllNamed(Routes.home);
      
    } catch (e) {
      debugPrint("Error cancelling scheduled ride: $e");
      if (Get.isDialogOpen == true) Get.back();
      Get.offAllNamed(Routes.home);
    }
  }

  void _startScheduledWait(String rideId) {
    scheduleWaitTime.value = 120;
    
    // 1. Show waiting dialog
    Get.dialog(
      PopScope(
        canPop: false,
        child: Obx(() => Scaffold(
          backgroundColor: Colors.black26,
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Scheduled Booking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  const Text("Waiting for a driver to accept your scheduled trip...", textAlign: TextAlign.center),
                  const SizedBox(height: 25),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: scheduleWaitTime.value / 120,
                          strokeWidth: 8,
                          color: Colors.orange,
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        ),
                      ),
                      Text(
                        "${scheduleWaitTime.value}s",
                        style: const TextStyle(fontSize: 22, color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text("Please don't close this screen", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => cancelScheduledRide(rideId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text("Cancel Booking", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );

    // 2. Start countdown timer
    _scheduleWaitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (scheduleWaitTime.value > 0) {
        scheduleWaitTime.value--;
      } else {
        _stopScheduledWait();
        // TRIGGER FCM NOTIFICATION FOR RIDER
        ApiService.sendRideNotification(
          rideId: rideId,
          title: 'Ride Search Continuing',
          body: 'No immediate driver was found for your scheduled ride. We will continue searching and notify you once assigned.',
          type: 'scheduled_searching_update'
        );
        Get.offAllNamed(Routes.home);
      }
    });

    // 3. Listen for acceptance via socket
    final socketService = Get.find<SocketService>();
    socketService.joinRide(rideId);
    
    socketService.socket?.on('ride:status_changed', (data) {
      if (data != null && data['_id'].toString() == rideId) {
        if (data['status'] == 'Accepted') {
           _stopScheduledWait();
           _showScheduledAcceptedDialog(data);
        }
      }
    });
  }

  void _stopScheduledWait() {
    _scheduleWaitTimer?.cancel();
    _scheduleWaitTimer = null;
    if (Get.isDialogOpen == true) Get.back();
  }

  void _showScheduledAcceptedDialog(Map<String, dynamic> data) {
    final driver = data['driverId'];
    if (driver == null) return;

    final String name = driver['name'] ?? "Driver";
    final String image = ApiService.getImageUrl(driver['profileImage']?.toString());
    final String phone = driver['phone']?.toString() ?? "";
    final String exp = "${driver['expYear'] ?? '0'} years of exp";
    final double total = (driver['totalRating'] ?? 0.0).toDouble();
    final int count = (driver['ratingCount'] ?? 0).toInt();
    final String rating = count > 0 ? (total / count).toStringAsFixed(1) : "0.0";

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 15),
                  const Text("Hurray, Your schedule booking is confirmed", 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                          backgroundImage: (image.isNotEmpty && image.startsWith('http')) ? NetworkImage(image) : null,
                          child: (image.isEmpty || !image.startsWith('http')) ? const Icon(Icons.person, size: 45, color: Colors.orange) : null,
                        ),
                        const SizedBox(height: 15),
                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(phone, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 15),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 20),
                              Text(" $rating", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 15),
                              const Icon(Icons.work, color: Colors.blue, size: 20),
                              Text(" $exp", style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.offAllNamed(Routes.home);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );

    // Close after 5 seconds and go home
    Future.delayed(const Duration(seconds: 5), () {
      if (Get.isDialogOpen == true) {
        Get.back();
        Get.offAllNamed(Routes.home);
      }
    });
  }

  void onDestinationChanged(String q) {
    _destSearchDebounce?.cancel();
    if (q.trim().isEmpty) {
      destinationSuggestions.clear();
      return;
    }
    _destSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchDestination(q);
    });
  }

  Future<void> searchDestination(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    try {
      isSearchingDestination.value = true;
      debugPrint("Searching destination via Google: $q");

      final apiKey = ApiService.googleMapsApiKey ?? AuthStore.googleMapsApiKey;
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint("Destination search failed: No API Key available");
        destinationSuggestions.clear();
        return;
      }

      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(q)}&key=$apiKey&components=country:in",
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        debugPrint("Google Search API error: ${res.statusCode}");
        destinationSuggestions.clear();
        return;
      }

      final data = jsonDecode(res.body);
      if (data['status'] != 'OK') {
        debugPrint("Google Search API Status: ${data['status']}");
        destinationSuggestions.clear();
        return;
      }

      final List<dynamic> predictions = data['predictions'];
      final list = predictions.map((json) {
        return PlaceSuggestion(
          displayName: json['description'],
          latLng: const LatLng(0, 0), // Will be geocoded on selection
        );
      }).toList();

      destinationSuggestions.assignAll(list);
      debugPrint("Google Suggestions found: ${list.length}");
    } catch (e) {
      debugPrint("Destination search failed: $e");
      destinationSuggestions.clear();
    } finally {
      isSearchingDestination.value = false;
    }
  }

  Future<void> selectDestinationSuggestion(PlaceSuggestion s) async {
    final apiKey = ApiService.googleMapsApiKey ?? AuthStore.googleMapsApiKey;
    if (apiKey == null || apiKey.isEmpty) return;

    try {
      isSearchingDestination.value = true;
      final url = Uri.parse(
          "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(s.displayName)}&key=$apiKey");
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final loc = data['results'][0]['geometry']['location'];
        final latLng = LatLng(loc['lat'], loc['lng']);

        destinationSuggestions.clear();
        destinationTextController.text = s.displayName;
        destination.value = s.displayName;
        dropoffLat.value = latLng.latitude;
        dropoffLng.value = latLng.longitude;
        
        // Reset route distance to force instant Haversine fallback
        routedDistance.value = 0.0;
        routedDuration.value = 0.0;

        if (Get.isRegistered<MapController>()) {
          final mapC = Get.find<MapController>();
          // Sync with map layer
          mapC.pickedLocation.value = latLng;
          mapC.currentAddressSubtitle.value = s.displayName;
          // Optionally move map but for destination selection, 
          // we usually just want to record the coordinates
        }

        // Unfocus the search field
        Get.focusScope?.unfocus();

        // Instantly calculate the distance and price
        calculateTotalPrice();
        
        // Then fetch the accurate route
        fetchRoute();

        // Save to recent destinations
        saveRecentDestination(s.displayName, latLng.latitude, latLng.longitude);
      }
    } catch (e) {
      debugPrint("Select destination suggestion failed: $e");
    } finally {
      isSearchingDestination.value = false;
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _scheduleWaitTimer?.cancel();
    _paymentService.dispose();
    _destSearchDebounce?.cancel();
    travelPlanController.dispose();
    travelPlanFocusNode.dispose();
    super.onClose();
  }
}

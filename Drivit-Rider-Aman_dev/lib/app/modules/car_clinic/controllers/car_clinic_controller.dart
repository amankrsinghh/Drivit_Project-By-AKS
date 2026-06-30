import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../map/controllers/map_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CarClinicController extends GetxController {
  final isLoadingServices = false.obs;
  final isLoadingBookings = false.obs;
  final isBooking = false.obs;

  final services = <dynamic>[].obs;
  final bookings = <dynamic>[].obs;

  // Selected Service & Booking Details
  final selectedService = Rxn<dynamic>();
  final pickupAddress = "".obs;
  final pickupLat = 0.0.obs;
  final pickupLng = 0.0.obs;
  final scheduledDate = Rxn<DateTime>();
  final scheduledTime = Rxn<TimeOfDay>();

  // Fare Details (Calculated locally first for preview)
  final basePrice = 0.0.obs;
  final platformCharge = 20.0.obs;
  final gstPercentage = 5.0.obs;

  double get gstAmount => (basePrice.value + platformCharge.value) * (gstPercentage.value / 100.0);
  double get totalFare => basePrice.value + platformCharge.value + gstAmount;

  @override
  void onInit() {
    super.onInit();
    fetchServices();
    fetchMyBookings();
    loadDefaultLocation();
  }

  Future<void> fetchServices() async {
    isLoadingServices.value = true;
    try {
      final data = await ApiService.getClinicServices();
      services.value = data;
    } catch (e) {
      Get.snackbar("Error", "Failed to load services");
    } finally {
      isLoadingServices.value = false;
    }
  }

  Future<void> fetchMyBookings() async {
    isLoadingBookings.value = true;
    try {
      final data = await ApiService.getMyClinicBookings();
      bookings.value = data;
    } catch (e) {
      Get.snackbar("Error", "Failed to load bookings");
    } finally {
      isLoadingBookings.value = false;
    }
  }

  Future<void> loadDefaultLocation() async {
    try {
      if (Get.isRegistered<MapController>()) {
        final mapC = Get.find<MapController>();
        if (mapC.currentAddressSubtitle.value.isNotEmpty && mapC.currentAddressSubtitle.value != "Fetching address...") {
          pickupAddress.value = mapC.currentAddressSubtitle.value;
          final pos = mapC.userPosition.value ?? mapC.pickedLocation.value;
          if (pos != null) {
            pickupLat.value = pos.latitude;
            pickupLng.value = pos.longitude;
          }
        }
      }
      
      if (pickupAddress.value.isEmpty) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
          pickupLat.value = pos.latitude;
          pickupLng.value = pos.longitude;
          
          if (Get.isRegistered<MapController>()) {
            final mapC = Get.find<MapController>();
            await mapC.refreshAddressForLocation(LatLng(pos.latitude, pos.longitude));
            pickupAddress.value = mapC.currentAddressSubtitle.value;
          } else {
            pickupAddress.value = "${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}";
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading default location for clinic: $e");
    }
  }

  void selectService(dynamic service) {
    selectedService.value = service;
    basePrice.value = (service['basePrice'] ?? 0.0).toDouble();
  }

  Future<void> bookClinicJob() async {
    if (selectedService.value == null) {
      Get.snackbar("Error", "Please select a service", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (pickupAddress.value.isEmpty || pickupLat.value == 0) {
      Get.snackbar("Error", "Please select a valid pickup location", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (scheduledDate.value == null || scheduledTime.value == null) {
      Get.snackbar("Error", "Please select a date and time for schedule", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isBooking.value = true;
    try {
      final scheduleDateTime = DateTime(
        scheduledDate.value!.year,
        scheduledDate.value!.month,
        scheduledDate.value!.day,
        scheduledTime.value!.hour,
        scheduledTime.value!.minute,
      );

      final res = await ApiService.bookClinicService(
        serviceId: selectedService.value!['_id'],
        pickupLocation: pickupAddress.value,
        pickupCoords: {'lat': pickupLat.value, 'lng': pickupLng.value},
        scheduledAt: scheduleDateTime.toUtc().toIso8601String(),
      );

      if (res.containsKey('error')) {
        Get.snackbar("Booking Failed", res['error']?.toString() ?? "Could not book service", backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        Get.snackbar("Success", "Your Car Clinic booking has been placed successfully!", backgroundColor: Colors.green, colorText: Colors.white);
        fetchMyBookings();
        Get.back();
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isBooking.value = false;
    }
  }

  Future<void> cancelClinicJob(String id) async {
    try {
      final res = await ApiService.cancelClinicBooking(id);
      if (res.containsKey('error')) {
        Get.snackbar("Error", res['error']?.toString() ?? "Could not cancel booking", backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        Get.snackbar("Cancelled", "Booking cancelled successfully", backgroundColor: Colors.green, colorText: Colors.white);
        fetchMyBookings();
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}

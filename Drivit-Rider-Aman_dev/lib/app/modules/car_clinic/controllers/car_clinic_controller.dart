import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/services/payment_service.dart';
import '../../map/controllers/map_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../routes/app_routes.dart';
import 'package:geolocator/geolocator.dart';

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
  final selectedPaymentMethod = "Cash".obs; // 'Cash' or 'Razorpay'
  final activeTabIndex = 0.obs; // Tab selection: 0 for Services, 1 for Bookings

  // Fare Details (Calculated locally first for preview)
  final basePrice = 0.0.obs;
  final platformCharge = 20.0.obs;
  final gstPercentage = 5.0.obs;

  final PaymentService _paymentService = PaymentService();

  double get gstAmount => (basePrice.value + platformCharge.value) * (gstPercentage.value / 100.0);
  double get totalFare => basePrice.value + platformCharge.value + gstAmount;

  @override
  void onInit() {
    super.onInit();
    fetchServices();
    fetchMyBookings();
    loadDefaultLocation();
  }

  @override
  void onClose() {
    _paymentService.dispose();
    super.onClose();
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

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final apiKey = ApiService.googleMapsApiKey;
      if (apiKey == null || apiKey.isEmpty) return "$lat, $lng";
      final url = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] ?? "$lat, $lng";
        }
      }
    } catch (e) {
      debugPrint("Direct reverse geocoding failed: $e");
    }
    return "$lat, $lng";
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
      
      if (pickupAddress.value.isEmpty || pickupAddress.value.contains(RegExp(r'^\d+\.\d+'))) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
          pickupLat.value = pos.latitude;
          pickupLng.value = pos.longitude;
          pickupAddress.value = "Fetching address...";
          
          final address = await _reverseGeocode(pos.latitude, pos.longitude);
          pickupAddress.value = address;
        }
      }
    } catch (e) {
      debugPrint("Error loading default location for clinic: $e");
    }
  }

  Future<void> pickLocationFromMap() async {
    try {
      final result = await Get.toNamed(Routes.mapConfirm, arguments: {'returnLocation': true});
      if (result != null && result is Map) {
        pickupAddress.value = result['address'] ?? '';
        pickupLat.value = (result['lat'] as num).toDouble();
        pickupLng.value = (result['lng'] as num).toDouble();
      }
    } catch (e) {
      debugPrint("Error picking location from map: $e");
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

    if (selectedPaymentMethod.value == "Razorpay") {
      isBooking.value = true;
      try {
        String userPhone = "";
        String userEmail = "";
        
        if (Get.isRegistered<ProfileController>()) {
          final profileC = Get.find<ProfileController>();
          userPhone = profileC.phone.value;
          userEmail = profileC.email.value;
        }

        await _paymentService.startPayment(
          amount: totalFare,
          description: "Car Clinic Service - ${selectedService.value!['name']}",
          userPhone: userPhone.isNotEmpty ? userPhone : "9999999999",
          userEmail: userEmail.isNotEmpty ? userEmail : "user@drivit.com",
          onSuccess: (paymentId) async {
            await _createClinicBooking(paymentId: paymentId);
          },
          onFailure: (error) {
            isBooking.value = false;
            Get.snackbar("Payment Failed", error, backgroundColor: Colors.red, colorText: Colors.white);
          },
        );
      } catch (e) {
        isBooking.value = false;
        Get.snackbar("Error", "Could not initiate payment: $e", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } else {
      isBooking.value = true;
      await _createClinicBooking();
    }
  }

  Future<void> _createClinicBooking({String? paymentId}) async {
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
        paymentMethod: selectedPaymentMethod.value,
        paymentId: paymentId,
      );

      if (res.containsKey('error')) {
        Get.snackbar("Booking Failed", res['error']?.toString() ?? "Could not book service", backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        fetchMyBookings();
        Get.defaultDialog(
          title: "Booking Successful",
          middleText: "Your Car Clinic booking has been placed successfully!",
          textConfirm: "OK",
          confirmTextColor: Colors.white,
          buttonColor: const Color(0xffF38900),
          onConfirm: () {
            Get.back(); // Pop the dialog
            activeTabIndex.value = 1; // Switch tab to My Bookings
            Get.back(); // Pop the booking details checkout page
          },
        );
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

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/api_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../map/controllers/map_controller.dart';
import '../../../../core/utils/validators.dart';
import '../../login/controllers/login_controller.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  // Car Details
  final carModelController = TextEditingController();
  final carNumberController = TextEditingController();
  final carType = 'Manual'.obs; // From Image: Manual/Automatic

  final currentStep = 0.obs; // 0: Profile, 1: Car Details
  final isLoading = false.obs;
  final isPhoneReadOnly = false.obs;

  // Address Detection & Search
  final isAddressLoading = false.obs;
  final addressSuggestions = <PlaceSuggestion>[].obs;
  Timer? _searchDebounce;

  // Real-time Errors & Values
  final nameError = RxnString();
  final phoneError = RxnString();
  final emailError = RxnString();
  final addressError = RxnString();
  
  final name = "".obs;
  final phone = "".obs;
  final email = "".obs;
  final address = "".obs;

  void validateFields() {
    name.value = nameController.text.trim();
    phone.value = phoneController.text.trim();
    email.value = emailController.text.trim();
    address.value = addressController.text.trim();

    nameError.value = name.value.isEmpty ? null : Validators.validateName(name.value);
    phoneError.value = phone.value.isEmpty ? null : Validators.validatePhone(phone.value);
    emailError.value = email.value.isEmpty ? null : Validators.validateEmail(email.value);
    addressError.value = address.value.isEmpty ? null : Validators.validateRequired(address.value, 'Address');
  }

  bool isFormValid() {
    return name.value.isNotEmpty &&
           phone.value.length == 10 &&
           email.value.isNotEmpty &&
           address.value.isNotEmpty &&
           nameError.value == null &&
           phoneError.value == null &&
           emailError.value == null &&
           addressError.value == null;
  }

  @override
  void onInit() {
    super.onInit();
    
    // Add listeners for reactivity
    nameController.addListener(validateFields);
    phoneController.addListener(validateFields);
    emailController.addListener(validateFields);
    addressController.addListener(validateFields);

    // Check if we came from Login -> OTP flow
    if (Get.arguments != null && Get.arguments['phone'] != null) {
      phoneController.text = Get.arguments['phone'];
      isPhoneReadOnly.value = true;
    } 
    // Manual registration (clicked "Register" on Login screen)
    // always starts with a blank phone field, per user request.
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    carModelController.dispose();
    carNumberController.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }

  // ---------- Auto Detect ----------
  Future<void> autoDetectAddress() async {
    try {
      isAddressLoading.value = true;
      addressSuggestions.clear();

      // 1. Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      // 2. Get coords
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      
      // 3. Reverse Geocode (Nominatim)
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${pos.latitude}&lon=${pos.longitude}",
      );
      final res = await http.get(url, headers: const {"User-Agent": "DrivitRider/1.0"});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final displayName = data['display_name'] ?? "";
        if (displayName.isNotEmpty) {
          addressController.text = displayName;
        }
      }
    } catch (e) {
    } finally {
      isAddressLoading.value = false;
    }
  }

  // ---------- Search Address ----------
  void onAddressChanged(String q) {
    _searchDebounce?.cancel();
    if (q.trim().length < 3) {
      addressSuggestions.clear();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () => _searchAddress(q));
  }

  Future<void> _searchAddress(String query) async {
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(query)}&limit=5",
      );
      final res = await http.get(url, headers: const {"User-Agent": "DrivitRider/1.0"});

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final list = data.map((json) => PlaceSuggestion.fromJson(json)).toList();
        addressSuggestions.assignAll(list);
      }
    } catch (e) {
      debugPrint("Address search error: $e");
    }
  }

  void selectAddress(PlaceSuggestion suggestion) {
    addressController.text = suggestion.displayName;
    addressSuggestions.clear();
    // Unfocus
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> nextStep() async {
    final nameErr = Validators.validateName(nameController.text);
    if (nameErr != null) {
      return;
    }

    final phone = phoneController.text.trim();
    final phoneErr = Validators.validatePhone(phone);
    if (phoneErr != null) {
      return;
    }

    final emailErr = Validators.validateEmail(emailController.text);
    if (emailErr != null) {
      return;
    }

    // ✅ Availability check (Email & Phone)
    isLoading.value = true;
    final res = await ApiService.checkAvailability(
      email: emailController.text.trim(),
      phone: phone,
    );
    isLoading.value = false;

    if (res.containsKey('exists') && res['exists'] == true) {
      return;
    }

    final addressErr = Validators.validateRequired(addressController.text, 'Address');
    if (addressErr != null) {
      return;
    }
    
    // ✅ Save registration data locally early
    await ApiService.saveRegistrationData(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
    );

    // ✅ If phone is NOT read-only, it means we entered it manually.
    // We MUST verify it via OTP now.
    if (!isPhoneReadOnly.value) {
      isLoading.value = true;
      final otpRes = await ApiService.sendOtp(phone);
      isLoading.value = false;

      if (otpRes.containsKey('error')) {
        return;
      }

      // Store phone for verification
      await ApiService.saveSession("", ""); // Clear any old sessions
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_phone', phone);
      
      // Start OTP timer (LoginController manages the timer for the OTP screen)

      // Start OTP timer (LoginController manages the timer for the OTP screen)
      if (Get.isRegistered<LoginController>()) {
        Get.find<LoginController>().startTimer();
      }

      // Go to OTP page with context of registration
      Get.toNamed("${Routes.login}/otp", arguments: {
        'phone': phone,
        'fromRegister': true,
        'otp': otpRes['otp'], // for testing/helper
      });
    } else {
      // Proceed to map confirmation
      await ApiService.setRegistrationStep(2);
      Get.toNamed(Routes.mapConfirm);
    }
  }

  void prevStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    } else {
      // ✅ Back logic must work even if stack is empty (after offAllNamed)
      if (Get.previousRoute.isEmpty) {
        Get.offAllNamed(Routes.login);
      } else {
        Get.back();
      }
    }
  }

  Future<void> register() async {
    // Sync address from map if available
    if (Get.isRegistered<MapController>()) {
      final mapController = Get.find<MapController>();
      if (mapController.currentAddressSubtitle.value.isNotEmpty &&
          mapController.currentAddressSubtitle.value != "Fetching address..." &&
          mapController.currentAddressSubtitle.value != "Address not available") {
        addressController.text = mapController.currentAddressSubtitle.value;
      }
    }

    final nameErr = Validators.validateName(nameController.text);
    if (nameErr != null) {
      return;
    }

    final phoneErr = Validators.validatePhone(phoneController.text);
    if (phoneErr != null) {
      return;
    }

    final emailErr = Validators.validateEmail(emailController.text);
    if (emailErr != null) {
      return;
    }

    final addressErr = Validators.validateRequired(addressController.text, 'Address');
    if (addressErr != null) {
      return;
    }

    // ✅ Save registration data locally so it can be recovered on restart
    await ApiService.saveRegistrationData(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
    );

    // ✅ Do NOT call ApiService.registerCustomer yet. 
    // Advance to Step 3 (Car Details) first.
    await ApiService.setRegistrationStep(3); 
    Get.toNamed(Routes.carDetails);
  }
}

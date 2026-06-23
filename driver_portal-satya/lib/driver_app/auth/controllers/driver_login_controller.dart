import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/driver_routes.dart';
import '../../../services/api_service.dart';

class DriverLoginController extends GetxController {
  final phoneController = TextEditingController();
  final agreed = true.obs;
  final isLoading = false.obs;

  void toggle(bool? v) {
    agreed.value = v ?? false;
    validatePhone();
  }

  final phoneError = RxnString();
  final phone = "".obs;

  void validatePhone() {
    phone.value = phoneController.text.trim();
    if (phone.value.isEmpty) {
      phoneError.value = null;
    } else if (phone.value.length != 10) {
      phoneError.value = "Enter 10 digit mobile number";
    } else {
      phoneError.value = null;
    }
  }

  bool isFormValid() {
    return phone.value.length == 10 && 
           phoneError.value == null && 
           agreed.value;
  }

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10 || !agreed.value) {
      return;
    }

    isLoading.value = true;
    final res = await ApiService.sendOtp(phone);
    isLoading.value = false;

    if (res['error'] != null) {
      // Backend will send FCM if needed
    } else {
      final otp = res['otp']?.toString();
      Get.toNamed(DriverRoutes.otp, arguments: {
        'phone': phone,
        'otp': otp,
      });
    }
  }

  void login() => sendOtp();

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}

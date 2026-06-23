import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/payment_service.dart';
import '../../profile/controllers/driver_profile_controller.dart';

class DriverPackageController extends GetxController {
  final packages = <dynamic>[].obs;
  final isLoading = false.obs;
  final currentPackage = Rxn<Map<String, dynamic>>();
  final isLoadingCurrent = false.obs;
  
  late PaymentService _paymentService;

  @override
  void onInit() {
    super.onInit();
    _paymentService = PaymentService();
    fetchPackages();
    fetchCurrentPackage();
  }

  @override
  void onClose() {
    _paymentService.dispose();
    super.onClose();
  }

  Future<void> fetchPackages() async {
    try {
      isLoading.value = true;
      final res = await ApiService.getDriverPackages();
      packages.assignAll(res);
    } catch (e) {
      debugPrint("Error fetching packages: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCurrentPackage() async {
    try {
      isLoadingCurrent.value = true;
      final res = await ApiService.getCurrentDriverPackage();
      if (res.containsKey('active') && res['active'] == true) {
        currentPackage.value = res['package'];
      } else {
        currentPackage.value = null;
      }
    } catch (e) {
      debugPrint("Error fetching current package: $e");
    } finally {
      isLoadingCurrent.value = false;
    }
  }

  Future<void> buyPackage(dynamic pkg) async {
    if (currentPackage.value != null) {
      return;
    }

    final profileController = Get.find<DriverProfileController>();
    final double amount = (pkg['cost'] ?? 0).toDouble();

    try {
      // ✅ Show loading immediately
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
        barrierDismissible: false,
      );

      await _paymentService.startPayment(
        amount: amount,
        description: "Purchase of ${pkg['name']}",
        userPhone: profileController.phone.value,
        userEmail: profileController.email.value,
        onSuccess: (paymentId) => _completePackagePurchase(pkg['_id'], paymentId),
        onFailure: (error) {
           if (Get.isDialogOpen == true) Get.back(); // Hide loading on failure
           // Snackbar removed: Backend handles failure FCM if needed
        },
        onOpened: () {
          // ✅ Hide loading as soon as Razorpay loads/opens
          if (Get.isDialogOpen == true) Get.back();
        },
      );
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
    }
  }

  Future<void> _completePackagePurchase(String packageId, String paymentId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.orange)),
        barrierDismissible: false,
      );
      
      final res = await ApiService.buyDriverPackage(packageId, paymentId);
      
      if (Get.isDialogOpen == true) Get.back();

      if (res.containsKey('error')) {
        // Error handling: FCM sent by backend
      } else {
        fetchCurrentPackage();
        // Also update profile as wallet might be active now
        Get.find<DriverProfileController>().fetchProfile();
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
    }
  }
}


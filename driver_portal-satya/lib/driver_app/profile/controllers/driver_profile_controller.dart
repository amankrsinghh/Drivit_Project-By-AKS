import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../routes/driver_routes.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../../history/controllers/driver_history_controller.dart';
import '../../finding/controllers/driver_finding_controller.dart';
import '../../package/controllers/driver_package_controller.dart';
import 'driver_wallet_controller.dart';
import '../../../services/notification_service.dart';

class DriverProfileController extends GetxController {
  final name = "Loading...".obs;
  final phone = "Loading...".obs;
  final email = "Loading...".obs;
  final profileImage = "".obs;
  final walletBalance = 0.0.obs;
  final isWalletActive = false.obs;
  final avgRating = 0.0.obs;
  final expYear = "0".obs;
  final displayId = "".obs;
  final isLoading = false.obs;

  final driverData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Use synchronously pre-loaded cache if available
    if (ApiService.cachedProfile != null) {
      updateWithDriverData(ApiService.cachedProfile!);
    } else {
      _loadCachedProfile();
    }
    fetchProfile(); // Internal fetch
  }

  Future<void> _loadCachedProfile() async {
    final cached = await ApiService.getCachedDriverProfile();
    if (cached != null) {
      updateWithDriverData(cached);
    }
  }


  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final res = await ApiService.getDriverProfile();
      if (res != null && res['error'] == null) {
        updateWithDriverData(res);
        await ApiService.saveDriverProfile(res);
      } else {
        // If error is 401 or user not found, logout
        if (res != null && res['error'] != null) {
          final error = res['error'].toString().toLowerCase();
          if (error.contains('not found') || error.contains('not authorized')) {
             logout();
             return;
          }
        }
        
        // Only set error if we don't have cached data yet
        if (driverData.isEmpty) {
          name.value = "Error loading";
        }
        debugPrint("Profile Fetch Error: ${res?['error']}");
      }
    } catch (e) {
      if (driverData.isEmpty) {
        name.value = "Error";
      }
      debugPrint("Profile Fetch Exception: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void updateWithDriverData(Map<String, dynamic> data) {
    driverData.value = data;
    name.value = data['name'] ?? 'No Name';
    phone.value = data['phone'] ?? 'No Phone';
    email.value = data['email'] ?? 'No Email';
    profileImage.value = data['profileImage'] ?? '';
    walletBalance.value = (data['walletBalance'] ?? 0.0).toDouble();
    isWalletActive.value = data['isWalletActive'] ?? false;
    final double totalRating = (data['totalRating'] ?? 0.0).toDouble();
    final int ratingCount = (data['ratingCount'] ?? 0).toInt();
    avgRating.value = ratingCount > 0 ? totalRating / ratingCount : 0.0;
    expYear.value = (data['expYear'] ?? '0').toString();
    displayId.value = data['displayId'] ?? '';
  }

  void login(Map<String, dynamic> data) {
    updateWithDriverData(data);
  }

  void logout() async {
    debugPrint("Logging out driver...");
    await ApiService.logout();

    // Clear all controllers to prevent stale data for next login
    try {
      Get.delete<DriverHomeController>(force: true);
      Get.delete<DriverHistoryController>(force: true);
      Get.delete<DriverProfileController>(force: true);
      Get.delete<SocketService>(force: true);
      Get.delete<DriverFindingController>(force: true);
      Get.delete<DriverPackageController>(force: true);
      Get.delete<DriverWalletController>(force: true);
    } catch (e) {
      debugPrint("Error clearing controllers: $e");
    }

    Get.offAllNamed(DriverRoutes.login);
  }

  // Rate us
  final rating = 4.obs;
  final feedbackC = TextEditingController();

  void setRating(int v) => rating.value = v;

  void submitFeedback() {
    NotificationService().showLocalNotification(
      title: "Thank you",
      body: "Review submitted",
    );
  }

  void addToWallet(double amount) {
    walletBalance.value = walletBalance.value + amount;
  }

  @override
  void onClose() {
    feedbackC.dispose();
    super.onClose();
  }
}

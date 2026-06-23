import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../routes/driver_routes.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/notification_service.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../../history/controllers/driver_history_controller.dart';
import '../../profile/controllers/driver_profile_controller.dart';
import '../../finding/controllers/driver_finding_controller.dart';
import '../../package/controllers/driver_package_controller.dart';
import '../../profile/controllers/driver_wallet_controller.dart';
import 'driver_register_controller.dart';

class DriverOtpController extends GetxController {
  final otpC = TextEditingController();
  final isLoading = false.obs;
  final otpError = "".obs;
  final receivedOtp = Rx<String?>(null);
  String phone = '';

  @override
  void onInit() {
    super.onInit();
    phone = Get.arguments?['phone'] ?? '';
    final argOtp = Get.arguments?['otp']?.toString();
    if (argOtp != null && argOtp.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        onOtpReceived(argOtp);
      });
    }
  }

  void onOtpReceived(String code) {
    receivedOtp.value = code;
  }

  void applyOtp() {
    if (receivedOtp.value != null) {
      otpC.text = receivedOtp.value!;
      receivedOtp.value = null;
      verify();
    }
  }

  void dismissOtp() {
    receivedOtp.value = null;
  }

  void resendOtp() async {
    final res = await ApiService.sendOtp(phone);
    if (res['error'] != null) {
      // Backend FCM handles this if needed
    } else {
      final otp = res['otp']?.toString();
      if (otp != null && otp.isNotEmpty) {
        onOtpReceived(otp);
      }
    }
  }

  void verify() async {
    if (otpC.text.isEmpty) {
      return;
    }

    final bool isFromRegister = Get.arguments?['fromRegister'] ?? false;

    isLoading.value = true;
    otpError.value = "";
    final res = await ApiService.verifyOtp(phone, otpC.text);
    isLoading.value = false;

    if (res['error'] != null) {
      otpError.value = "Please enter the correct OTP";
      return;
    }

    // ✅ If we came from the Register flow, go to Registered Step 2
    if (isFromRegister) {
      if (Get.isRegistered<DriverRegisterController>()) {
        Get.find<DriverRegisterController>().isPhoneVerified.value = true;
        // Navigation is handled inside DriverRegisterController.goStep2() usually,
        // but here we want to advance directly.
        Get.offNamed(DriverRoutes.registerStep2);
      } else {
        Get.offNamed(DriverRoutes.registerStep1, arguments: {
          'phone': phone,
          'isPhoneVerified': true,
        });
      }
      return;
    }

    // Checking if registered
    if (res['isRegistered'] == false) {
      Get.offNamed(DriverRoutes.registerStep1, arguments: {'phone': phone});
    } else {
      final userData = res['user'] ?? res['driver'] ?? {};
      final token = res['token'];
      final status = userData['status'] ?? 'Pending';

      if (token != null) {
        await ApiService.saveToken(token, userData['_id'].toString());
        
        // Update FCM token after login — use the registered singleton
        if (Get.isRegistered<NotificationService>()) {
          await NotificationService.to.getTokenAndSave();
        }
        
        // ✅ FORCE fresh controllers for new session
        Get.delete<DriverHomeController>(force: true);
        Get.delete<DriverHistoryController>(force: true);
        Get.delete<DriverProfileController>(force: true);
        Get.delete<DriverFindingController>(force: true);
        Get.delete<DriverPackageController>(force: true);
        Get.delete<DriverWalletController>(force: true);
        
        if (Get.isRegistered<SocketService>()) {
          Get.delete<SocketService>(force: true);
        }
        Get.put(SocketService(), permanent: true); // Start socket for updates
      }

      // Navigate to Home for all registered users unless Suspended/Rejected
      if (status != 'Suspended' && status != 'Rejected') {
        await Future.delayed(const Duration(milliseconds: 100));
        Get.offAllNamed(DriverRoutes.home);
      } else {
        // Shown for specific restricted states
        Get.offAllNamed(DriverRoutes.verificationPending);
      }
    }
  }

  @override
  void onClose() {
    otpC.dispose();
    super.onClose();
  }
}

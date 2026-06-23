import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/socket_service.dart';
import '../../../services/api_service.dart';
import '../../routes/driver_routes.dart';

class VerificationController extends GetxController {
  final status = "Pending".obs;
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    checkStatus();
    _startPolling();
    
    // Listen for socket updates if socket service is ready
    if (Get.isRegistered<SocketService>()) {
      final socketService = Get.find<SocketService>();
      socketService.socket?.on('driver:status_changed', (data) {
        debugPrint("VerificationController: ⚡ Direct Socket Status Update: $data");
        if (data != null && data['status'] != null) {
          status.value = data['status'];
          _handleStatusChange();
        } else {
          checkStatus(); // Fallback to API check
        }
      });
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (status.value != 'Approved' && status.value != 'Active') {
        checkStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> checkStatus() async {
    try {
      final profile = await ApiService.getDriverProfile();
      if (profile != null && profile['error'] == null) {
        final newStatus = profile['status'] ?? 'Pending';
        if (status.value != newStatus) {
            status.value = newStatus;
            _handleStatusChange();
        }
      }
    } catch (e) {
      debugPrint("VerificationController: Error checking status: $e");
    }
  }

  void _handleStatusChange() {
    debugPrint("VerificationController: 🔍 Handling Status Change: ${status.value}");
    if (status.value == 'Approved' || status.value == 'Active') {
       _pollingTimer?.cancel();
       if (Get.currentRoute == DriverRoutes.verificationPending) {
         Get.offNamed(DriverRoutes.verificationApproved);
       } else {
         // Even if route changed, we should probably redirect if they are still "pending" contextually
         Get.offAllNamed(DriverRoutes.verificationApproved);
       }
    }
  }

  void goHome() {
    Get.offAllNamed(DriverRoutes.home);
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }
}

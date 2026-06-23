import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/package_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/payment_service.dart';

class PackagesController extends GetxController {
  final type = PackageType.hourly.obs;
  final packages = <Package>[].obs;
  final isLoading = true.obs;
  final isBuying = false.obs;
  final fromBooking = false.obs;
  final selectedDuration = "".obs; // e.g. "2 Hour"
  final _paymentService = PaymentService();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['fromBooking'] == true) {
      fromBooking.value = true;
    }
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    isLoading.value = true;
    try {
      final data = await ApiService.getPackages();
      packages.value = data.map((e) => Package.fromJson(e)).where((p) => p.status == 'Active').toList();
      
      // Select first available duration if not set
      if (packages.isNotEmpty) {
        final hourly = packages.where((p) => p.type == 'Hourly').toList();
        if (hourly.isNotEmpty) {
          selectedDuration.value = hourly.first.duration;
        } else {
          selectedDuration.value = packages.first.duration;
        }
      }
    } catch (e) {
      print("Error fetching packages: $e");
    } finally {
      isLoading.value = false;
    }
  }

  String formatDuration(String duration) {
    if (duration.isEmpty) return "";
    // If it's already got "Hour" or letters, just return it
    if (duration.contains(RegExp(r'[a-zA-Z]'))) return duration;
    return "$duration Hour";
  }

  void setType(PackageType t) {
    type.value = t;
    // Update selected duration for the new type
    final filtered = packages.where((p) => p.type == (t == PackageType.hourly ? 'Hourly' : 'Outstation')).toList();
    if (filtered.isNotEmpty) {
      selectedDuration.value = filtered.first.duration;
    } else {
      selectedDuration.value = "";
    }
  }

  void setDuration(String d) => selectedDuration.value = d;

  List<String> get availableDurations {
    final t = type.value == PackageType.hourly ? 'Hourly' : 'Outstation';
    return packages
        .where((p) => p.type == t)
        .map((p) => p.duration)
        .toSet()
        .toList();
  }

  List<String> get formattedDurations {
    return availableDurations.map((d) => formatDuration(d)).toList();
  }

  Package? get currentPackage {
    final t = type.value == PackageType.hourly ? 'Hourly' : 'Outstation';
    return packages.firstWhereOrNull(
      (p) => p.type == t && p.duration == selectedDuration.value,
    );
  }

  List<PackageDetailRow> get currentRows {
    final pkg = currentPackage;
    if (pkg == null) return [];

    if (type.value == PackageType.hourly) {
      return [
        PackageDetailRow(formatDuration(pkg.duration).toLowerCase(), "₹ ${pkg.basePrice.toInt()}/-"),
        PackageDetailRow("Per hour overtime", "₹ ${pkg.overtimeCharge.toInt()}/-"),
        PackageDetailRow("Price between 12 AM to 6 AM", "₹ ${pkg.nightCharge.toInt()}/-"),
        PackageDetailRow("Drop location change charge", "₹ ${pkg.locationChangeCharge.toInt()}/-"),
      ];
    }

    return [
      PackageDetailRow(formatDuration(pkg.duration).toLowerCase(), "₹ ${pkg.basePrice.toInt()}/-"),
      PackageDetailRow("Per hour overtime", "₹ ${pkg.overtimeCharge.toInt()}/-"),
      PackageDetailRow("Drop location change charge", "₹ ${pkg.locationChangeCharge.toInt()}/-"),
    ];
  }

  Future<void> buyCurrentPackage() async {
    final pkg = currentPackage;
    if (pkg == null) return;
    if (isBuying.value) return;

    isBuying.value = true;
    try {
      final customerId = await ApiService.getCustomerId();
      if (customerId == null) {
        return;
      }

      final profile = await ApiService.getCustomerProfile(customerId);
      if (profile.containsKey('error')) {
        return;
      }

      final String phone = profile['phone'] ?? "";
      final String email = profile['email'] ?? "";

      await _paymentService.startPayment(
        amount: pkg.basePrice,
        description: "Buying ${pkg.name} - ${formatDuration(pkg.duration)}",
        userPhone: phone,
        userEmail: email,
        onSuccess: (paymentId) async {
          Get.dialog(
            const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A00))),
            barrierDismissible: false,
          );

          final res = await ApiService.buyPackage(
            packageId: pkg.id,
            packageName: pkg.name,
            packageType: pkg.type,
            duration: formatDuration(pkg.duration),
            amount: pkg.basePrice,
            paymentId: paymentId,
          );

          Get.back(); // close loading

          if (res.containsKey('error')) {
            // Failure handled by FCM
          } else {
            // 5. Instant redirection for booking-triggered purchases
            final bool isFromBooking = fromBooking.value == true || (Get.arguments is Map && Get.arguments['fromBooking'] == true);
            
            if (isFromBooking) {
              // Forced redirection: immediate return to booking page WITHOUT delay or snackbar blocking
              Future.microtask(() {
                // Return success result to trigger auto-complete in booking page
                Get.back(result: true); 
                fromBooking.value = false; // Reset state
              });
            } else {
              // Standard feedback for normal standalone purchases
            }
          }
        },
        onFailure: (error) {
          // Failure handled by FCM
        },
      );
    } catch (e) {
      // Failure handled by FCM
    } finally {
      isBuying.value = false;
    }
  }

  @override
  void onClose() {
    _paymentService.dispose();
    super.onClose();
  }
}
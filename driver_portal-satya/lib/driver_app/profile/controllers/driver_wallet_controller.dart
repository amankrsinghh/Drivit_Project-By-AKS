import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../controllers/driver_profile_controller.dart';
import '../../../services/payment_service.dart';
import '../../home/controllers/driver_home_controller.dart';

/// Simple model for a wallet history entry
class WalletHistoryItem {
  final String title;
  final DateTime time;
  final double amount;
  final bool isCredit;

  const WalletHistoryItem({
    required this.title,
    required this.time,
    required this.amount,
    this.isCredit = true,
  });
}

class DriverWalletController extends GetxController {
  final balance = 0.0.obs;
  final isLoading = false.obs;
  late final PaymentService _paymentService;

  // Typed history list — exposed as `history` so the view works unchanged
  final history = <WalletHistoryItem>[].obs;
  final isWalletActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    _paymentService = PaymentService();
    _loadFromProfile();
    fetchEarnings();
  }

  @override
  void onClose() {
    _paymentService.dispose();
    super.onClose();
  }

  void _loadFromProfile() {
    try {
      final profileCtrl = Get.find<DriverProfileController>();
      balance.value = profileCtrl.walletBalance.value;
      isWalletActive.value = profileCtrl.isWalletActive.value;
    } catch (_) {}
  }

  Future<void> fetchEarnings() async {
    isLoading.value = true;
    try {
      final profile = await ApiService.getDriverProfile();
      if (profile != null && !profile.containsKey('error')) {
        balance.value = (profile['walletBalance'] ?? 0.0).toDouble();
        isWalletActive.value = profile['isWalletActive'] ?? false;

        if (profile['transactions'] != null) {
          final txs = (profile['transactions'] as List<dynamic>)
              .where((t) => t['title'] == 'Wallet Recharge')
              .toList();
          final items = txs.map<WalletHistoryItem>((t) {
            DateTime txDate;
            try {
              txDate = DateTime.parse(t['createdAt'].toString()).toLocal();
            } catch (_) {
              txDate = DateTime.now();
            }
            return WalletHistoryItem(
              title: t['title'] ?? 'Wallet Update',
              time: txDate,
              amount: (t['amount'] ?? 0).toDouble(),
              isCredit: t['type'] != 'debit',
            );
          }).toList();
          items.sort((a, b) => b.time.compareTo(a.time));
          history.value = items;
        }
      }
    } catch (e) {
      _loadFromProfile();
    } finally {
      isLoading.value = false;
    }
  }

  /// Format a DateTime for display (used by the wallet view)
  String formatTime(DateTime time) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '${time.day} ${months[time.month - 1]} ${time.year}  •  $hour:$minute $ampm';
  }

  /// Add money to wallet via Razorpay
  Future<void> addMoney(double amount) async {
    final profileCtrl = Get.find<DriverProfileController>();
    final phone = profileCtrl.phone.value;
    final email = profileCtrl.email.value;

    if (amount < 100) {
      return;
    }

    isLoading.value = true;
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
        description: 'Wallet Recharge - Rs $amount',
        userPhone: phone,
        userEmail: email,
        onSuccess: (paymentId) async {
          // onSuccess is called after payment returns
          final res = await ApiService.rechargeWallet(amount);
          if (!res.containsKey('error')) {
            // Instantly update UI balances locally for snappy UX
            balance.value += amount;
            if (Get.isRegistered<DriverProfileController>()) {
              Get.find<DriverProfileController>().walletBalance.value += amount;
            }
            if (Get.isRegistered<DriverHomeController>()) {
              Get.find<DriverHomeController>().walletBalance.value += amount;
            }

            // Fetch latest synced data from server in background
            fetchEarnings(); 
            if (Get.isRegistered<DriverProfileController>()) {
              Get.find<DriverProfileController>().fetchProfile();
            }
            if (Get.isRegistered<DriverHomeController>()) {
              Get.find<DriverHomeController>().fetchStats();
            }
            Get.back(); // back to wallet page after success
          }
          isLoading.value = false;
        },
        onFailure: (error) {
          if (Get.isDialogOpen == true) Get.back(); // Hide on error
          isLoading.value = false;
        },
        onOpened: () {
          // ✅ Hide loading as soon as Razorpay loads
          if (Get.isDialogOpen == true) Get.back();
        },
      );
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      isLoading.value = false;
    }
  }
}

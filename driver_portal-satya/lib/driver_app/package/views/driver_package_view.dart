import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/driver_package_controller.dart';
import '../../theme/driver_colors.dart';

class DriverPackageView extends GetView<DriverPackageController> {
  const DriverPackageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Subscription Packages",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.fetchPackages();
          controller.fetchCurrentPackage();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final activePack = controller.currentPackage.value;
            final hasActive = activePack != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasActive) ...[
                  _buildCurrentSubscription(),
                ] else ...[
                  const Text(
                    "Available Packages",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  _buildPackageList(),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentSubscription() {
    return Obx(() {
      final activePack = controller.currentPackage.value;
      if (activePack == null) return const SizedBox.shrink();

      final status = activePack['status'] ?? 'Active';
      final isSuspended = status == 'Suspended';
      final expiryDate = activePack['expiryDate'] != null ? DateTime.parse(activePack['expiryDate']).toLocal() : null;
      final startDate = activePack['createdAt'] != null ? DateTime.parse(activePack['createdAt']).toLocal() : null;
      final duration = activePack['packageId']?['durationMonths'] ?? 'N/A';

      return Column(
        children: [
          // Header Card (Style from MyPackageDetailsView)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSuspended ? [Colors.red.shade400, Colors.red.shade700] : [DriverColors.primary, const Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isSuspended ? Colors.red : DriverColors.primary).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                    const Icon(Icons.verified_user, color: Colors.white70, size: 24),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  activePack['packageId']?['name'] ?? 'Subscription Package',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                if (startDate != null)
                  Text(
                    "Member Since: ${DateFormat('dd MMM yyyy').format(startDate)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Details Card
          _buildCard(
            title: "Package Information",
            children: [
              _buildDetailRow(Icons.timer_outlined, "Duration", "$duration Month${duration is int && duration > 1 ? 's' : ''}"),
              if (startDate != null)
                _buildDetailRow(Icons.calendar_month, "Start Date", DateFormat('dd MMM yyyy').format(startDate)),
              _buildDetailRow(Icons.event_note, "Expiry Date", expiryDate != null ? DateFormat('dd MMM yyyy, hh:mm a').format(expiryDate) : 'N/A'),
              _buildDetailRow(Icons.wallet, "Wallet Credit", "₹${activePack['walletCredit'] ?? 0}"),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Transaction Card
          _buildCard(
            title: "Transaction Details",
            children: [
              _buildDetailRow(Icons.payment, "Payment ID", activePack['paymentId'] ?? 'N/A', copyable: true),
              _buildDetailRow(Icons.currency_rupee, "Amount Paid", "₹${activePack['amount'] ?? 0}"),
              _buildDetailRow(Icons.check_circle_outline, "Payment Status", activePack['paymentStatus'] ?? 'Completed'),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DriverColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: DriverColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                    if (copyable && value != 'N/A')
                      IconButton(
                        onPressed: () {
                          // Copy functionality - snackbar removed
                        },
                        icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Colors.orange),
        ));
      }

      if (controller.packages.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text("No packages available.", style: TextStyle(color: Colors.grey)),
        ));
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.packages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final pkg = controller.packages[index];
          return _buildPackageCard(pkg);
        },
      );
    });
  }

  Widget _buildPackageCard(dynamic pkg) {
    return Obx(() {
      final isPurchased = controller.currentPackage.value?['packageId']?['_id'] == pkg['_id'];
      
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: (isPurchased ? Colors.green : DriverColors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPurchased ? Icons.check_circle_outline : Icons.shield_outlined,
                      color: isPurchased ? Colors.green : DriverColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pkg['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Duration: ${pkg['durationMonths']} Month${pkg['durationMonths'] > 1 ? 's' : ''}",
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet, color: Colors.green, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "+₹${pkg['walletCredit']}",
                                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("Wallet Credit", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${pkg['cost']}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isPurchased ? Colors.green : DriverColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: isPurchased
                  ? null
                  : () {
                      Get.defaultDialog(
                        title: "Purchase Package",
                        middleText: "Are you sure you want to buy the ${pkg['name']} for ₹${pkg['cost']}?",
                        textCancel: "Cancel",
                        textConfirm: "Buy Now",
                        confirmTextColor: Colors.white,
                        buttonColor: DriverColors.primary,
                        onConfirm: () {
                          Get.back();
                          controller.buyPackage(pkg);
                        },
                      );
                    },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isPurchased ? Colors.green.withValues(alpha: 0.08) : DriverColors.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    isPurchased ? "PURCHASED" : "BUY PACKAGE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPurchased ? Colors.green : DriverColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

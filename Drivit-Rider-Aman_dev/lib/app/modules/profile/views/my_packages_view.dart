import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_packages_controller.dart';
import 'package:intl/intl.dart';

class MyPackagesView extends StatelessWidget {
  const MyPackagesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyPackagesController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("My Packages", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (controller.packages.isEmpty) {
            return _buildEmptyState();
          }

          final active = controller.packages.where((p) => !controller.isExpired(p)).toList();
          final history = controller.packages.where((p) => controller.isExpired(p)).toList();

          return TabBarView(
            children: [
              _buildPackageList(active),
              _buildPackageList(history),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No packages found", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPackageList(List<dynamic> list) {
    if (list.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        final expired = Get.find<MyPackagesController>().isExpired(p);
        final createdAtRaw = p['bookingDate'] ?? p['createdAt'];
        final expiryRaw = p['expiresAt'];

        final DateTime? createdAt = createdAtRaw != null ? DateTime.parse(createdAtRaw.toString()).toLocal() : null;
        final DateTime? expiry = expiryRaw != null ? DateTime.parse(expiryRaw.toString()).toLocal() : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    p['packageName'] ?? "Package",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: expired ? Colors.grey[100] : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      expired ? "EXPIRED" : "ACTIVE",
                      style: TextStyle(
                        color: expired ? Colors.grey : Colors.green[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${p['packageType']} • ${p['duration']}",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("PURCHASED", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        createdAt != null 
                          ? DateFormat('dd MMM, HH:mm').format(createdAt)
                          : "N/A",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(expired ? "EXPIRED ON" : "EXPIRES ON", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        expiry != null 
                          ? DateFormat('dd MMM, HH:mm').format(expiry)
                          : "N/A",
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 13,
                          color: expired ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (p['paymentId'] != null) ...[
                const SizedBox(height: 16),
                Text(
                  "TXN ID: ${p['paymentId']}",
                  style: TextStyle(color: Colors.grey[400], fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

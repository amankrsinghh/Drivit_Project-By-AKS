import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tariffs_controller.dart';

class TariffsView extends GetView<TariffsController> {
  const TariffsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            "Tariffs & Fares",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: "Standard"),
              Tab(text: "Hourly"),
              Tab(text: "Outstation"),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          return TabBarView(
            children: [
              _buildTripTypesList(),
              _buildPackageList(controller.hourlyPackages),
              _buildPackageList(controller.outstationPackages),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTripTypesList() {
    if (controller.tripTypes.isEmpty) {
      return const Center(child: Text("No standard trip types available."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.tripTypes.length,
      itemBuilder: (context, index) {
        final trip = controller.tripTypes[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip['name'] ?? 'Trip',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  trip['description'] ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Price per hour:", style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      "₹${trip['pricePerHour'] ?? 0}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPackageList(List<dynamic> packages) {
    if (packages.isEmpty) {
      return const Center(child: Text("No packages available."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDuration(pkg['duration'] ?? ''),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (pkg['name'] != null && pkg['name'].isNotEmpty)
                            Text(
                              pkg['name'],
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      "₹${pkg['basePrice'] ?? 0}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildChargeRow("Overtime Charge", "₹${pkg['overtimeCharge'] ?? 0} / hr"),
                const SizedBox(height: 8),
                _buildChargeRow("Night Charge", "₹${pkg['nightCharge'] ?? 0}"),
                if (pkg['type'] == 'Outstation') ...[
                  const SizedBox(height: 8),
                  _buildChargeRow("Location Change", "₹${pkg['locationChangeCharge'] ?? 0}"),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChargeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade800)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDuration(String duration) {
    final trimmed = duration.trim();
    if (trimmed.isEmpty) return 'Package';
    final hours = int.tryParse(trimmed);
    if (hours != null) {
      return '$hours ${hours == 1 ? "Hour" : "Hours"}';
    }
    return trimmed;
  }
}

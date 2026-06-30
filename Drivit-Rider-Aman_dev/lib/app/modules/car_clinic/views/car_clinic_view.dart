import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/car_clinic_controller.dart';
import 'book_clinic_service_view.dart';

class CarClinicView extends StatefulWidget {
  const CarClinicView({super.key});

  @override
  State<CarClinicView> createState() => _CarClinicViewState();
}

class _CarClinicViewState extends State<CarClinicView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CarClinicController controller = Get.find<CarClinicController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: controller.activeTabIndex.value,
    );
    _tabController.addListener(() {
      controller.activeTabIndex.value = _tabController.index;
    });
    
    ever(controller.activeTabIndex, (int val) {
      if (mounted && _tabController.index != val) {
        _tabController.animateTo(val);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'build':
        return Icons.build_rounded;
      case 'build_circle':
        return Icons.build_circle_rounded;
      case 'time_to_leave':
        return Icons.time_to_leave_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'car_repair':
        return Icons.car_repair_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Assigned':
        return Colors.blue;
      case 'Ongoing':
        return Colors.indigo;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Car Clinic",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xffF38900),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xffF38900),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: "Services"),
            Tab(text: "My Bookings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServicesTab(),
          _buildBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return Obx(() {
      if (controller.isLoadingServices.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xffF38900)));
      }
      if (controller.services.isEmpty) {
        return const Center(child: Text("No services available at this time."));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.services.length,
        itemBuilder: (context, index) {
          final service = controller.services[index];
          final price = service['basePrice'] ?? 0;
          final name = service['name'] ?? '';
          final desc = service['description'] ?? '';
          final icon = _getIcon(service['iconName']?.toString());

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF7EE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xffF38900), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          Text(
                            "₹$price",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xffF38900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.selectService(service);
                            Get.to(() => const BookClinicServiceView());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffF38900),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text(
                            "Book Now",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBookingsTab() {
    return Obx(() {
      if (controller.isLoadingBookings.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xffF38900)));
      }
      if (controller.bookings.isEmpty) {
        return const Center(child: Text("You have no clinic bookings."));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.bookings.length,
        itemBuilder: (context, index) {
          final booking = controller.bookings[index];
          final bookingId = booking['bookingId'] ?? '';
          final serviceName = booking['serviceId']?['name'] ?? booking['serviceName'] ?? 'Service';
          final pickup = booking['pickupLocation'] ?? '';
          final date = DateTime.tryParse(booking['scheduledAt']?.toString() ?? '')?.toLocal();
          final fare = booking['fare'] ?? 0;
          final status = booking['status'] ?? 'Pending';
          final driverName = booking['driverId']?['name']?.toString();
          final driverPhone = booking['driverId']?['phone']?.toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bookingId,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xffF1F5F9)),
                Text(
                  serviceName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pickup,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (date != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        "${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.payment_rounded, color: Colors.grey, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      "Fare: ₹$fare",
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (driverName != null) ...[
                  const Divider(height: 20, color: Color(0xffF1F5F9)),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xffFFF7EE),
                        child: Icon(Icons.person, color: Color(0xffF38900), size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Assigned: $driverName ($driverPhone)",
                        style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                if (status == 'Pending' || status == 'Assigned') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Get.defaultDialog(
                            title: "Cancel Booking",
                            middleText: "Are you sure you want to cancel this clinic booking?",
                            textCancel: "No",
                            textConfirm: "Yes, Cancel",
                            confirmTextColor: Colors.white,
                            buttonColor: Colors.red,
                            onConfirm: () {
                              Get.back();
                              controller.cancelClinicJob(booking['_id']);
                            },
                          );
                        },
                        child: const Text("Cancel Booking", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          );
        },
      );
    });
  }
}

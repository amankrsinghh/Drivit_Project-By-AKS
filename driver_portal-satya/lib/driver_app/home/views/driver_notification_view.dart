import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../theme/driver_colors.dart';
import '../controllers/driver_home_controller.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../routes/driver_routes.dart';

class DriverNotificationView extends StatefulWidget {
  const DriverNotificationView({super.key});

  @override
  State<DriverNotificationView> createState() => _DriverNotificationViewState();
}

class _DriverNotificationViewState extends State<DriverNotificationView> {
  late final DriverHomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DriverHomeController>();
    // Clear badge as soon as the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: DriverColors.primary,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => controller.notifications.isNotEmpty
              ? TextButton(
                  onPressed: () {
                    controller.clearNotifications();
                  },
                  child: const Text(
                    "Clear All",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  "No notifications yet",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            String timeStr = "";
            if (notification['time'] != null) {
              final dt = DateTime.tryParse(notification['time'].toString());
              if (dt != null) {
                timeStr = DateFormat("dd MMM, h:mm a").format(dt.toLocal());
              }
            }

            return Dismissible(
              key: Key(notification['time'].toString() + index.toString()),
              direction: DismissDirection.startToEnd,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                controller.removeNotification(index);
              },
              child: InkWell(
                onTap: () async {
                  Map<String, dynamic> payload = Map<String, dynamic>.from(notification);
                  if (notification['payload'] is Map) {
                    payload = Map<String, dynamic>.from(notification['payload'] as Map);
                  } else if (notification['data'] is Map) {
                    payload = Map<String, dynamic>.from(notification['data'] as Map);
                  }
                  
                  if (payload['payload'] is Map) {
                    payload = Map<String, dynamic>.from(payload['payload'] as Map);
                  } else if (payload['data'] is Map) {
                    payload = Map<String, dynamic>.from(payload['data'] as Map);
                  }

                  final type = payload['type'];
                    if (type == 'chat_message') {
                      Get.toNamed('/chat', arguments: {
                        'rideId': payload['rideId'],
                        'name': payload['senderName'],
                        'profileImage': payload['senderImage'],
                        'otherId': payload['senderId'],
                      });
                    } else if (type == 'new_ride') {
                      final rideId = payload['rideId']?.toString();
                      if (rideId != null && rideId.isNotEmpty) {
                        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                        try {
                          final res = await ApiService.getRide(rideId);
                          Get.back();
                          if (!res.containsKey('error')) {
                            final rideData = res['data'] ?? res;
                            final status = (rideData['status'] ?? '').toString().toLowerCase();

                            final profile = await ApiService.getCachedDriverProfile();
                            final driverTransmission = (profile?['transmissionType'] ?? 'Both').toString().toLowerCase();
                            final rideTransmission = (rideData['transmission'] ?? 'manual').toString().toLowerCase();
                            final bool isAllowed = driverTransmission == 'both' || driverTransmission == rideTransmission;

                            if (isAllowed &&
                                (status == 'pending' ||
                                    status == 'upcoming' ||
                                    rideData['isScheduled'] == true ||
                                    rideData['isScheduled'] == 'true')) {
                              // ✅ Ride is still available — show accept dialog
                              if (Get.isRegistered<SocketService>()) {
                                Get.find<SocketService>().showRideRequestDialog(rideData, fromFcmClick: true);
                              }
                            } else {
                              // ✅ Ride was skipped/missed — show read-only trip details
                              Get.toNamed(
                                DriverRoutes.tripDetails,
                                arguments: rideData,
                              );
                            }
                          }
                        } catch (e) {
                          if (Get.isDialogOpen ?? false) Get.back();
                        }
                      }
                    } else if (payload['rideId'] != null || payload['trip_id'] != null) {
                      // Generic ride-related notification — navigate to trip details
                      final rideId = payload['rideId'] ?? payload['trip_id'];
                      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                      try {
                        final res = await ApiService.getRide(rideId);
                        Get.back();
                        if (!res.containsKey('error')) {
                          final rideData = res['data'] ?? res;
                          Get.toNamed(DriverRoutes.tripDetails, arguments: rideData);
                        }
                      } catch (e) {
                        if (Get.isDialogOpen ?? false) Get.back();
                      }
                    }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DriverColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: DriverColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    notification['title'] ?? 'Notification',
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification['body'] ?? '',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

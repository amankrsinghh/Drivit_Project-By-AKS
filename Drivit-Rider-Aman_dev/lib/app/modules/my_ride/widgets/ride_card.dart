

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ride_items.dart';
import '../views/my_ride_detail_view.dart';
import '../../../core/services/api_service.dart';

class RideCard extends StatelessWidget {
  final RideItem item;
  const RideCard({super.key, required this.item});

  Color get statusColor {
    switch (item.status) {
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
        return Colors.red;
      case RideStatus.upcoming:
        return Colors.orange;
      case RideStatus.expired:
        return Colors.grey;
      case RideStatus.unassigned:
        return Colors.red;
    }
  }

  String get statusText {
    switch (item.status) {
      case RideStatus.completed:
        return "Completed";
      case RideStatus.cancelled:
        return "Canceled"; // image me "Canceled"
      case RideStatus.upcoming:
        return "Upcoming";
      case RideStatus.expired:
        return "Expired";
      case RideStatus.unassigned:
        return "Unassigned";
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => MyRideDetailView(item: item)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Date and Price
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${item.dateText}  •  ${item.timeText}",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
                Text(
                  "₹ ${item.amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup Address
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF38900), // Primary orange
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.tripStartAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dropoff Address (Added for consistency)
            Row(
              children: [
                const Icon(Icons.location_on, size: 10, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.tripEndAddress,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Driver and Status
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.driverProfileImage != null && item.driverProfileImage!.isNotEmpty
                      ? Image.network(
                          ApiService.getImageUrl(item.driverProfileImage),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Image.asset("assets/images/user.png", fit: BoxFit.cover),
                        )
                      : Image.asset("assets/images/user.png", fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.driverName,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
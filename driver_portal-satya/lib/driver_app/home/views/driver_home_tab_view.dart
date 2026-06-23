import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../services/api_service.dart';
import '../../theme/driver_colors.dart';
import '../../routes/driver_routes.dart';
import '../controllers/driver_home_controller.dart';
import '../../history/models/driver_trip_history_model.dart';

class DriverHomeTabView extends GetView<DriverHomeController> {
  const DriverHomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // FIXED TOP BAR
        Container(
          color: DriverColors.primary,
          height: topPad + 64,
          padding: EdgeInsets.only(top: topPad, left: 14, right: 14),
          child: Row(
            children: [
              Obx(
                () => InkWell(
                  onTap: () => controller.setIndex(4),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: controller.profileImageUrl.value.isNotEmpty
                          ? Image.network(
                              ApiService.getImageUrl(controller.profileImageUrl.value),
                              fit: BoxFit.cover,
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                    "assets/images/user.png",
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                  ),
                            )
                          : Image.asset(
                              "assets/images/user.png",
                              fit: BoxFit.cover,
                            ),
                    ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "Dashboard",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Obx(
                () => InkWell(
                  onTap: () {
                    Get.toNamed(DriverRoutes.notifications);
                  },
                  child: Stack(
                    children: [
                      _circleIcon(Icons.notifications),
                      if (controller.unreadNotificationsCount.value > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              controller.unreadNotificationsCount.value > 9
                                  ? '9+'
                                  : '${controller.unreadNotificationsCount.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // MAIN CONTENT AREA
        Expanded(
          child: Stack(
            children: [
              // SCROLLABLE CONTENT
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 180),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      
    
                          // BALANCE CARD
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF7ED),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Color(0xFFF97316),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Obx(
                                        () => Text(
                                          "₹ ${controller.walletBalance.value.toStringAsFixed(0)}",
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Available Balance",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Obx(() => InkWell(
                                    onTap: () {
                                      if (controller.isWalletActive.value) {
                                        Get.toNamed(DriverRoutes.addAmount);
                                      } else {
                                        controller.setIndex(1); // Redirect to Package tab
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: controller.isWalletActive.value 
                                            ? DriverColors.primary 
                                            : Colors.grey,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        "Recharge Now",
                                        style: GoogleFonts.inter(
                                          color: controller.isWalletActive.value 
                                            ? DriverColors.primary 
                                            : Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // STATS GRID
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              children: [
                                Obx(
                                  () => Row(
                                    children: [
                                      Expanded(
                                        child: _StatCard(
                                          icon: Icons.attach_money,
                                          iconBg: const Color(0xFFE9FBEF),
                                          iconColor: const Color(0xFF2DBE60),
                                          title: "Today Earning",
                                          value:
                                              "₹ ${controller.todayEarning.value.toStringAsFixed(0)}",
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _StatCard(
                                          icon: Icons.auto_graph,
                                          iconBg: const Color(0xFFEFF1FF),
                                          iconColor: const Color(0xFF5A6BFF),
                                          title: "This Week",
                                          value:
                                              "₹ ${controller.weekEarning.value.toStringAsFixed(0)}",
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _StatCard(
                                          icon: Icons.trending_up,
                                          iconBg: const Color(0xFFFFEFEF),
                                          iconColor: const Color(0xFFE35757),
                                          title: "Monthly",
                                          value:
                                              "₹ ${controller.monthEarning.value.toStringAsFixed(0)}",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Obx(
                                        () => _StatCard(
                                          icon: Icons.account_balance_wallet,
                                          iconBg: const Color(0xFFEAF6FF),
                                          iconColor: const Color(0xFF2AA7FF),
                                          title: "Last Recharge",
                                          value:
                                              "₹ ${controller.totalRecharge.value.toStringAsFixed(0)}",
                                          isHorizontal: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // TRIP HISTORY HEADER
                          Row(
                            children: [
                              Text(
                                "Trip History",
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => controller.setIndex(3),
                                child: Text(
                                  "see all",
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: DriverColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // TRIP HISTORY LIST
                          Obx(() {
                            if (controller.recentRides.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    "No trips yet",
                                    style: GoogleFonts.inter(
                                      color: Colors.black45,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: controller.recentRides
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final i = entry.key;
                                      final d = entry.value;

                                      String title = "Trip";
                                      if (d['pickupLocation'] != null &&
                                          d['dropoffLocation'] != null) {
                                        final p = d['pickupLocation']
                                            .toString()
                                            .split(',')[0];
                                        final dp = d['dropoffLocation']
                                            .toString()
                                            .split(',')[0];
                                        title = "$p  →  $dp";
                                      }

                                      String sub = "";
                                      if (d['createdAt'] != null) {
                                        final dt = DateTime.tryParse(d['createdAt'].toString());
                                        if (dt != null) {
                                          sub = DateFormat("EEE, dd MMM  •  h:mm a").format(dt.toLocal());
                                        }
                                      }

                                      final amount = "₹ ${d['fare'] ?? '0'}";
                                      return Column(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Get.toNamed(
                                                DriverRoutes.tripDetails,
                                                arguments: DriverTripHistoryModel.fromApi(d),
                                              );
                                            },
                                            borderRadius: i == 0
                                                ? const BorderRadius.vertical(top: Radius.circular(16))
                                                : i == controller.recentRides.length - 1
                                                    ? const BorderRadius.vertical(bottom: Radius.circular(16))
                                                    : null,
                                            child: _TripTile(
                                              title: title,
                                              sub: sub,
                                              amount: amount,
                                            ),
                                          ),
                                          if (i <
                                              controller.recentRides.length - 1)
                                            const Divider(height: 1),
                                        ],
                                      );
                                    })
                                    .toList(),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // FIXED CURRENT STATUS CARD AT BOTTOM
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Obx(() {
                  final online = controller.isOnline.value;
                  final bg = online
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF3B30);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            online ? Icons.wifi : Icons.wifi_off,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Status",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                online ? "Online" : "Offline",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: online,
                          onChanged: controller.toggleOnline,
                          activeThumbColor: Colors.white,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          activeTrackColor: Colors.white24,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _circleIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: DriverColors.primary, size: 24),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final bool isHorizontal;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  final String title;
  final String sub;
  final String amount;

  const _TripTile({
    required this.title,
    required this.sub,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

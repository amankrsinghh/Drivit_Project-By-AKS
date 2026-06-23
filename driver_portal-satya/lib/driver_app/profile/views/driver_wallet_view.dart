import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../routes/driver_routes.dart';
import '../../theme/driver_colors.dart';
import '../controllers/driver_wallet_controller.dart';
import '../../home/controllers/driver_home_controller.dart';

class DriverWalletView extends GetView<DriverWalletController> {
  const DriverWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: DriverColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _orangeHeader(top, "My Wallet"),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: DriverColors.primary,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Obx(() {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹${controller.balance.value.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Minimum Recharge ₹200",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                        Obx(() => OutlinedButton(
                          onPressed: () {
                             if (controller.isWalletActive.value) {
                               Get.toNamed(DriverRoutes.addAmount);
                             } else {
                               if (Get.isRegistered<DriverHomeController>()) {
                                 Get.find<DriverHomeController>().setIndex(1);
                               }
                             }
                           },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: controller.isWalletActive.value 
                                ? DriverColors.primary 
                                : Colors.grey
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            "Add Amount",
                            style: TextStyle(
                              color: controller.isWalletActive.value 
                                ? DriverColors.primary 
                                : Colors.grey,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        )),
                      ],
                    ),

                    const SizedBox(height: 26),

                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Recharge History",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Text(
                          "see all",
                          style: TextStyle(
                            color: DriverColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ✅ Dynamic history
                    Obx(() {
                      if (controller.history.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            "No recharges yet",
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: controller.history.map((h) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF3E6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.north_east,
                                    size: 15,
                                    color: DriverColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Recharge",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        controller.formatTime(h.time),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "₹${h.amount}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orangeHeader(double top, String title) {
    return Container(
      color: DriverColors.primary,
      padding: EdgeInsets.only(top: top),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 12),
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(99),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 30),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22, // ✅ was 14
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

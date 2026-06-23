import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../../routes/driver_routes.dart';
import '../../theme/driver_colors.dart';
import '../controllers/driver_profile_controller.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../widgets/driver_logout_dialog.dart';

class DriverProfileView extends GetView<DriverProfileController> {
  const DriverProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: DriverColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Column(
        children: [
          // orange header
          Container(
            color: DriverColors.primary,
            padding: EdgeInsets.only(top: top),
            child: const SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  "Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Center(
                      child: InkWell(
                        onTap: () {
                          if (controller.profileImage.value.isNotEmpty) {
                            _showImagePreview(context, controller.profileImage.value);
                          }
                        },
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5E5E5),
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: controller.profileImage.value.isNotEmpty
                              ? Image.network(
                                  ApiService.getImageUrl(controller.profileImage.value),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => Image.asset(
                                    "assets/images/user.png",
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  "assets/images/user.png",
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        controller.name.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    Obx(() => controller.displayId.value.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Center(
                              child: Text(
                                controller.displayId.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: DriverColors.primary,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          controller.avgRating.value.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${controller.expYear.value} Years Exp",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Clickable Edit Profile
                    Center(
                      child: InkWell(
                        onTap: () => Get.toNamed(DriverRoutes.editProfile),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF999999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Wallet Balance Card
                    // Container(
                    //   margin: const EdgeInsets.symmetric(horizontal: 10),
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(16),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.black.withValues(alpha: 0.05),
                    //         blurRadius: 15,
                    //         offset: const Offset(0, 5),
                    //       ),
                    //     ],
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Container(
                    //         width: 48,
                    //         height: 48,
                    //         decoration: const BoxDecoration(
                    //           color: Color(0xFFFFF7ED),
                    //           shape: BoxShape.circle,
                    //         ),
                    //         child: const Icon(
                    //           Icons.account_balance_wallet,
                    //           color: Color(0xFFF97316),
                    //           size: 24,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 14),
                    //       Expanded(
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             const Text(
                    //               "Wallet Balance",
                    //               style: TextStyle(
                    //                 fontSize: 14,
                    //                 color: Colors.grey,
                    //                 fontWeight: FontWeight.w500,
                    //               ),
                    //             ),
                    //             const SizedBox(height: 4),
                    //             Obx(() => Text(
                    //               "₹ ${controller.walletBalance.value.toStringAsFixed(0)}",
                    //               style: const TextStyle(
                    //                 fontSize: 22,
                    //                 fontWeight: FontWeight.w800,
                    //                 color: Colors.black,
                    //               ),
                    //             )),
                    //           ],
                    //         ),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () => Get.toNamed(DriverRoutes.addAmount),
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: DriverColors.primary,
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(8),
                    //           ),
                    //           padding: const EdgeInsets.symmetric(horizontal: 16),
                    //         ),
                    //         child: const Text(
                    //           "Recharge",
                    //           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 18),

                    _menuTile(
                      icon: Icons.account_balance_wallet,
                      title: "My Wallet",
                      onTap: () {
                        if (controller.isWalletActive.value) {
                          Get.toNamed(DriverRoutes.wallet);
                        } else {
                          Get.defaultDialog(
                            title: "Package Required",
                            middleText: "Please buy a package to access wallet and start accepting rides.",
                            textCancel: "Cancel",
                            textConfirm: "Buy Package",
                            confirmTextColor: Colors.white,
                            buttonColor: DriverColors.primary,
                            onConfirm: () {
                              Get.back();
                              // We need to navigate to the Package tab in the Home controller
                              // If HomeTabView is the main scaffold, we can use the controller
                              if (Get.isRegistered<DriverHomeController>()) {
                                Get.find<DriverHomeController>().setIndex(1);
                              }
                            },
                          );
                        }
                      },
                    ),

                    _menuTile(
                      icon: Icons.info,
                      title: "About Us",
                      onTap: () => Get.toNamed(DriverRoutes.aboutUs),
                    ),
                    _menuTile(
                      icon: Icons.call,
                      title: "Contact Us",
                      onTap: () => Get.toNamed(DriverRoutes.contactUs),
                    ),
                    _menuTile(
                      icon: Icons.privacy_tip,
                      title: "Privacy Policy",
                      onTap: () => Get.toNamed(DriverRoutes.privacy),
                    ),
                    _menuTile(
                      icon: Icons.star,
                      title: "Rate us & Feedback",
                      onTap: () => Get.toNamed(DriverRoutes.rateUs),
                    ),
                    _menuTile(
                      icon: Icons.logout,
                      title: "Logout",
                      onTap: () {
                        DriverLogoutDialog.show(onLogout: controller.logout);
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: Get.width * 0.8,
                height: Get.width * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(
                    ApiService.getImageUrl(imageUrl),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionCurve: Curves.easeInOutBack,
    );
  }

  static Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 22, color: DriverColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

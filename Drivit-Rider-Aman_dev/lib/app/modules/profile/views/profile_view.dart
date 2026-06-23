
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../widgets/log_out_dialog.dart';
import '../widgets/profile_widget.dart';

import 'about_us_view.dart';
import 'contact_us_view.dart';
import 'edit_profile_view.dart';
import 'privacy_policy_view.dart';
import 'rate_us_view.dart';
import 'terms_conditions_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  ProfileController get controller => Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        children: [
          // Header / Top Area
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Profile",
              style: TextStyle(
                color: Colors.black,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Avatar Section
          Column(
            children: [
              // Avatar
              Obx(() {
                final path = controller.profileImagePath.value;
                final url = controller.profileImageUrl.value;
                return InkWell(
                  onTap: () {
                    if (path.isNotEmpty || url.isNotEmpty) {
                      _showImagePreview(context, path: path, url: url);
                    }
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: path.isNotEmpty
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : url.isNotEmpty
                              ? Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/user.png", fit: BoxFit.cover),
                                )
                              : Image.asset("assets/images/user.png", fit: BoxFit.cover),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              
              Obx(
                () => Text(
                  controller.name.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              ),
              Obx(() => controller.displayId.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Text(
                        controller.displayId.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF07E23),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
              const SizedBox(height: 6),

              // Rating Display
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          controller.avgRating.value > 0
                              ? controller.avgRating.value.toStringAsFixed(1)
                              : "No Ratings",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              
              // Edit Profile Link
              InkWell(
                onTap: () => Get.to(() => const EditProfileView()),
                child: const Text(
                  "Edit Profile",
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Menu Tiles
          ProfileMenuTile(
            icon: Icons.info_outline,
            title: "About Us",
            onTap: () => Get.to(() => const AboutUsView()),
          ),
          ProfileMenuTile(
            icon: Icons.call,
            title: "Contact Us",
            onTap: () => Get.to(() => const ContactUsView()),
          ),
          ProfileMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            onTap: () => Get.to(() => const PrivacyPolicyView()),
          ),
        
          ProfileMenuTile(
            icon: Icons.assignment,
            title: "Terms & Conditions",
            onTap: () => Get.to(() => const TermsConditionsView()),
          ),
          ProfileMenuTile(
            icon: Icons.star,
            title: "Rate Us & Feedback",
            onTap: () => Get.to(() => const RateUsView()),
          ),
          ProfileMenuTile(
            icon: Icons.logout,
            title: "Logout",
            onTap: () async {
              final result = await LogoutDialog.show();
              if (result == true) {
                controller.logout();
              }
            },
          ),
          const SizedBox(height: 120), // Extra space for bottom nav
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, {String? path, String? url}) {
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
                  child: path != null && path.isNotEmpty
                      ? Image.file(File(path), fit: BoxFit.cover)
                      : url != null && url.isNotEmpty
                          ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            )
                          : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.85),
    );
  }
}

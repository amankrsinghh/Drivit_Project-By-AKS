import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

import '../../my_ride/views/my_ride_view.dart';
import '../../profile/views/profile_view.dart';

import '../controllers/home_controller.dart';
import '../widgets/home_header.dart';
import '../../../widgets/bottom_nav/app_bottom_nav.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldExit = await controller.onWillPop();
        if (shouldExit) {
          // This case is handled by SystemNavigator.pop() inside onWillPop
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Obx(
              () => IndexedStack(
                index: controller.selectedIndex.value,
                children: const [
                  _HomeTab(), // tab 0
                  SafeArea(child: MyRideView()), // tab 1
                  SafeArea(child: ProfileView()), // tab 2
                ],
              ),
            ),
            // Floating active ride card
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Obx(() {
                final ride = controller.activeRideData.value;
                if (ride == null) return const SizedBox.shrink();
                
                final rideId = ride['_id']?.toString() ?? '';
                final status = ride['status']?.toString() ?? '';
                final bookingId = ride['booking_id']?.toString() ?? "";
                final String displayId = bookingId.isNotEmpty 
                    ? bookingId 
                    : "RID${(rideId.substring((rideId.length - 8).clamp(0, rideId.length))).toUpperCase()}";

                final isPending = status == 'Pending';

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, val, child) {
                    return Transform.scale(
                      scale: 0.95 + (0.05 * val),
                      child: Opacity(opacity: val, child: child),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800), // Vibrant premium orange (matching Driver app)
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Get.toNamed(
                              Routes.findingDriver,
                              arguments: {
                                'rideId': rideId,
                                'status': status,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_car, color: Colors.white, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isPending ? "Finding best driver..." : "Active Trip is Live",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        isPending 
                                            ? "Booking ID: $displayId • Tap to view" 
                                            : "Booking ID: $displayId • Tap to resume",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        bottomNavigationBar: const AppBottomNav(),
      ),
    );
  }
}

class _HomeTab extends GetView<HomeController> {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final RxInt promoIndex = 0.obs;
    final PageController promoPageController = PageController();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: Stack(
        children: [ 
          // Main Content
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                  child: const HomeHeader(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      _buildPromoCarousel(promoIndex, promoPageController),
                      const SizedBox(height: 30),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Professional & Highly Experienced Drivers",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Select a service to request a driver for your journey",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildServiceCard(
                            title: "Local",
                            subtitle: "Standard point-to-point drop-off",
                            icon: Icons.navigation_rounded,
                            iconColor: const Color(0xffF38900),
                            iconBgColor: const Color(0xffFFF3E0),
                            onTap: () => controller.navigateToSelectRide(
                              arguments: {'tripType': 'One Way'},
                            ),
                          ),
                          const SizedBox(width: 15),
                          _buildServiceCard(
                            title: "Outstation",
                            subtitle: "Travel beyond city limits with ease",
                            icon: Icons.map_rounded,
                            iconColor: const Color(0xff0288D1),
                            iconBgColor: const Color(0xffE1F5FE),
                            onTap: () => controller.navigateToSelectRide(
                              arguments: {'tripType': 'Outstation'},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Existing view tariffs & fares card preserved below the grid
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.tariffs),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xffF38900),
                                Color(0xffE07A00),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffF38900).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.request_quote_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "View Tariffs & Fares",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "View pricing for hourly, outstation & standard rides",
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCarousel(RxInt promoIndex, PageController pageController) {
    final List<Map<String, dynamic>> promos = [
      {
        'title': "Need a Driver?",
        'subtitle': "Book a professional driver for your personal car instantly.",
        'icon': Icons.drive_eta_rounded,
        'colors': [const Color(0xffF38900), const Color(0xffFFB24D)],
      },
      {
        'title': "Police Verified",
        'subtitle': "Thorough background and police verification for your complete safety.",
        'icon': Icons.verified_user_rounded,
        'colors': [const Color(0xff1E3C72), const Color(0xff2A5298)],
      },
      {
        'title': "Experienced Drivers",
        'subtitle': "Sit back and relax while our highly experienced drivers navigate traffic.",
        'icon': Icons.star_rounded,
        'colors': [const Color(0xff6C33A3), const Color(0xff8D4DE8)],
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 145,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: (index) => promoIndex.value = index,
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: promo['colors'] as List<Color>,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (promo['colors'] as List<Color>).first.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            promo['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            promo['subtitle'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        promo['icon'] as IconData,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                promos.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: promoIndex.value == index ? 16 : 6,
                  decoration: BoxDecoration(
                    color: promoIndex.value == index
                        ? const Color(0xffF38900)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffF3F4F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

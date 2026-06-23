import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/verification_controller.dart';

class VerificationPendingView extends GetView<VerificationController> {
  const VerificationPendingView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<VerificationController>()) {
      Get.put(VerificationController());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFBF5E9),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Top Title
              Text(
                "Verification",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              
              const Spacer(),
              
              // Stylized Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.0), // Invisible container for sizing
                    ),
                  ),
                  const Icon(
                    Icons.search_rounded,
                    size: 130,
                    color: Color(0xFFF97316), // Premium Orange
                  ),
                  // Small white highlight to mimic Figma shine
                  Positioned(
                    top: 35,
                    left: 45,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 60),
              
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Your profile is under verification. You can start taking trips once approved.",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.black,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/common_button.dart';
import '../../../../widgets/common_text.dart';
import '../../../../widgets/otp_boxes.dart';
import '../controllers/login_controller.dart';

class OtpView extends GetView<LoginController> {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 16),
                
                Center(
                  child: Image.asset(
                    "assets/images/car1.png",
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.directions_car, size: 100, color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                CommonText(
                  text: "Enter OTP",
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CommonText(
                  text: "We've sent a code to your registered mobile no",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                /// OTP Boxes
                CommonOtpBoxes(
                  length: 6,
                  controller: controller.otpController,
                  onCompleted: (v) {
                    controller.otpError.value = "";
                    controller.verifyOtp();
                  },
                  onChanged: (v) {
                    if (controller.otpError.value.isNotEmpty) {
                      controller.otpError.value = "";
                    }
                  },
                ),
                
                Obx(() => controller.otpError.value.isNotEmpty 
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: Text(
                          controller.otpError.value,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()
                ),

                const SizedBox(height: 24),
                Center(
                  child: Obx(() => GestureDetector(
                    onTap: controller.isLoading.value || controller.otpTimer.value > 0 
                        ? null 
                        : controller.resendOtp,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Didn't receive the code? ",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          TextSpan(
                            text: controller.otpTimer.value > 0
                                ? "Resend in ${controller.otpTimer.value}s"
                                : "Resend OTP",
                            style: TextStyle(
                              color: controller.otpTimer.value > 0 ? Colors.grey : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 32),

                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CommonButton(
                    title: controller.isLoading.value ? "Verifying..." : "Verify",
                    color: controller.otpController.text.length == 6 ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                    onTap: (controller.isLoading.value || controller.otpController.text.length < 6) ? () {} : controller.verifyOtp,
                  ),
                )),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

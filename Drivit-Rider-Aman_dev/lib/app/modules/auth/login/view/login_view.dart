import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/common_button.dart';
import '../../../../widgets/common_text.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                /// ✅ Top Image
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

                /// ✅ Title
                CommonText(
                  text: "Let’s Get You Moving",
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                /// ✅ Subtitle
                CommonText(
                  text: "Enter your mobile number to continue your journey.",
                  style: AppTextStyles.body.copyWith(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 32),

                /// ✅ Mobile Label
                CommonText(
                  text: "Mobile No",
                  style: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 8),

                /// ✅ Mobile Field with +91
                Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF7EE),
                            borderRadius: BorderRadius.circular(12),
                            border: controller.phoneError.value != null ? Border.all(color: Colors.red.shade300, width: 1) : null,
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text(
                                  "+91",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: TextField(
                                    controller: controller.phoneController,
                                    onChanged: (v) {
                                      controller.validatePhone();
                                    },
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: "Enter mobile no",
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (controller.phoneError.value != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 16),
                            child: Text(
                              controller.phoneError.value!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    )),

                const SizedBox(height: 24),

                /// ✅ Terms Checkbox
                Obx(() => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: controller.isChecked.value,
                        onChanged: (v) {
                          controller.toggleCheck(v);
                          controller.validatePhone(); // Re-validate for form logic
                        },
                        activeColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "By continuing, you agree to our Terms of Service and Privacy Policy",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                )),

                const SizedBox(height: 32),

                /// ✅ Action Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CommonButton(
                    title: controller.isLoading.value ? "Processing..." : "Get OTP",
                    onTap: (controller.isLoading.value || !controller.isFormValid()) ? () {} : controller.sendOtp,
                    color: controller.isFormValid() ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                  ),
                )),

                
                const SizedBox(height: 16),

                /// ✅ Footer 
                _buildFooter(),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: Colors.grey.shade100, thickness: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don’t have an account? ",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: controller.goToRegister,
              child: const Text(
                "Register",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

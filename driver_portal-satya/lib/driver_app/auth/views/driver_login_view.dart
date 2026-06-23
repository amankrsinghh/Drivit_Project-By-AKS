import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter/services.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';
import '../../common/widgets/primary_button.dart';
import '../../routes/driver_routes.dart';
import '../controllers/driver_login_controller.dart';

class DriverLoginView extends GetView<DriverLoginController> {
  const DriverLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Center(
                  child: Image.asset(
                    "assets/images/login.png",
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.drive_eta,
                        size: 80,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text("Go Online & Earn", style: DriverTextStyles.title),
                const SizedBox(height: 8),
                Text(
                  "Log in to go online and start receiving trip\nrequests.",
                  style: DriverTextStyles.subtitle,
                ),
                const SizedBox(height: 24),
                Text("Mobile No", style: DriverTextStyles.label),
                const SizedBox(height: 8),

                /// Mobile Field with +91 (Matching image)
                Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF7EE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: controller.phoneError.value != null
                                    ? Colors.red.shade300
                                    : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text(
                                  "+91",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: TextField(
                                    controller: controller.phoneController,
                                    onChanged: (v) => controller.validatePhone(),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: "Enter mobile no",
                                      border: InputBorder.none,
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

                const SizedBox(height: 16),

                Obx(
                  () => Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: controller.agreed.value,
                          onChanged: controller.toggle,
                          activeColor: DriverColors.primary,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "By continuing, you agree to our Terms of Service and Privacy Policy",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Obx(
                  () => DriverPrimaryButton(
                    title: controller.isLoading.value ? "Processing..." : "Get OTP",
                    bgColor: controller.isFormValid() ? DriverColors.primary : Colors.grey.withValues(alpha: 0.5),
                    onTap: (controller.isLoading.value || !controller.isFormValid()) ? () {} : controller.sendOtp,
                  ),
                ),


                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: "Register",
                        style: const TextStyle(
                          color: DriverColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () =>
                              Get.toNamed(DriverRoutes.registerStep1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48), // Extra bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}

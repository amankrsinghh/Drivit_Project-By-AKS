import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/driver_colors.dart';
import '../../common/widgets/otp_boxes.dart';
import '../controllers/driver_otp_controller.dart';

class DriverOtpView extends GetView<DriverOtpController> {
  const DriverOtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 25),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter OTP",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "We’ve sent a code to your register mobile no",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.50,
                ),
              ),
              const SizedBox(height: 20),

              // ✅ OTP boxes
              DriverOtpBoxes(
                length: 6,
                controller: controller.otpC,
                onCompleted: (v) {
                  controller.otpError.value = "";
                  controller.verify();
                },
                onChanged: (v) {
                  if (controller.otpError.value.isNotEmpty) {
                    controller.otpError.value = "";
                  }
                },
              ),

              // ✅ OTP Received Popup
              Obx(() {
                final otp = controller.receivedOtp.value;
                if (otp == null || otp.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DriverColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DriverColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sms, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "OTP Received",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Your code: $otp",
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: controller.dismissOtp,
                        child: const Text("Dismiss", style: TextStyle(fontSize: 12)),
                      ),
                      ElevatedButton(
                        onPressed: controller.applyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DriverColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Apply", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),
              
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

              const SizedBox(height: 20),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                    ),
                    children: [
                      const TextSpan(text: "Didn't receive the code? "),
                      TextSpan(
                        text: "Resend OTP",
                        style: const TextStyle(
                          color: DriverColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = controller.resendOtp,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ✅ Big pill button like image
              Obx(
                () => SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (controller.isLoading.value || controller.otpC.text.length < 6)
                        ? null
                        : controller.verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverColors.primary,
                      disabledBackgroundColor: DriverColors.primary.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      controller.isLoading.value ? "Verifying..." : "Verify",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),


              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}


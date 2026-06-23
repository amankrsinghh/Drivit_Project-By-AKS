import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../theme/driver_colors.dart';
import '../controllers/driver_trip_controller.dart';
import '../../common/widgets/primary_button.dart';

class EnterOtpDialog extends GetView<DriverTripController> {
  final VoidCallback onClose;
  final VoidCallback onVerify;

  const EnterOtpDialog({
    super.key,
    required this.onClose,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(
        fontSize: 18,
        color: Colors.black,
        fontWeight: FontWeight.w800,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Enter OTP",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    child: const Icon(Icons.close, color: Colors.orange, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Pinput(
                length: 4,
                controller: controller.otpC,
                focusNode: controller.otpFocusNode,
                autofillHints: const [],
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: DriverColors.primary),
                  ),
                ),
                onCompleted: (pin) {
                  if (pin.length == 4) {
                    onVerify();
                  }
                },
              ),
              const SizedBox(height: 32),
              Obx(() => DriverPrimaryButton(
                    title: "Confirm",
                    onTap: onVerify,
                    isLoading: controller.isVerifyingOtp.value,
                    radius: 20, // matching screenshot style
                    fontWeight: FontWeight.w900,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
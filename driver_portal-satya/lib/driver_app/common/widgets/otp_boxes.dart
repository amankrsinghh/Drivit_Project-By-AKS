import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class DriverOtpBoxes extends StatelessWidget {
  final int length;
  final TextEditingController? controller;
  final Function(String)? onCompleted;
  final Function(String)? onChanged;

  const DriverOtpBoxes({
    super.key,
    this.length = 6,
    this.controller,
    this.onCompleted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: length == 4 ? 60 : 42,
      height: length == 4 ? 60 : 42,
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.orange, width: 1.2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xffFFF7EE),
      ),
    );

    return Pinput(
      length: length,
      controller: controller,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      onCompleted: onCompleted,
      onChanged: onChanged,
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}

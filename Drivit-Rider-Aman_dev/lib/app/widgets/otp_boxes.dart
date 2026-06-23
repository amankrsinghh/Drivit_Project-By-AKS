import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class CommonOtpBoxes extends StatelessWidget {
  final int length;
  final TextEditingController? controller;
  final Function(String)? onCompleted;
  final Function(String)? onChanged;

  const CommonOtpBoxes({
    super.key,
    this.length = 6,
    this.controller,
    this.onCompleted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Styling refined to match your new request: White background with Primary borders
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.white, // Background changed to white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: const Color(0xffF38900), // Primary color border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffF38900).withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
    );

    return Pinput(
      length: length,
      controller: controller,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      showCursor: true,
      onCompleted: (pin) {
        if (onCompleted != null) {
          onCompleted!(pin);
        }
      },
      onChanged: onChanged,
      autofocus: true,
      keyboardType: TextInputType.number,
      cursor: Container(
        width: 2,
        height: 24,
        color: const Color(0xffF38900),
      ),
    );
  }
}

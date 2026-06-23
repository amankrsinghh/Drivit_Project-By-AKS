import 'package:flutter/material.dart';

class ConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  final double bottom;
  final double left;
  final double right;

  const ConfirmButton({
    super.key,
    required this.onTap,
    this.bottom = 40,
    this.left = 40,
    this.right = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: left,
      right: right,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffF38900),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onTap,
        child: const Text(
          "Confirm",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

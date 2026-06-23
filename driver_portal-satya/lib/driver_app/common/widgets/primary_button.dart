



import 'package:flutter/material.dart';
import '../../theme/driver_colors.dart';

class DriverPrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  // image-like controls
  final double height;
  final double radius;
  final double fontSize;
  final FontWeight fontWeight;
  final Color bgColor;
  final bool isLoading;
  final bool isEnabled;
  final Color textColor;

  const DriverPrimaryButton({
    super.key,
    required this.title,
    required this.onTap,
    this.height = 48,
    this.radius = 28,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
    this.bgColor = DriverColors.primary, // orange
    this.isLoading = false,
    this.isEnabled = true,
    this.textColor = Colors.black,       // screenshot me black
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isLoading || !isEnabled) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}
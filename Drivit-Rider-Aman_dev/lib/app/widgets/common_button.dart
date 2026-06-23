import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

class CommonButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final Color? color;

  const CommonButton({super.key, required this.title, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.buttonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          title,
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

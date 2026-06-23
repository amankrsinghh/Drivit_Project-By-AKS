import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class LoginFooter extends StatelessWidget {
  final VoidCallback onRegisterTap;
  const LoginFooter({super.key, required this.onRegisterTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.body.copyWith(fontSize: 14),
          children: [
            const TextSpan(
              text: "Don’t have an account? ",
              style: TextStyle(color: Colors.black54),
            ),
            TextSpan(
              text: "Register",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()..onTap = onRegisterTap,
            ),
          ],
        ),
      ),
    );
  }
}
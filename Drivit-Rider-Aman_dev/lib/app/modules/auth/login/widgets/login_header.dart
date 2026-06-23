import 'package:flutter/material.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/common_text.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset(
            "assets/images/car1.png",
            height: 180,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        CommonText(text: "Let’s Get You Moving", style: AppTextStyles.heading),
        const SizedBox(height: 8),
        CommonText(
          text: "Enter your email and password to continue your journey.",
          style: AppTextStyles.body,
        ),
      ],
    );
  }
}

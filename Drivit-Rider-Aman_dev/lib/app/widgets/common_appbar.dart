import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import 'common_text.dart';

class CommonAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const CommonAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: CommonText(
        text: title,
        style: AppTextStyles.subHeading,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
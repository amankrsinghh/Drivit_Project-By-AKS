

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DriverAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final Color backgroundColor;

  const DriverAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back, size: 25, color: Colors.black),
      )
          : null,
      title: title.isEmpty
          ? null
          : Text(title, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
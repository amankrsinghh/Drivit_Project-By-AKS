import 'package:flutter/material.dart';
import '../../theme/driver_colors.dart';

class DriverOutlineButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const DriverOutlineButton({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: DriverColors.primary),
          shape: const StadiumBorder(),
        ),
        child: Text(title, style: const TextStyle(color: DriverColors.primary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
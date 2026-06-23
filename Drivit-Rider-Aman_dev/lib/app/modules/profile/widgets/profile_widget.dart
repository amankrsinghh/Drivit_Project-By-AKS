


import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ProfileBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const ProfileBackAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFFF38900), size: 20),
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7EA), // Slightly more yellowish like reference
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrangePillButton extends StatelessWidget {
  final String title;
  final String? successTitle;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isSuccess;
  final Color? successColor;

  const OrangePillButton({
    super.key,
    required this.title,
    this.successTitle,
    required this.onTap,
    this.isLoading = false,
    this.isSuccess = false,
    this.successColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55, // Taller button
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isLoading || isSuccess) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSuccess ? successColor : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
          disabledBackgroundColor: isSuccess 
              ? successColor 
              : AppColors.primary.withValues(alpha: 0.6),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isSuccess ? (successTitle ?? title) : title,
                style: TextStyle(
                  color: isSuccess ? Colors.white : Colors.black, // White text on green success
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

InputDecoration profileFieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
    filled: true,
    fillColor: const Color(0xFFFFF7EA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1),
    ),
  );
}
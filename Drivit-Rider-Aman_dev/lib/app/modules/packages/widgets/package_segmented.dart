import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/package_controller.dart';
import '../models/package_model.dart';

class PackageSegmented extends GetView<PackagesController> {
  const PackageSegmented({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isHourly = controller.type.value == PackageType.hourly;

      return Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F2), // Light primary tint
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SegBtn(
                title: "Hourly",
                selected: isHourly,
                onTap: () => controller.setType(PackageType.hourly),
              ),
              _SegBtn(
                title: "Outstation",
                selected: !isHourly,
                onTap: () => controller.setType(PackageType.outstation),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SegBtn extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SegBtn({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.black : Colors.black54,
          ),
        ),
      ),
    );
  }
}
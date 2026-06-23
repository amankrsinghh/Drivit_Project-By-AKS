import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/package_controller.dart';

class HourSelector extends GetView<PackagesController> {
  const HourSelector({super.key});

  static const orange = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final durations = controller.availableDurations;
      final sel = controller.selectedDuration.value;

      if (durations.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: durations.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final d = durations[index];
            final selected = sel == d;

            return InkWell(
              onTap: () => controller.setDuration(d),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFFF3E6) : const Color(0xFFF6F2E7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? orange : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  controller.formatDuration(d),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? orange : Colors.black54,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
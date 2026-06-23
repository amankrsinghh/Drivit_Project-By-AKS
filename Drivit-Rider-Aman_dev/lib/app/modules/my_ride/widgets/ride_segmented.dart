import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_ride_controller.dart';
import '../models/ride_items.dart';


class RideSegmented extends GetView<MyRideController> {
  const RideSegmented({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPast = controller.segment.value == RideSegment.past;

      return Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SegButton(
                selected: isPast,
                title: "Past Trips",
                onTap: () => controller.setSegment(RideSegment.past),
              ),
              _SegButton(
                selected: !isPast,
                title: "Scheduled Trips",
                onTap: () => controller.setSegment(RideSegment.scheduled),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SegButton extends StatelessWidget {
  final bool selected;
  final String title;
  final VoidCallback onTap;

  const _SegButton({
    required this.selected,
    required this.title,
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
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.black : Colors.black54,
          ),
        ),
      ),
    );
  }
}
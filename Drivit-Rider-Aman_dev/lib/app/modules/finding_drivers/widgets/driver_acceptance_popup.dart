import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finding_driver_controller.dart';

class DriverAcceptancePopup extends StatelessWidget {
  final FindingDriverController controller;
  
  const DriverAcceptancePopup({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              "Driver Found!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "A driver has accepted your ride request",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Obx(() => CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              backgroundImage: controller.driverImage.value.isNotEmpty
                  ? NetworkImage(controller.driverImage.value)
                  : null,
              child: controller.driverImage.value.isEmpty
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            )),
            const SizedBox(height: 16),
            Obx(() => Text(
              controller.driverName.value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )),
            const SizedBox(height: 8),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 18),
                Text(
                  " ${controller.driverRating.value}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.history, color: Colors.blue, size: 18),
                Text(
                  " ${controller.driverExp.value}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

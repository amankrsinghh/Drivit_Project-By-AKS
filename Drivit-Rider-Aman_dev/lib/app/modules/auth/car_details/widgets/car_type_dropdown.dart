import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/car_details_controller.dart';

class CarTypeDropdown extends GetView<CarDetailsController> {
  const CarTypeDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final cars = const ["Manual", "Automatic", "Both"];

    return Obx(
      () => DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.transmission.value.isEmpty ? null : controller.transmission.value,
          hint: const Text(
            "Select Car Type",
            style: TextStyle(fontSize: 13, color: Colors.black26),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 24),
          items: cars
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Outfit',
                      color: Colors.black,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              controller.setTransmission(val);
            }
          },
        ),
      ),
    );
  }
}

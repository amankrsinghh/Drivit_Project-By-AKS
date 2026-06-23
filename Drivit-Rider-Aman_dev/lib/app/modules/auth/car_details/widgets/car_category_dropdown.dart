import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/car_details_controller.dart';

class CarCategoryDropdown extends GetView<CarDetailsController> {
  const CarCategoryDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: controller.selectedCategory.value,
          hint: const Text(
            "Select Car Category",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Outfit',
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 24),
          items: controller.carCategories.map((cat) {
            return DropdownMenuItem<dynamic>(
              value: cat,
              child: Text(
                cat['name'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              controller.selectCategory(val);
            }
          },
        ),
      ),
    );
  }
}

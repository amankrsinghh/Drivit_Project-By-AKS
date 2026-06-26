import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../theme/app_text_styles.dart';

import '../../../../widgets/common_text.dart';
import '../controllers/car_details_controller.dart';

class CarDetailsView extends GetView<CarDetailsController> {
  const CarDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.padding,
                  ),
                  child: _buildProfileSection(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: "Almost ",
            style: AppTextStyles.heading.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: const [
              TextSpan(
                text: "There!",
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CommonText(
          text: "Just a few details to personalize your App experience.",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),

        _buildFieldLabel("Transmission Type"),
        Obx(() => Row(
          children: controller.transmissionOptions.map((opt) {
            final isSelected = controller.transmission.value == opt;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Center(child: Text(opt)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.transmission.value = opt;
                      final cat = controller.carCategories.firstWhereOrNull((c) => c['name'] == opt);
                      if (cat != null) {
                        controller.selectedCategory.value = cat;
                      }
                    }
                  },
                  selectedColor: const Color(0xffFFF3E0),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orange.shade900 : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  side: BorderSide(
                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );
          }).toList(),
        )),
        const SizedBox(height: 20),

        _buildFieldLabel("Vehicle Fuel Type"),
        Obx(() => Row(
          children: controller.fuelTypeOptions.map((opt) {
            final isSelected = controller.fuelType.value == opt;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Center(child: Text(opt)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.fuelType.value = opt;
                    }
                  },
                  selectedColor: const Color(0xffFFF3E0),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orange.shade900 : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  side: BorderSide(
                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );
          }).toList(),
        )),
        const SizedBox(height: 20),

        _buildFieldLabel("Car Name / Model"),
        _buildTextField(
          controller.carModelController,
          "Enter your car model (e.g. Swift, Creta)",
        ),
        const SizedBox(height: 20),

        _buildFieldLabel("Your Car Number"),
        _buildTextField(
          controller.carNumberController,
          "Enter your car number",
        ),
        const SizedBox(height: 20),

        const SizedBox(height: 48),
        Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: controller.isFormValid.value
                          ? controller.submit
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isFormValid.value
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Continue",
                        style: TextStyle(
                          color: controller.isFormValid.value
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }



  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

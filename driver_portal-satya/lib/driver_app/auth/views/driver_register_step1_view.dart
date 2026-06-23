import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../common/widgets/driver_app_bar.dart';

import '../controllers/driver_register_controller.dart';

class DriverRegisterStep1View extends GetView<DriverRegisterController> {
  const DriverRegisterStep1View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const DriverAppBar(
        title: "",
        showBack: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Progress Bar Indicator
            _buildProgressBar(1),
            const SizedBox(height: 24),

            const Text(
              "Complete your driver\nregistration",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Provide your detail and document so we can\nverify your profile before assigning trip",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            _buildLabel("Driver Name"),
            Obx(() => _buildInputField(
                  controller.nameC,
                  "Enter your full name",
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                  errorText: controller.nameError.value,
                )),

            const SizedBox(height: 16),
            _buildLabel("Your Mobile no"),
            Obx(() => Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF7EE),
                    borderRadius: BorderRadius.circular(10),
                    border: controller.phoneError.value != null
                        ? Border.all(color: Colors.red.shade300, width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "+91",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller.phoneC,
                          readOnly: controller.isPhoneReadOnly.value,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter mobile no",
                            hintStyle: TextStyle(color: Colors.black26, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            Obx(() => controller.phoneError.value != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      controller.phoneError.value!,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  )
                : const SizedBox.shrink()),
            _buildLabel("Address"),
            Obx(() => _buildInputField(
                  controller.addressC,
                  "House no, street area",
                  errorText: controller.addressError.value,
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Obx(() => _buildInputField(
                        controller.cityC,
                        "City",
                        errorText: controller.cityError.value,
                      )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => _buildInputField(
                        controller.pincodeC,
                        "Pincode",
                        type: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 6,
                        errorText: controller.pincodeError.value,
                      )),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildLabel("Aadhar Number"),
            Obx(() => _buildInputField(
                  controller.aadharC,
                  "12 - digit aadhar number",
                  type: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 12,
                  errorText: controller.aadharError.value,
                )),

            const SizedBox(height: 16),
            _buildLabel("Driving License Number"),
            Obx(() => _buildInputField(
                  controller.dlC,
                  "Eg. RJ14 20110001234",
                  maxLength: 16,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s-]')),
                  ],
                  errorText: controller.dlError.value,
                )),

            const SizedBox(height: 32),
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (controller.isStep1Valid.value && !controller.isLoading.value)
                      ? controller.goStep2
                      : null,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF8C1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: controller.isLoading.value
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : const Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: index < step
                ? const Color(0xffFF8C1A)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffFFF7EE),
            borderRadius: BorderRadius.circular(10),
            border: errorText != null
                ? Border.all(color: Colors.red.shade300, width: 1)
                : null,
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            inputFormatters: formatters,
            maxLength: maxLength,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              counterText: "",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black26),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

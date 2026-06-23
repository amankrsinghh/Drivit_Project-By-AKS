import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';

import '../../common/widgets/driver_app_bar.dart';
import '../controllers/driver_register_controller.dart';

class DriverRegisterStep2View extends GetView<DriverRegisterController> {
  const DriverRegisterStep2View({super.key});

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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(2),
            const SizedBox(height: 24),
            const Text(
              "Experience Details",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _buildLabel("License Issue Year"),
            _buildInputField(
              controller.licenseYearC,
              "YYYY",
              readOnly: true,
              onTap: controller.selectLicenseYear,
            ),

            const SizedBox(height: 16),
            _buildLabel("Years of experience"),
            _buildInputField(
              controller.expYearC,
              "Total Driving experience",
              readOnly: true,
              onTap: controller.selectExpYear,
            ),

            const SizedBox(height: 16),
            _buildLabel("Transmission Type"),
            _buildDropdownField(controller.transmissionType, [
              "Manual",
              "Automatic",
              "Both",
            ]),

            const SizedBox(height: 16),
            _buildLabel("Previous driver app experience"),
            _buildDropdownField(controller.prevAppExp, ["Yes", "No"]),

            Obx(() => controller.prevAppExp.value == "Yes"
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildLabel("Experience Proof"),
                      _buildUploadBox(
                        "Upload Experience Document",
                        controller.expProofFile,
                        controller.pickExpProof,
                        controller.clearExpProof,
                      ),
                    ],
                  )
                : const SizedBox.shrink()),

            const SizedBox(height: 16),
            _buildLabel("Police Verification"),
            _buildDropdownField(controller.policeVerification, [
              "Done",
              "Not Done",
            ]),

            Obx(() => controller.policeVerification.value == "Done"
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildLabel("Verification Proof"),
                      _buildUploadBox(
                        "Upload Verification Document",
                        controller.policeVerificationFile,
                        controller.pickPoliceVerification,
                        controller.clearPoliceVerification,
                      ),
                    ],
                  )
                : const SizedBox.shrink()),

            const SizedBox(height: 48),
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: controller.isStep2Valid.value
                      ? controller.goDocs
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF8C1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
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
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffFFF7EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintStyle: const TextStyle(fontSize: 13, color: Colors.black26),
        ),
      ),
    );
  }

  Widget _buildDropdownField(RxString value, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Obx(
        () => DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value.value == "Select" ? null : value.value,
            hint: const Text(
              "Select",
              style: TextStyle(fontSize: 13, color: Colors.black26),
            ),
            isExpanded: true,
            items: items
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (val) => value.value = val!,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBox(
      String label, RxString filePath, VoidCallback onTap, VoidCallback onClear) {
    return Obx(
      () => GestureDetector(
        onTap: filePath.value.isEmpty ? onTap : null,
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xffF2F2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: filePath.value.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_upload_outlined,
                        color: Colors.grey, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      "JPEG,PDF Only",
                      style: TextStyle(fontSize: 9, color: Colors.black26),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Center(
                      child: filePath.value.endsWith(".pdf")
                          ? const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 40,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(filePath.value),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: onClear,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

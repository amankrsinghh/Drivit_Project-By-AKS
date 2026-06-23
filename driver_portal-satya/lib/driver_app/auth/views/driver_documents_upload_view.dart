import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/widgets/driver_app_bar.dart';
import '../controllers/driver_register_controller.dart';

class DriverDocumentsUploadView extends GetView<DriverRegisterController> {
  const DriverDocumentsUploadView({super.key});

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
            _buildProgressBar(3),
            const SizedBox(height: 24),
            const Text(
              "Documents upload",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text(
              "Aadhaar Document",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildUploadBox(
                    "Upload a photo Front",
                    controller.aadharFrontFile,
                    controller.pickAadharFront,
                    controller.clearAadharFront,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUploadBox(
                    "Upload a photo Back",
                    controller.aadharBackFile,
                    controller.pickAadharBack,
                    controller.clearAadharBack,
                  ),
                ),
              ],
            ),
            /* 
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "( JPG,PDF Only )",
                style: TextStyle(fontSize: 10, color: Colors.black26),
              ),
            ),
            */ 
            // Removed as it is now inside boxes

            const SizedBox(height: 24),
            const Text(
              "License Document",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildUploadBox(
              "Upload a photo",
              controller.licenseFile,
              controller.pickLicense,
              controller.clearLicense,
            ),
            /*
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "( JPG,PDF Only )",
                style: TextStyle(fontSize: 10, color: Colors.black26),
              ),
            ),
            */

            const SizedBox(height: 48),
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (controller.isLoading.value || 
                              controller.aadharFrontFile.value.isEmpty || 
                              controller.aadharBackFile.value.isEmpty || 
                              controller.licenseFile.value.isEmpty)
                      ? null
                      : controller.submitDocs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF8C1A),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    controller.isLoading.value ? "Registering..." : "Confirm",
                    style: const TextStyle(
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
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 60,
          height: 5,
          decoration: BoxDecoration(
            color: index == (step - 1)
                ? const Color(0xffFF8C1A)
                : const Color(0xffBDCAD6), // Greyish blue from Figma
            borderRadius: BorderRadius.circular(2),
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

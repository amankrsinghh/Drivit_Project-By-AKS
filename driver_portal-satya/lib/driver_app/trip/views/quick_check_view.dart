//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../theme/driver_colors.dart';
// import '../../common/widgets/primary_button.dart';
// import '../controllers/driver_trip_controller.dart';
//
// class DriverQuickCheckView extends GetView<DriverTripController> {
//   const DriverQuickCheckView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final top = MediaQuery.of(context).padding.top;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           // Top orange bar
//           Container(
//             color: DriverColors.primary,
//             padding: EdgeInsets.only(top: top),
//             child: SizedBox(
//               height: 56,
//               child: Row(
//                 children: [
//                   const SizedBox(width: 12),
//                   InkWell(
//                     onTap: () => Get.back(),
//                     borderRadius: BorderRadius.circular(99),
//                     child: Container(
//                       width: 36,
//                       height: 36,
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(Icons.arrow_back, size: 20),
//                     ),
//                   ),
//                   const Expanded(
//                     child: Center(
//                       child: Text(
//                         "Quick Check",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w900,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 48),
//                 ],
//               ),
//             ),
//           ),
//
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//               child: Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Color(0x14000000),
//                       blurRadius: 14,
//                       offset: Offset(0, 8),
//                     )
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     _switchRow("Clean The Card"),
//                     const SizedBox(height: 10),
//                     _switchRow("Check for dent/scratch"),
//
//                     const SizedBox(height: 12),
//
//                     // Upload box (UI only)
//                     Container(
//                       height: 110,
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF4F4F4),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.file_upload_outlined,
//                               color: Colors.black45, size: 26),
//                           SizedBox(height: 6),
//                           Text("Upload a photo",
//                               style: TextStyle(
//                                   color: Colors.black54,
//                                   fontWeight: FontWeight.w700)),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 10),
//
//                     // file chips (dummy)
//                     Row(
//                       children: [
//                         _chip("File dent"),
//                         const SizedBox(width: 10),
//                         _chip("Upload Image"),
//                       ],
//                     ),
//
//                     const SizedBox(height: 12),
//                     _switchRow("Confirm Damage with Customer"),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           SafeArea(
//             top: false,
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
//               child: SizedBox(
//                 height: 52,
//                 width: double.infinity,
//                 child: DriverPrimaryButton(
//                   title: "Start Trip",
//                   onTap: controller.openOtpDialog, // ✅ OTP popup
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _switchRow(String title) {
//     return Row(
//       children: [
//         Expanded(
//           child: Text(
//             title,
//             style: const TextStyle(fontWeight: FontWeight.w700),
//           ),
//         ),
//         Switch(
//           value: true,
//           onChanged: (_) {},
//           activeColor: DriverColors.primary,
//         )
//       ],
//     );
//   }
//
//   Widget _chip(String text) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF3F3F3),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 text,
//                 style: const TextStyle(fontSize: 12, color: Colors.black54),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             const SizedBox(width: 6),
//             const Icon(Icons.close, size: 16, color: Colors.black45),
//           ],
//         ),
//       ),
//     );
//   }
// }




//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../theme/driver_colors.dart';
// import '../../common/widgets/primary_button.dart';
// import '../controllers/driver_trip_controller.dart';
//
// class DriverQuickCheckView extends GetView<DriverTripController> {
//   const DriverQuickCheckView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final top = MediaQuery.of(context).padding.top;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           // Top orange bar
//           Container(
//             color: DriverColors.primary,
//             padding: EdgeInsets.only(top: top),
//             child: SizedBox(
//               height: 56,
//               child: Row(
//                 children: [
//                   const SizedBox(width: 12),
//                   InkWell(
//                     onTap: () => Get.back(),
//                     borderRadius: BorderRadius.circular(99),
//                     child: Container(
//                       width: 36,
//                       height: 36,
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(Icons.arrow_back, size: 20),
//                     ),
//                   ),
//                   const Expanded(
//                     child: Center(
//                       child: Text(
//                         "Quick Check",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w900,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 48),
//                 ],
//               ),
//             ),
//           ),
//
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//               child: Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Color(0x14000000),
//                       blurRadius: 14,
//                       offset: Offset(0, 8),
//                     )
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     _switchRow("Clean The Car", controller.qcCleanCar),
//                     const SizedBox(height: 10),
//                     _switchRow("Check for dent/scratch", controller.qcDentScratch),
//
//                     const SizedBox(height: 12),
//
//                     // Upload box (UI only)
//                     Container(
//                       height: 110,
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF4F4F4),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.file_upload_outlined,
//                               color: Colors.black45, size: 26),
//                           SizedBox(height: 6),
//                           Text(
//                             "Upload a photo",
//                             style: TextStyle(
//                               color: Colors.black54,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 10),
//
//                     // chips (UI only)
//                     Row(
//                       children: [
//                         _chip("File dent"),
//                         const SizedBox(width: 10),
//                         _chip("Upload Image"),
//                       ],
//                     ),
//
//                     const SizedBox(height: 12),
//                     _switchRow("Confirm Damage with Customer", controller.qcConfirmDamage),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           SafeArea(
//             top: false,
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
//               child: SizedBox(
//                 height: 52,
//                 width: double.infinity,
//                 child: DriverPrimaryButton(
//                   title: "Start Trip",
//                   onTap: controller.openOtpDialog, // ✅ OTP popup
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _switchRow(String title, RxBool value) {
//     return Obx(() {
//       return Row(
//         children: [
//           Expanded(
//             child: Text(
//               title,
//               style: const TextStyle(fontWeight: FontWeight.w700),
//             ),
//           ),
//           Switch(
//             value: value.value,
//             onChanged: (v) => value.value = v, // ✅ ON/OFF working
//             activeColor: DriverColors.primary,
//             activeTrackColor: DriverColors.primary.withValues(alpha: 0.35),
//             inactiveThumbColor: Colors.white,
//             inactiveTrackColor: const Color(0xFFDDDDDD),
//           ),
//         ],
//       );
//     });
//   }
//
//   Widget _chip(String text) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF3F3F3),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 text,
//                 style: const TextStyle(fontSize: 12, color: Colors.black54),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             const SizedBox(width: 6),
//             const Icon(Icons.close, size: 16, color: Colors.black45),
//           ],
//         ),
//       ),
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/driver_colors.dart';
import '../../routes/driver_routes.dart';
import '../controllers/driver_trip_controller.dart';

class DriverQuickCheckView extends GetView<DriverTripController> {
  const DriverQuickCheckView({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Top orange bar
            Container(
              color: DriverColors.primary,
              padding: EdgeInsets.only(top: top),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => Get.offAllNamed(DriverRoutes.home),
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Quick Check",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _switchRow("Clean The Car", controller.qcCleanCar),
                    const SizedBox(height: 10),
                    _switchRow("Check for dent/scratch", controller.qcDentScratch),

                    const SizedBox(height: 12),
                    // Upload box
                    InkWell(
                      onTap: controller.pickQCImage,
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.file_upload_outlined,
                                color: Colors.black45, size: 26),
                            SizedBox(height: 6),
                            Text(
                              "Upload a photo",
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // file chips
                    Obx(() {
                      if (controller.qcDamageImages.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.qcDamageImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final path = entry.value;
                          final fileName = path.split('/').last;
                          return SizedBox(
                            width: (Get.width - 60) / 2, // 2 chips per row approx
                            child: _chip(fileName, () => controller.removeQCImage(index)),
                          );
                        }).toList(),
                      );
                    }),

                    const SizedBox(height: 12),
                    _switchRow("Confirm Damage with Customer", controller.qcConfirmDamage),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Obx(() {
                if (controller.isStartingTrip.value) {
                  return const Center(child: CircularProgressIndicator(color: DriverColors.primary));
                }
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isQuickCheckValid ? controller.openOtpDialog : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: const Text(
                      "Start Trip",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(String title, RxBool value) {
    return Obx(() {
      return Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Switch(
            value: value.value,                 // ✅ ON/OFF dynamic
            onChanged: (v) => value.value = v,  // ✅ update
            activeColor: DriverColors.primary,
            activeTrackColor: DriverColors.primary.withValues(alpha: 0.35),
            inactiveTrackColor: const Color(0xFFDDDDDD),
          ),
        ],
      );
    });
  }

  Widget _chip(String text, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
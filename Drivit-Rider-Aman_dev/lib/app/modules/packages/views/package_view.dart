// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/package_controller.dart';
// import '../../../theme/app_colors.dart';
// import '../widgets/hour_selector.dart';
// import '../widgets/package_detail.dart';
// import '../widgets/package_segmented.dart';

// class PackagesView extends StatelessWidget {
//   const PackagesView({super.key});

//   PackagesController get controller => Get.isRegistered<PackagesController>()
//       ? Get.find<PackagesController>()
//       : Get.put(PackagesController());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(child: CircularProgressIndicator(color: AppColors.primary));
//         }

//         final rows = controller.currentRows;

//         if (rows.isEmpty) {
//           return RefreshIndicator(
//             onRefresh: () => controller.fetchPackages(),
//             color: AppColors.primary,
//             child: ListView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               children: [
//                 SizedBox(
//                   height: MediaQuery.of(context).size.height * 0.8,
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 30),
//                       Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           if (Get.currentRoute == '/packages')
//                             Align(
//                               alignment: Alignment.centerLeft,
//                               child: IconButton(
//                                 icon: const Icon(Icons.arrow_back),
//                                 onPressed: () => Get.back(),
//                               ),
//                             ),
//                           const Center(
//                             child: Text(
//                               "Package",
//                               style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 25),
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 10),
//                         child: PackageSegmented(),
//                       ),
//                       const Spacer(),
//                       const Text("No packages available for this type"),
//                       const Spacer(),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return RefreshIndicator(
//           onRefresh: () => controller.fetchPackages(),
//           color: AppColors.primary,
//           child: ListView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 110), // Bottom padding for bar
//             children: [
//               const SizedBox(height: 30),
//               Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   if (Get.currentRoute == '/packages')
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_back),
//                         onPressed: () => Get.back(),
//                       ),
//                     ),
//                   const Center(
//                     child: Text(
//                       "Package",
//                       style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 25),

//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 10),
//                 child: PackageSegmented(),
//               ),

//               const SizedBox(height: 16),

//               const HourSelector(),
//               const SizedBox(height: 18),

//               const Text("Packages Detail", style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),),
//               const SizedBox(height: 10),

//               PackageDetailCard(rows: rows),
//               const SizedBox(height: 32),
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: Obx(() => ElevatedButton(
//                   onPressed: controller.isBuying.value 
//                       ? null 
//                       : () => controller.buyCurrentPackage(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     elevation: 0,
//                   ),
//                   child: controller.isBuying.value
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Text(
//                           "Buy Now",
//                           style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                 )),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }
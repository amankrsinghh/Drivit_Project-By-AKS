//
//
//
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../theme/app_colors.dart';
//
// class AboutUsView extends StatelessWidget {
//   const AboutUsView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//
//       // ✅ Proper AppBar (title thoda niche)
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios_new,
//             color: AppColors.primary,
//             size: 18,
//           ),
//           onPressed: () => Get.back(),
//         ),
//         title: const Padding(
//           padding: EdgeInsets.only(top: 35), // ✅ title niche
//           child: Text(
//             "About Us",
//             style: TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.w700,
//               fontSize: 16,
//             ),
//           ),
//         ),
//       ),
//
//       // ✅ Text thoda niche
//       body: const Padding(
//         padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
//         child: Text(
//           "We are a trusted driver booking platform designed\n"
//               "to make travel simple, safe, and reliable. Our app\n"
//               "connects customers with verified drivers for both\n"
//               "instant and scheduled rides. With real-time\n"
//               "tracking, transparent pricing, and secure OTP ride\n"
//               "verification, we ensure a smooth and stress-free\n"
//               "journey from pickup to drop-off.",
//           style: TextStyle(
//             color: Colors.black54,
//             height: 1.35,
//             fontSize: 16,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';

class AboutUsView extends StatelessWidget {
  const AboutUsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFFF38900), size: 20),
            ),
          ),
        ),
        title: const Text(
          "About Us",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getPolicy('About'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String content = "Failed to load About Us information.";
          if (snapshot.hasData && snapshot.data!['error'] == null) {
            String rawHtml = snapshot.data!['content'] ?? "No Information available at the moment.";
            content = rawHtml
                .replaceAll(RegExp(r'</p>|<br\s*/?>'), '\n')
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll('&nbsp;', ' ')
                .trim();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Text(
              content,
              style: const TextStyle(
                color: Color(0xFF555555),
                height: 1.6,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }
}

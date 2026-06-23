//
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../theme/app_colors.dart';
//
// class PrivacyPolicyView extends StatelessWidget {
//   const PrivacyPolicyView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation:0 ,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back,
//             color: AppColors.primary,
//             size: 22,
//           ),
//           onPressed: () => Get.back(),
//         ),
//         title: const Padding(
//           padding: EdgeInsets.only(top: 30),
//           child: Text(
//             "Privacy Policy",
//             style: TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.w700,
//               fontSize: 20,
//             ),
//           ),
//         ),
//       ),
//
//       body: const SingleChildScrollView(
//         padding: EdgeInsets.fromLTRB(10, 20, 16, 16), // ✅ appbar ke baad spacing
//         child: Text(
//           "Privacy Policy\n"
//               "Last updated: 2026\n\n"
//               "This Privacy Policy explains how we collect, use, and protect your "
//               "information when you use our driver booking application.\n\n"
//               "1) Information We Collect\n"
//               "• Personal details: name, phone number, email address.\n"
//               "• Ride details: pickup/drop location, ride time, booking ID, trip history.\n"
//               "• Location data: to enable pickup, navigation, and ride tracking.\n"
//               "• Device data: app version, crash logs for improving performance.\n\n"
//               "2) How We Use Your Information\n"
//               "• To provide and manage your rides.\n"
//               "• To communicate booking updates and support.\n"
//               "• To improve safety and user experience.\n"
//               "3) Sharing of Information\n"
//               "We may share limited information with drivers and service providers "
//               "required to complete a booking. We do not sell your personal data.\n\n"
//               "4) Data Security\n"
//               "We use reasonable security practices to protect your information.\n\n"
//               "5) Contact Us\n"
//               "For questions, use the Contact Us section in the app.",
//           style: TextStyle(color: Colors.black54, height: 1.4, fontSize: 15),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
          "Privacy Policy",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getPolicy('Privacy'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String content = "Failed to load policy.";
          if (snapshot.hasData && snapshot.data!['error'] == null) {
            String rawHtml = snapshot.data!['content'] ?? "No privacy policy available at the moment.";
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../../../core/services/api_service.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Get.back(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getPolicy('Terms'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String content = "Failed to load Terms & Conditions.";
          if (snapshot.hasData && snapshot.data!['error'] == null) {
            String rawHtml =
                snapshot.data!['content'] ??
                "No Terms & Conditions available at the moment.";
            content = rawHtml
                .replaceAll(RegExp(r'</p>|<br\s*/?>'), '\n')
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll('&nbsp;', ' ')
                .trim();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.50,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../../theme/driver_colors.dart';
import '../../../services/api_service.dart';

class DriverAboutUsView extends StatelessWidget {
  const DriverAboutUsView({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: DriverColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _orangeHeader(top, "About Us"),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: ApiService.getPolicy('About'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  String content = "Failed to load About Us information.";
                  if (snapshot.hasData && snapshot.data!['error'] == null) {
                    String rawHtml = snapshot.data!['content'] ??
                        "No Information available at the moment.";
                    content = rawHtml
                        .replaceAll(RegExp(r'</p>|<br\s*/?>'), '\n')
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .replaceAll('&nbsp;', ' ')
                        .trim();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _orangeHeader(double top, String title) {
    return Container(
      color: DriverColors.primary,
      padding: EdgeInsets.only(top: top),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 12),
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(99),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 25),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

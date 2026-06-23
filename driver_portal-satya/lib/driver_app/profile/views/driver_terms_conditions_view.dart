import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../theme/driver_colors.dart';

class DriverTermsConditionsView extends StatelessWidget {
  const DriverTermsConditionsView({super.key});

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
            _orangeHeader(top, "Terms & Conditions"),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: ApiService.getPolicy('Terms'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  String content = "Failed to load policy.";
                  if (snapshot.hasData && snapshot.data!['error'] == null) {
                    String rawHtml =
                        snapshot.data!['content'] ??
                        "No terms & conditions available at the moment.";
                    // Strip HTML tags for clean display
                    content = rawHtml
                        .replaceAll(RegExp(r'</p>|<br\s*/?>'), '\n')
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .replaceAll('&nbsp;', ' ')
                        .trim();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 19, 18, 19),
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

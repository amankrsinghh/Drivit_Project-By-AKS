


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../theme/driver_colors.dart';

class DriverRateUsView extends StatefulWidget {
  const DriverRateUsView({super.key});

  @override
  State<DriverRateUsView> createState() => _DriverRateUsViewState();
}

class _DriverRateUsViewState extends State<DriverRateUsView> {
  int rating = 4;
  final c = TextEditingController();

  bool submitting = false;
  bool submitted = false;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (submitting || submitted) return;

    setState(() => submitting = true);
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      submitting = false;
      submitted = true;
    });

    // Get.snackbar removed
  }

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
            _orangeHeader(top, "Rate Us"),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 19, 18, 19),
                child: Column(
                  children: [
                    Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Image.asset(
                          "assets/images/rate_us.png",
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ⭐⭐⭐⭐⭐ (bigger)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          onPressed:
                          submitted ? null : () => setState(() => rating = star),
                          icon: Icon(
                            Icons.star,
                            size: 34, // ✅ bigger stars
                            color: star <= rating ? Colors.orange : Colors.black26,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 8),

                    // Feedback (bigger font)
                    TextField(
                      controller: c,
                      enabled: !submitted,
                      maxLength: 300,
                      minLines: 7,
                      maxLines: 7,
                      style: const TextStyle(fontSize: 20), // ✅ input text bigger
                      decoration: InputDecoration(
                        hintText: "Write your feedback here...",
                        hintStyle: const TextStyle(
                          fontSize: 20, // ✅ hint bigger
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                        counterStyle: const TextStyle(fontSize: 18), // ✅ counter bigger
                        filled: true,
                        fillColor: const Color(0xFFF4F4F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Submit (bigger text)
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (submitting || submitted) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: submitted
                              ? const Color(0xFF34C759)
                              : DriverColors.primary,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          disabledBackgroundColor: submitted
                              ? const Color(0xFF34C759)
                              : DriverColors.primary.withValues(alpha: 0.6),
                        ),
                        child: submitting
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (submitted) ...[
                              const Icon(Icons.check,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              submitted ? "Submitted" : "Submit Review",
                              style: TextStyle(
                                fontSize: 18,
                                color: submitted ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w900,

                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Header font size bigger
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
                child: Icon(Icons.arrow_back, color: Colors.white, size: 25,),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25, // ✅ was 14
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/notification_service.dart';
import '../../../theme/app_colors.dart';

class RateUsView extends StatefulWidget {
  const RateUsView({super.key});

  @override
  State<RateUsView> createState() => _RateUsViewState();
}

class _RateUsViewState extends State<RateUsView> {
  int rating = 0;
  final feedbackC = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    feedbackC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ Rate Us
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
            size: 25,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 30),
          child: Text(
            "Rate Us",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 22),
        children: [
          Container(
            height: 170,
            alignment: Alignment.center,
            child: Image.asset(
              "assets/images/customer.png",
              height: 150,
              fit: BoxFit.contain,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              final active = idx <= rating;
              return InkWell(
                onTap: () {
                  setState(() {
                    if (rating == idx) {
                      rating = 0; // Deselect if tapping the same star
                    } else {
                      rating = idx; // Select new rating
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    active ? Icons.star : Icons.star_border,
                    color: active ? const Color(0xFFFFB300) : Colors.black26,
                    size: 28,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: feedbackC,
              maxLines: 6,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Write your feedback here...",
                hintStyle: TextStyle(color: Colors.black54, fontSize: 15),
              ),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_isLoading || _isSuccess)
                  ? null
                  : () async {
                      if (rating == 0) {
                        NotificationService.to.showLocalNotification(
                          title: "Rating Required",
                          body: "Please select a rating",
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      
                      // Simulate API call
                      await Future.delayed(const Duration(milliseconds: 800));
                      
                      if (!mounted) return;
                      setState(() {
                        _isLoading = false;
                        _isSuccess = true;
                      });

                      NotificationService.to.showLocalNotification(
                        title: "Thank you",
                        body: "Review submitted successfully",
                      );

                      // Reset everything after 2 seconds
                      await Future.delayed(const Duration(seconds: 2));
                      
                      if (!mounted) return;
                      setState(() {
                        _isSuccess = false;
                        rating = 0;
                        feedbackC.clear();
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSuccess ? Colors.green : AppColors.primary,
                disabledBackgroundColor: _isSuccess ? Colors.green : AppColors.primary,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : _isSuccess
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Submitted!",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "Submit Review",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../theme/driver_colors.dart';

class CustomerRatingDialog extends StatefulWidget {
  final String rideId;
  final String customerId;
  final String customerName;
  final String? customerImage;
  final VoidCallback onComplete;

  const CustomerRatingDialog({
    super.key,
    required this.rideId,
    required this.customerId,
    required this.customerName,
    this.customerImage,
    required this.onComplete,
  });

  @override
  _CustomerRatingDialogState createState() => _CustomerRatingDialogState();
}

class _CustomerRatingDialogState extends State<CustomerRatingDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Rate Your Customer",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DriverColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    widget.customerImage != null &&
                        widget.customerImage!.isNotEmpty
                    ? NetworkImage(ApiService.getImageUrl(widget.customerImage))
                    : null,
                child:
                    widget.customerImage == null ||
                        widget.customerImage!.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                widget.customerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      Icons.star,
                      size: 36,
                      color: star <= _rating ? Colors.orange : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "Write a comment (optional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator(color: DriverColors.primary)
              else
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _skipRating,
                        child: const Text(
                          "Skip",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _rating > 0 ? _submitRating : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rating > 0
                              ? DriverColors.primary
                              : Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await ApiService.submitCustomerRating(
        tripId: widget.rideId,
        customerId: widget.customerId,
        rating: _rating.toDouble(),
        comment: _commentController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rated_${widget.rideId}', true);

      if (res.containsKey('error')) {
        Get.snackbar(
          "Error",
          res['error'] ?? "Failed to submit rating",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }

      if (mounted) Get.back(); // Close dialog safely
      widget.onComplete();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Something went wrong",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rated_${widget.rideId}', true);
      } catch (_) {}
      if (mounted) Get.back(); // Close dialog safely
      widget.onComplete();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipRating() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await ApiService.skipCustomerRating(widget.rideId);

      // Save flag locally even on skip
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rated_${widget.rideId}', true);

      if (mounted) Get.back(); // Close dialog safely
      widget.onComplete();
    } catch (e) {
      if (mounted) Get.back();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

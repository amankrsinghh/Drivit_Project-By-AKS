import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../modules/my_ride/models/ride_items.dart';

class DriverRatingDialog extends StatefulWidget {
  final RideItem ride;
  final VoidCallback onComplete;

  const DriverRatingDialog({
    super.key,
    required this.ride,
    required this.onComplete,
  });

  @override
  _DriverRatingDialogState createState() => _DriverRatingDialogState();
}

class _DriverRatingDialogState extends State<DriverRatingDialog> {
  double _rating = 0.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Rate Your Driver",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF07E23),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.ride.driverProfileImage != null
                  ? NetworkImage(
                      ApiService.getImageUrl(widget.ride.driverProfileImage),
                    )
                  : null,
              child: widget.ride.driverProfileImage == null
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              widget.ride.driverName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: 0,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              unratedColor: Colors.grey[300],
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Color(0xFFF07E23)),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
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
              const CircularProgressIndicator(color: Color(0xFFF07E23))
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
                            ? const Color(0xFFF07E23)
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
    );
  }

  Future<void> _submitRating() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.submitDriverRating(
        tripId: widget.ride.rawId!,
        driverId: widget.ride.rawDriverId!,
        rating: _rating,
        comment: _commentController.text,
      );
      if (res.containsKey('error')) {
        NotificationService.to.showLocalNotification(
          title: "Error",
          body: res['error'] ?? "Failed to submit rating",
        );
      } else {
        // Save flag locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rated_${widget.ride.rawId}', true);

        Get.back(); // Close dialog
        widget.onComplete();
      }
    } catch (e) {
        NotificationService.to.showLocalNotification(
          title: "Error",
          body: "Something went wrong",
        );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _skipRating() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.skipDriverRating(widget.ride.rawId!);

      // Save flag locally even on skip
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rated_${widget.ride.rawId}', true);

      Get.back(); // Close dialog
      widget.onComplete();
    } catch (e) {
      Get.back();
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

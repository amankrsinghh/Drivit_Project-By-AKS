import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../routes/app_routes.dart';

class ProfileController extends GetxController {
  final name = "".obs;
  final phone = "".obs;
  final email = "".obs;
  final address = "".obs;
  final avgRating = 0.0.obs;
  final displayId = "".obs;

  final isLoading = false.obs;

  // For profile image
  final profileImagePath = "".obs; // Local preview
  final profileImageUrl = "".obs;  // Network URL

  void setProfileImage(String path) {
    profileImagePath.value = path;
  }

  @override
  void onInit() {
    super.onInit();
    // Use synchronously pre-loaded cache if available
    if (ApiService.cachedProfile != null) {
      _applyProfileData(ApiService.cachedProfile!);
    } else {
      _loadCachedProfile();
    }
    fetchProfile();
  }

  Future<void> _loadCachedProfile() async {
    final cached = await ApiService.getCachedCustomerProfile();
    if (cached != null) {
      _applyProfileData(cached);
    }
  }

  void _applyProfileData(Map<String, dynamic> data) {
    name.value = data['name'] ?? '';
    phone.value = data['phone'] ?? '';
    email.value = data['email'] ?? '';
    address.value = data['address'] ?? '';
    displayId.value = data['displayId'] ?? '';
    
    final double ratingVal = (data['rating'] ?? 0.0).toDouble();
    if (ratingVal > 0) {
      avgRating.value = ratingVal;
    } else {
      final double total = (data['totalRating'] ?? 0.0).toDouble();
      final int count = (data['ratingCount'] ?? 0).toInt();
      avgRating.value = count > 0 ? total / count : 0.0;
    }
    
    if (data['profileImage'] != null) {
      profileImageUrl.value = ApiService.getImageUrl(data['profileImage']);
      // Clear local path once we have the network URL
      profileImagePath.value = "";
    }
  }

  Future<void> fetchProfile() async {
    final customerId = await ApiService.getCustomerId();
    if (customerId == null) return;

    isLoading.value = true;
    final res = await ApiService.getCustomerProfile(customerId);
    isLoading.value = false;

    if (res.containsKey('error')) {
      final error = res['error'].toString().toLowerCase();
      if (error.contains('not found') || error.contains('not authorized')) {
        // This is a safety catch, though ApiService._processResponse already calls logout()
        logout();
      }
    } else {
      _applyProfileData(res);
      await ApiService.saveCustomerProfile(res);
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    Get.offAllNamed(Routes.login);
  }
}

import 'package:get/get.dart';
import '../../../core/services/api_service.dart';

class MyPackagesController extends GetxController {
  final packages = <dynamic>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyPackages();
  }

  Future<void> fetchMyPackages() async {
    isLoading.value = true;
    try {
      final res = await ApiService.getMyPackages(); // We'll add this to ApiService
      if (res is List) {
        packages.assignAll(res);
      }
    } catch (e) {
      // Background failure handled by FCM
    } finally {
      isLoading.value = false;
    }
  }

  bool isExpired(dynamic p) {
    if (p['expiresAt'] == null) return false;
    final expiry = DateTime.parse(p['expiresAt'].toString());
    return expiry.isBefore(DateTime.now());
  }
}

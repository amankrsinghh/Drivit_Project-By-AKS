import 'package:get/get.dart';
import '../../../core/services/api_service.dart';

class TariffsController extends GetxController {
  final isLoading = true.obs;
  
  // Data lists
  final tripTypes = <dynamic>[].obs;
  final hourlyPackages = <dynamic>[].obs;
  final outstationPackages = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      final futures = await Future.wait([
        ApiService.getTripTypes(),
        ApiService.getAllPackages(),
      ]);

      final tripTypeData = futures[0];
      final packageData = futures[1];

      tripTypes.value = tripTypeData.where((t) => t['status'] == 'Active').toList();
      
      final packages = packageData.where((p) => p['status'] == 'Active').toList();
      hourlyPackages.value = packages.where((p) => p['type'] == 'Hourly').toList();
      outstationPackages.value = packages.where((p) => p['type'] == 'Outstation').toList();
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load tariffs data');
    } finally {
      isLoading.value = false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/validators.dart';
import '../../register/controller/register_controller.dart';

class CarDetailsController extends GetxController {
  final carModelController = TextEditingController();
  final carNumberController = TextEditingController();
  
  final isOpen = false.obs;
  final isCategoryOpen = false.obs;
  final selectedType = Rx<String?>(null);
  final transmission = 'Manual'.obs; // Default to Manual
  final fuelType = 'Petrol'.obs;      // Default to Petrol
  final isLoading = false.obs;

  final carCategories = <dynamic>[].obs;
  final selectedCategory = Rx<dynamic>(null);
  final isFormValid = false.obs;

  final transmissionOptions = ['Manual', 'Automatic'];
  final fuelTypeOptions = ['Petrol', 'Diesel', 'EV'];

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    carNumberController.addListener(_validateForm);
    carModelController.addListener(_validateForm);
    
    // Also listen to observable changes
    ever(selectedCategory, (cat) {
      if (cat != null) {
        transmission.value = cat['name'] ?? 'Manual';
      }
      _validateForm();
    });
    ever(transmission, (_) => _validateForm());
    ever(fuelType, (_) => _validateForm());
  }

  void _validateForm() {
    isFormValid.value = selectedCategory.value != null &&
        carModelController.text.trim().isNotEmpty &&
        carNumberController.text.trim().isNotEmpty &&
        transmission.value.isNotEmpty &&
        fuelType.value.isNotEmpty;
  }

  Future<void> fetchCategories() async {
    final categories = await ApiService.getCarCategories();
    carCategories.assignAll(categories);
    
    // Auto-select first category if available
    if (categories.isNotEmpty && selectedCategory.value == null) {
      selectCategory(categories.first);
    }
  }

  void toggleCategoryDropdown() {
    isCategoryOpen.value = !isCategoryOpen.value;
  }

  void selectCategory(dynamic category) {
    selectedCategory.value = category;
    isCategoryOpen.value = false;
  }

  void setTransmission(String value) {
    transmission.value = value;
    selectedType.value = value; // Sync with selectedType for register validation
    isOpen.value = false;
  }

  void toggleDropdown() {
    isOpen.value = !isOpen.value;
  }

  void selectType(String type) {
    selectedType.value = type;
    isOpen.value = false;
  }

  Future<void> submit() async {
    final categoryErr = selectedCategory.value == null ? 'Please select car category' : null;
    if (categoryErr != null) {
      Get.snackbar('Error', 'Please select a car category',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final modelErr = Validators.validateRequired(carModelController.text, 'Car Model/Name');
    if (modelErr != null) {
      Get.snackbar('Error', 'Please enter your car model/name',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final numberErr = Validators.validateRequired(carNumberController.text, 'Car Number Plate');
    if (numberErr != null) {
      return;
    }

    isLoading.value = true;
    
    // Fetch data from RegisterController or fallback to persistent storage
    String name = "";
    String email = "";
    String phone = "";
    String address = "";

    if (Get.isRegistered<RegisterController>()) {
      final registerC = Get.find<RegisterController>();
      name = registerC.nameController.text.trim();
      email = registerC.emailController.text.trim();
      phone = registerC.phoneController.text.trim();
      address = registerC.addressController.text.trim();
    } else {
      // Recovery mode: Load from SharedPreferences
      final regData = await ApiService.getRegistrationData();
      final pending = await ApiService.getPendingPhone();
      name = regData['name'] ?? "";
      email = regData['email'] ?? "";
      address = regData['address'] ?? "";
      phone = pending ?? "";

      if (name.isEmpty || phone.isEmpty) {
        isLoading.value = false;
        Get.offAllNamed(Routes.register);
        return;
      }
    }
    
    final res = await ApiService.registerCustomer(
      name: name,
      email: email,
      phone: phone,
      address: address,
      carModel: carModelController.text.trim(),
      carNumber: carNumberController.text.trim(),
      carType: selectedCategory.value['name'],
      transmission: transmission.value,
      fuelType: fuelType.value,
    );
    isLoading.value = false;

    if (res.containsKey('error')) {
      // Failure handled by FCM
    } else {
      final token = res['token'];
      final user = res['user'] ?? res['customer'] ?? {};
      
      await ApiService.logout(); // Wipe old session
      await ApiService.saveSession(token, user['_id'] ?? '');
      await ApiService.saveCustomerProfile(user);
      await ApiService.setProfileComplete(true);
      
      // Update FCM token after registration
      if (Get.isRegistered<NotificationService>()) {
        await NotificationService.to.getTokenAndSave();
      }
      
      // Clear registration step
      await ApiService.setRegistrationStep(0);
      
      if (!Get.isRegistered<SocketService>()) {
        Get.put(SocketService(), permanent: true);
      }
      
      Get.offAllNamed(Routes.home);
    }
  }

  @override
  void onClose() {
    carModelController.dispose();
    carNumberController.dispose();
    super.onClose();
  }
}

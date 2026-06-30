import 'package:get/get.dart';
import '../controllers/car_clinic_controller.dart';

class CarClinicBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CarClinicController>(() => CarClinicController());
  }
}

import 'package:get/get.dart';
import '../controllers/driver_login_controller.dart';

class DriverLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverLoginController>(() => DriverLoginController());
  }
}
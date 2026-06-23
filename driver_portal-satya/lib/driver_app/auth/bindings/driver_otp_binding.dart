import 'package:get/get.dart';
import '../controllers/driver_otp_controller.dart';

class DriverOtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverOtpController>(() => DriverOtpController());
  }
}
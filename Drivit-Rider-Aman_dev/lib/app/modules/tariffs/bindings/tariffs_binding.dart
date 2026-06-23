import 'package:get/get.dart';
import '../controllers/tariffs_controller.dart';

class TariffsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TariffsController>(() => TariffsController());
  }
}

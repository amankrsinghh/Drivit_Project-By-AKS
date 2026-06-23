import 'package:get/get.dart';

import '../controllers/package_controller.dart';


class PackagesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PackagesController>(() => PackagesController(), fenix: true);
  }
}
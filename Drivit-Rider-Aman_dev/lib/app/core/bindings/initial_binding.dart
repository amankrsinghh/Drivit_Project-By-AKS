import 'package:get/get.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';
import '../services/network_service.dart';
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core Services
    Get.put(NotificationService(), permanent: true);
    Get.put(SocketService(), permanent: true);
    Get.put(NetworkService(), permanent: true);
  }
}

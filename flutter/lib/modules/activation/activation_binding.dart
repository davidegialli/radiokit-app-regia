import 'package:get/get.dart';
import 'activation_controller.dart';

class ActivationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ActivationController(), fenix: true);
  }
}

import 'package:get/get.dart';
import 'on_air_controller.dart';

class OnAirBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => OnAirController(), fenix: true);
  }
}

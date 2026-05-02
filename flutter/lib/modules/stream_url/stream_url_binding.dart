import 'package:get/get.dart';
import 'stream_url_controller.dart';

class StreamUrlBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StreamUrlController(), fenix: true);
  }
}

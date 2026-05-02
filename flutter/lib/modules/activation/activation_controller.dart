import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/ws_service.dart';
import '../../shared/widgets/rk_toast.dart';

class ActivationController extends GetxController {
  final keyText = ''.obs;
  final loading = false.obs;
  final error = RxnString();

  bool get isKeyValid => AppConstants.keyRegex.hasMatch(keyText.value.trim().toUpperCase());

  Future<void> activate() async {
    final k = keyText.value.trim().toUpperCase();
    if (!AppConstants.keyRegex.hasMatch(k)) {
      error.value = 'activation.invalidKey'.tr;
      return;
    }
    loading.value = true;
    error.value = null;
    try {
      final r = await ApiService.to.activate(k);
      final token = r['token'] as String?;
      if (token == null || token.isEmpty) throw Exception('Missing token');

      final storage = StorageService.to;
      storage.licenseKey = k;
      storage.jwt        = token;
      storage.radioId    = r['radio_id'] as String?;
      storage.userName   = r['user_name'] as String?;
      storage.services   = ((r['services'] as List?)?.cast<String>()) ?? const [];

      final bridges = ((r['bridges_online'] as List?)?.cast<String>()) ?? const [];
      if (bridges.isEmpty) {
        error.value = 'activation.noBridge'.tr;
        return;
      }

      await WsService.to.connect();
      RkToast.show('activation.bridgeFound'.tr, kind: RkToastKind.success);
      Get.offAllNamed(AppRoutes.shell);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}

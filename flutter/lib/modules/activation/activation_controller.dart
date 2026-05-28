import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/api_service.dart';
import '../../core/services/status_service.dart';
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
      StatusService.to.start();
      RkToast.show('activation.bridgeFound'.tr, kind: RkToastKind.success);
      Get.offAllNamed(AppRoutes.shell);
    } on DioException catch (e) {
      // Server ha risposto con stato HTTP non-2xx ma corpo JSON strutturato
      // (es. {"ok":false, "error":"key_expired", "message":"Beta scaduta."})
      final data = e.response?.data;
      String? serverMsg;
      String? serverCode;
      if (data is Map) {
        serverMsg  = data['message']?.toString();
        serverCode = data['error']?.toString();
      }
      // Mapping codici noti → chiavi i18n locali (se disponibili)
      String? i18nKey;
      switch (serverCode) {
        case 'key_expired':     i18nKey = 'activation.keyExpired'; break;
        case 'not_approved':    i18nKey = 'activation.notApproved'; break;
        case 'invalid_key_format':
        case 'wrong_product':
        case 'not_found':       i18nKey = 'activation.invalidKey'; break;
      }
      String msg;
      if (i18nKey != null) {
        final t = i18nKey.tr;
        msg = (t == i18nKey) ? (serverMsg ?? i18nKey) : t; // fallback se i18n manca
      } else if (serverMsg != null && serverMsg.isNotEmpty) {
        msg = serverMsg;
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.connectionError) {
        msg = 'activation.networkError'.tr;
      } else {
        msg = 'activation.genericError'.tr;
      }
      error.value = msg;
    } catch (e) {
      error.value = 'activation.genericError'.tr;
    } finally {
      loading.value = false;
    }
  }
}

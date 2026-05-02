import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../constants/app_constants.dart';
import 'storage_service.dart';

/// REST client verso il VPS RadioKit.
/// Tutti gli endpoint sono sotto /api/regia/*.
/// L'auth è via JWT ottenuto al momento dell'attivazione con la chiave RKR-.
class ApiService extends GetxService {
  static ApiService get to => Get.find<ApiService>();

  late final Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opt, h) {
        final t = StorageService.to.jwt;
        if (t != null && t.isNotEmpty) opt.headers['Authorization'] = 'Bearer $t';
        return h.next(opt);
      },
    ));
  }

  /// Attivazione con chiave RKR-XXXX-XXXX-XXXX.
  /// Risposta attesa: { token, radio_id, services: [...], user_name, bridges_online: [...] }
  Future<Map<String, dynamic>> activate(String key) async {
    final r = await _dio.post('/auth', data: {'key': key});
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Stato globale (now playing, listener, bridge attivi).
  Future<Map<String, dynamic>> status() async {
    final r = await _dio.get('/status');
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Lancia diretta da URL stream esterno.
  /// Body: { url, title, host?, duration_min?, start_mode, auto_fallback }
  Future<Map<String, dynamic>> streamUrlStart(Map<String, dynamic> body) async {
    final r = await _dio.post('/live/stream-url', data: body);
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> streamUrlStatus() async {
    final r = await _dio.get('/live/stream-url/status');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<void> streamUrlStop() async {
    await _dio.post('/live/stream-url/stop');
  }

  /// Probe URL sorgente prima di andare in onda.
  /// Risposta: { reachable: bool, content_type, codec?, bitrate? }
  Future<Map<String, dynamic>> probeStreamUrl(String url) async {
    final r = await _dio.post('/probe', data: {'url': url});
    return Map<String, dynamic>.from(r.data as Map);
  }
}

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

  /// Front-controller pattern (allineato a /api/timer/): single endpoint,
  /// action via query string. Tutti i metodi colpiscono `apiBaseUrl`.

  Future<Map<String, dynamic>> activate(String key) async {
    final r = await _dio.post('?action=auth', data: {'key': key});
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> status() async {
    final r = await _dio.get('?action=status');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> streamUrlStart(Map<String, dynamic> body) async {
    final r = await _dio.post('?action=stream_url_start', data: body);
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> streamUrlStatus() async {
    final r = await _dio.get('?action=stream_url_status');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<void> streamUrlStop() async {
    await _dio.post('?action=stream_url_stop');
  }

  Future<Map<String, dynamic>> probeStreamUrl(String url) async {
    final r = await _dio.post('?action=probe', data: {'url': url});
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Invia un comando generico al bridge (handler in radiokit_regia_bridge.py).
  /// Ritorna `{command_id, status:'pending'}`.
  Future<Map<String, dynamic>> cmdSend(String type, [Map<String, dynamic>? payload]) async {
    final r = await _dio.post('?action=cmd', data: {
      'type': type,
      if (payload != null) 'payload': payload,
    });
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Polling esito comando: usato dal pattern "conferma reale".
  /// Risponde 404 con {ok:false, error:not_found} se l'id non esiste.
  Future<Map<String, dynamic>> cmdResult(String commandId) async {
    try {
      final r = await _dio.get('?action=cmd_result&id=$commandId');
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      rethrow;
    }
  }
}

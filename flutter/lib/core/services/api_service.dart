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

  /// Stats listener server-side (popolate dal poller cron VPS).
  /// Ritorna {streams:[{url,name,type,last_listeners,...}], listeners_now}.
  Future<Map<String, dynamic>> statsStreams() async {
    final r = await _dio.get('?action=stats_streams');
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Storico realtime: snapshot 30s, ultimi N minuti (default 60).
  Future<Map<String, dynamic>> statsRealtime({int minutes = 60}) async {
    final r = await _dio.get('?action=stats_realtime&minutes=$minutes');
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Aggregato hourly (24h/7d) o daily (30d/90d).
  Future<Map<String, dynamic>> statsHistory({String range = '7d', int? streamId}) async {
    var path = '?action=stats_history&range=$range';
    if (streamId != null) path += '&stream=$streamId';
    final r = await _dio.get(path);
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// KPI sintetici: now, 24h avg/peak, 7d avg/peak.
  Future<Map<String, dynamic>> statsSummary() async {
    final r = await _dio.get('?action=stats_summary');
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

  /// Upload audio (parlato registrato o jingle file) al VPS.
  /// `kind`: 'voice' | 'jingle'
  /// `mode`: 'now' | 'endtrack' | 'fade'
  /// Ritorna {file_id, command_id, size_bytes, ...}.
  /// Il VPS automaticamente accoda `playlist.insert_audio` per il bridge.
  Future<Map<String, dynamic>> audioUpload({
    required String filePath,
    required String filename,
    required String kind,
    required String mode,
    bool normalize = true,
    bool denoise = false,
    double gainDb = 0.0,
    String? title,
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(filePath, filename: filename),
      'kind': kind,
      'mode': mode,
      'normalize': normalize ? '1' : '0',
      'denoise': denoise ? '1' : '0',
      // gain in dB con 1 decimale; il server lo applica solo se != 0
      'gain_db': gainDb.toStringAsFixed(1),
      if (title != null && title.isNotEmpty) 'title': title,
    });
    final r = await _dio.post(
      '?action=audio_upload',
      data: form,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      onSendProgress: onProgress,
    );
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

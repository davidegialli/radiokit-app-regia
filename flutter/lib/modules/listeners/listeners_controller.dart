import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/services/api_service.dart';
import '../../core/services/status_service.dart';

/// Controller del tab Streaming (ex Listeners).
/// Carica la lista degli stream OUTPUT configurati nel Timer (tab
/// Trasmissione) via cmd `monitor.streams_preset` + cmd_result polling.
///
/// La lista contiene gli URL pubblici (icecast/shoutcast/HLS) verso cui
/// si connettono gli ascoltatori — non gli URL sorgente per il relay
/// (quelli stanno nella tab Diretta come "recents").
///
/// Stats per-stream individuali (count/peak/bitrate per ogni stream) sono
/// in arrivo: richiedono il bridge handler `monitor.listener_stats` non
/// ancora implementato. Per ora mostriamo l'aggregato globale di
/// /status sopra alla lista.
class ListenersController extends GetxController {
  static ListenersController get to => Get.find<ListenersController>();

  // Lista stream output configurati: [{url, label, type, primary}]
  final streams = <Map<String, dynamic>>[].obs;
  final loading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadStreams();
  }

  Future<void> loadStreams() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      // Bridge offline → niente preset disponibili
      if (!StatusService.to.bridgeOnline) {
        loading.value = false;
        return;
      }
      final sent = await ApiService.to.cmdSend('monitor.streams_preset', const {});
      final cid = sent['command_id']?.toString();
      if (cid == null || cid.isEmpty) return;

      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 800));
        final r = await ApiService.to.cmdResult(cid);
        final st = (r['status'] ?? '').toString();
        if (st == 'done') {
          final result = r['result'];
          if (result is Map && result['presets'] is List) {
            final list = (result['presets'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .where((e) => (e['url'] ?? '').toString().isNotEmpty)
                .toList();
            streams.assignAll(list);
          }
          return;
        }
        if (st == 'failed') {
          error.value = (r['error'] ?? '').toString();
          return;
        }
      }
      // timeout
      error.value = 'timeout';
    } on DioException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}

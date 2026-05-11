import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/services/api_service.dart';
import '../../core/services/status_service.dart';

/// Controller del tab Streaming (ex Listeners).
///
/// Legge stats listener direttamente dall'API VPS (`stats_streams`)
/// alimentata da poller cron server-side ogni 30s. Non più via bridge
/// locale → meno carico sul PC della regia + dati sempre disponibili
/// anche se il bridge è offline o Timer è chiuso.
///
/// Fallback graceful: se l'endpoint VPS non risponde (deploy vecchio
/// API), prova ancora il vecchio path bridge `monitor.listener_stats`.
class ListenersController extends GetxController {
  static ListenersController get to => Get.find<ListenersController>();

  // Lista stream output configurati con stats realtime:
  // [{url, label, type, primary, online, listeners, peak, bitrate, codec, title}]
  final streams = <Map<String, dynamic>>[].obs;
  final totalListeners = RxnInt();
  final loading = false.obs;
  final error = RxnString();

  // Polling ogni 15s per refresh stats. UX percepita fresca senza
  // saturare il bridge (4 stream * 1 cmd / 15s = OK).
  static const _pollInterval = Duration(seconds: 15);
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    loadStreams();
    _timer = Timer.periodic(_pollInterval, (_) => loadStreams(silent: true));
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// Carica la lista stream + stats listener real-time.
  /// Primary path: API VPS `stats_streams` (server-side poller).
  /// Fallback path: bridge cmd `monitor.listener_stats` (deploy vecchio).
  Future<void> loadStreams({bool silent = false}) async {
    if (loading.value) return;
    if (!silent) loading.value = true;
    error.value = null;

    bool ok = false;

    // 1) Primary: API VPS server-side
    try {
      final r = await ApiService.to.statsStreams();
      if (r['ok'] == true && r['streams'] is List) {
        final list = (r['streams'] as List)
            .whereType<Map>()
            .map((m) {
              final mm = Map<String, dynamic>.from(m);
              // Normalizza il campo per la UI: 'listeners' (vs last_listeners)
              mm['listeners'] = mm['last_listeners'] ?? mm['listeners'] ?? 0;
              mm['online'] = mm['last_poll_ok'] == 1 || mm['last_poll_ok'] == true;
              mm['label']  = mm['name'] ?? mm['label'] ?? mm['url'];
              return mm;
            })
            .where((e) => (e['url'] ?? '').toString().isNotEmpty)
            .toList();
        streams.assignAll(list);
        final tot = r['listeners_now'];
        totalListeners.value = tot is int ? tot : null;
        ok = true;
      }
    } on DioException catch (e) {
      // VPS API 404 / offline → fallback bridge
      error.value = e.message;
    } catch (e) {
      error.value = e.toString();
    }

    // 2) Fallback bridge (legacy)
    if (!ok && StatusService.to.bridgeOnline) {
      final got = await _callCmd('monitor.listener_stats');
      if (got != null && got['streams'] is List) {
        final list = (got['streams'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => (e['url'] ?? '').toString().isNotEmpty)
            .toList();
        streams.assignAll(list);
        final tot = got['total_listeners'];
        totalListeners.value = tot is int ? tot : null;
      }
    }

    if (!silent) loading.value = false;
  }

  /// Manda un cmd al bridge e polla cmd_result. Ritorna result se done,
  /// null se failed/timeout/error.
  Future<Map<String, dynamic>?> _callCmd(String type) async {
    try {
      final sent = await ApiService.to.cmdSend(type, const {});
      final cid = sent['command_id']?.toString();
      if (cid == null || cid.isEmpty) return null;
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 800));
        final r = await ApiService.to.cmdResult(cid);
        final st = (r['status'] ?? '').toString();
        if (st == 'done') {
          final result = r['result'];
          if (result is Map) return Map<String, dynamic>.from(result);
          return null;
        }
        if (st == 'failed') return null;
      }
      return null;
    } on DioException catch (e) {
      error.value = e.message;
      return null;
    } catch (e) {
      error.value = e.toString();
      return null;
    }
  }
}

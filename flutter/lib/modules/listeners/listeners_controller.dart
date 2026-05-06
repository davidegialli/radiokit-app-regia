import 'dart:async';

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

  /// Carica la lista stream + stats realtime (count, peak, bitrate per
  /// ogni stream). Usa il bridge handler `monitor.listener_stats`.
  /// Fallback graceful: se l'handler non risponde (Timer non aggiornato),
  /// usa `monitor.streams_preset` per avere almeno la lista metadata.
  Future<void> loadStreams({bool silent = false}) async {
    if (loading.value) return;
    if (!StatusService.to.bridgeOnline) {
      // Bridge offline: tieni la lista corrente, niente reset
      return;
    }
    if (!silent) loading.value = true;
    error.value = null;

    // listener_stats ritorna gia' tutti i campi necessari (url, label, type,
    // primary, online, listeners, peak, bitrate, codec) — niente fallback
    // a streams_preset (era duplicato pre-deploy nuovo bridge).
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

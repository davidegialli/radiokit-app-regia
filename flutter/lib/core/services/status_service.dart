import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../data/models/regia_status.dart';
import 'api_service.dart';

/// Servizio singleton: polla /api/regia/?action=status ogni 4s e mantiene
/// uno snapshot reattivo + un buffer rotativo della storia listener.
///
/// Tutti i tab (Home, Listener, Stream) leggono da qui — single source of
/// truth condivisa, evita N polling indipendenti dello stesso endpoint.
///
/// NOTA: lo StreamUrlController di oggi mantiene il SUO polling separato
/// per non rischiare regressioni su quello che e' in test in produzione.
/// Lo unificheremo in una passata futura, una volta validato questo.
class StatusService extends GetxService {
  static StatusService get to => Get.find<StatusService>();

  static const _pollInterval = Duration(seconds: 4);
  static const _historyMax = 60; // ~4 minuti a 4s di intervallo

  final status = RegiaStatus.unknown.obs;
  final lastError = RxnString();

  /// Ring buffer dei sample listener (più recenti in coda).
  /// Solo valori interi non-null sono pushati.
  final ListQueue<int> _listenerHistory = ListQueue<int>(_historyMax);
  final listenerHistory = <int>[].obs;

  Timer? _timer;
  bool _started = false;
  // Histeresi: servono N offline consecutivi per flippare lo stato a offline.
  // Evita flicker quando il bridge salta un singolo heartbeat (soglia VPS = 30s).
  static const _offlineDebounce = 2;
  int _consecOffline = 0;

  void start() {
    if (_started) return;
    _started = true;
    refresh();
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  Future<void> refresh() async {
    try {
      final raw = await ApiService.to.status();
      if (raw['ok'] == false) return;
      final next = RegiaStatus.fromJson(raw);

      // Histeresi: ignora un singolo poll offline isolato (flicker dovuto a
      // VPS threshold 30s + occasionale skip heartbeat). Servono N offline
      // consecutivi per flippare; se ne arriva anche uno solo non-offline,
      // resettiamo il counter.
      if (next.appState == RegiaAppState.offline) {
        _consecOffline++;
        if (_consecOffline < _offlineDebounce && status.value.appState != RegiaAppState.offline) {
          // Manteniamo lo stato precedente, ma aggiorniamo gli altri campi
          // (now_playing, listeners, ecc.) che potrebbero comunque essere validi
          // dal precedente snapshot. In pratica: skip questo update offline.
          return;
        }
      } else {
        _consecOffline = 0;
      }

      status.value = next;
      lastError.value = null;
      if (next.listeners != null) {
        if (_listenerHistory.length >= _historyMax) _listenerHistory.removeFirst();
        _listenerHistory.addLast(next.listeners!);
        listenerHistory.assignAll(_listenerHistory);
      }
    } on DioException catch (e) {
      lastError.value = e.message;
    } catch (_) {}
  }

  // ── Helpers per UI ───────────────────────────────────────────────

  bool get bridgeOnline {
    final s = status.value;
    if (s.bridgesOnline.isEmpty) return false;
    final age = s.bridgeAgeSec;
    return age != null && age <= 30;
  }

  /// Trend rapido: media degli ultimi 5 sample vs i precedenti 5.
  /// 0 = stabile, 1 = up, -1 = down. null se dati insufficienti.
  int? get listenerTrend {
    final h = _listenerHistory.toList();
    if (h.length < 10) return null;
    final recent = h.sublist(h.length - 5);
    final prev   = h.sublist(h.length - 10, h.length - 5);
    final ra = recent.reduce((a, b) => a + b) / recent.length;
    final pa = prev.reduce((a, b) => a + b) / prev.length;
    if (ra > pa * 1.05) return 1;
    if (ra < pa * 0.95) return -1;
    return 0;
  }

  /// Peak in tutto il buffer (sessione corrente).
  int? get listenerPeak {
    if (_listenerHistory.isEmpty) return null;
    return _listenerHistory.reduce((a, b) => a > b ? a : b);
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/regia_command.dart';
import '../../data/models/regia_status.dart';
import '../../shared/widgets/rk_toast.dart';

/// Controller del tab Stream — backend REST polling architecture.
///
/// Single source of truth = `/status`:
/// - app_state ∈ {unknown, offline, idle, requested, scheduled, live, error}
/// - now_playing reale da RadioBOSS (via heartbeat bridge)
/// - session attiva (se c'è)
///
/// Pattern "conferma reale" (richiesto da progettazione):
/// 1) tap "Vai in onda" → POST /stream_url_start → command_id
/// 2) UI passa a `requested`
/// 3) polling /cmd_result?id=X ogni 2s finché status=done|failed
/// 4) /status ritorna app_state aggiornato (scheduled o live)
/// 5) toast "✅ Diretta avviata" UNA VOLTA SOLA al passaggio a `live`
class StreamUrlController extends GetxController {
  static StreamUrlController get to => Get.find<StreamUrlController>();

  // ── Form (TextEditingController + mirror reattivo) ─────────────────
  final urlCtrl   = TextEditingController(text: 'https://encoder.miosito.com:8000/live');
  final titleCtrl = TextEditingController();
  final hostCtrl  = TextEditingController();

  final url        = 'https://encoder.miosito.com:8000/live'.obs;
  final title      = ''.obs;
  final host       = ''.obs;
  final duration   = '120'.obs; // minuti, '0' = manuale
  final startMode  = StartMode.endtrack.obs;
  final autoFallback = true.obs;

  // ── Stato runtime (da /status) ─────────────────────────────────────
  final status = RegiaStatus.unknown.obs;
  final loading = false.obs; // POST /stream_url_start in corso
  final localError = RxnString();

  // ── Recenti URL sorgente (last N URLs lanciati con successo) ───────
  // NB: NON sono gli stream output icecast/shoutcast (quelli stanno nella
  // tab Streaming/Listener). Qui sono URL SORGENTE per il relay esterno
  // (encoder, evento esterno, radio partner).
  static const _recentsMax = 5;
  static const _recentsKey = 'rkr_stream_recents';
  final recents = <String>[].obs;

  // ── Polling timers ─────────────────────────────────────────────────
  Timer? _statusTimer;
  RegiaAppState _lastSeenState = RegiaAppState.unknown;
  bool _liveToastShown = false;

  // ── Getter di comodo per la UI ─────────────────────────────────────
  RegiaAppState get appState => status.value.appState;
  bool get isLive       => appState == RegiaAppState.live;
  bool get isWaiting    => appState == RegiaAppState.requested
                       || appState == RegiaAppState.scheduled;
  bool get isOffline    => appState == RegiaAppState.offline;
  bool get isIdle       => appState == RegiaAppState.idle;
  bool get isError      => appState == RegiaAppState.error;
  bool get formLocked   => isLive || isWaiting || loading.value;

  bool get canStart {
    if (formLocked || !isIdle) return false;
    final u = url.value.trim();
    if (!RegExp(r'^https?:\/\/[^\s]+', caseSensitive: false).hasMatch(u)) return false;
    return title.value.trim().isNotEmpty;
  }

  // Elapsed locale, calcolato dal session.started_at del backend
  int get elapsedSec {
    final s = status.value.session;
    if (s == null) return 0;
    final started = DateTime.tryParse(s['started_at']?.toString() ?? '');
    if (started == null) return 0;
    return DateTime.now().toUtc().difference(started.toUtc()).inSeconds;
  }

  int? get sessionDurationMin {
    final v = status.value.session?['duration_min'];
    return v is int ? v : null;
  }

  String? get sessionTitle => status.value.session?['title']?.toString();

  // ── Lifecycle ──────────────────────────────────────────────────────
  void _wireText() {
    urlCtrl.addListener(()   => url.value   = urlCtrl.text);
    titleCtrl.addListener(() => title.value = titleCtrl.text);
    hostCtrl.addListener(()  => host.value  = hostCtrl.text);
  }

  @override
  void onInit() {
    super.onInit();
    _wireText();
    _loadRecents();
    _refreshStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refreshStatus());
  }

  @override
  void onClose() {
    _statusTimer?.cancel();
    urlCtrl.dispose();
    titleCtrl.dispose();
    hostCtrl.dispose();
    super.onClose();
  }

  // ── Polling /status ────────────────────────────────────────────────
  Future<void> _refreshStatus() async {
    try {
      final raw = await ApiService.to.status();
      if (raw['ok'] == false) return;
      final next = RegiaStatus.fromJson(raw);
      _onNewStatus(next);
    } on DioException {
      // network down → manteniamo l'ultimo stato; UI mostrerà bridge_age stale
    } catch (_) {}
  }

  void _onNewStatus(RegiaStatus next) {
    final prev = _lastSeenState;
    status.value = next;
    _lastSeenState = next.appState;

    // Toast "Diretta avviata" UNA VOLTA SOLA quando si entra in live
    if (next.appState == RegiaAppState.live && prev != RegiaAppState.live && !_liveToastShown) {
      _liveToastShown = true;
      final t = sessionTitle ?? title.value;
      RkToast.show(
        'stream.toast.live'.tr.replaceAll('@title', t),
        kind: RkToastKind.success,
      );
    }
    // Reset toast flag quando si esce dalla diretta
    if (next.appState == RegiaAppState.idle && prev != RegiaAppState.idle) {
      _liveToastShown = false;
    }
  }

  // ── Azione: Vai in onda ────────────────────────────────────────────
  Future<void> start() async {
    if (!canStart) return;
    loading.value = true;
    localError.value = null;
    try {
      final dMin = duration.value == '0' ? null : int.tryParse(duration.value);
      final urlClean = url.value.trim();
      await ApiService.to.streamUrlStart({
        'url': urlClean,
        'title': title.value.trim(),
        if (host.value.trim().isNotEmpty) 'host': host.value.trim(),
        if (dMin != null) 'duration_min': dMin,
        'start_mode': startMode.value.wireName,
        'auto_fallback': autoFallback.value,
      });

      // Salva URL in recents locali (utile per quick-select alla prossima diretta)
      _addToRecents(urlClean);

      // Il /stream_url_start non ritorna command_id del bridge_command,
      // ritorna session_id. Per la "conferma reale" basta osservare /status:
      // appena il bridge picka e ack-a, app_state passa a 'scheduled' o 'live'.
      // Forziamo subito un refresh per accelerare la transizione → 'requested'.
      _liveToastShown = false;
      await _refreshStatus();

      // Se la chiamata ritorna senza errore ma /status è ancora idle,
      // significa che il bridge non ha ancora pollato → mostriamo intanto
      // lo stato 'requested' lato client come hint ottimistico.
      if (status.value.appState == RegiaAppState.idle) {
        status.value = RegiaStatus(
          appState: RegiaAppState.requested,
          bridgesOnline: status.value.bridgesOnline,
          bridgeAgeSec: status.value.bridgeAgeSec,
          nowPlaying: status.value.nowPlaying,
          listeners: status.value.listeners,
          relayActive: status.value.relayActive,
          live: false,
          session: status.value.session,
          serverTime: status.value.serverTime,
        );
      }
      // Continua il polling normale, il vero stato vince
    } on DioException catch (e) {
      localError.value = _extractErr(e);
      RkToast.show('stream.toast.failed'.tr, kind: RkToastKind.error);
    } catch (e) {
      localError.value = e.toString();
      RkToast.show('stream.toast.failed'.tr, kind: RkToastKind.error);
    } finally {
      loading.value = false;
    }
  }

  // ── Recents: persistenza locale via GetStorage ──────────────────────
  void _loadRecents() {
    try {
      final raw = StorageService.to.read<List>(_recentsKey) ?? const [];
      recents.assignAll(raw.cast<String>());
    } catch (_) {}
  }

  void _saveRecents() {
    try {
      StorageService.to.write(_recentsKey, recents.toList());
    } catch (_) {}
  }

  void _addToRecents(String url) {
    final u = url.trim();
    if (u.isEmpty) return;
    recents.remove(u);                // sposta in cima se già presente
    recents.insert(0, u);
    while (recents.length > _recentsMax) {
      recents.removeLast();
    }
    _saveRecents();
  }

  /// Tap su un recente → riempie il form URL.
  void applyRecent(String url) {
    if (formLocked) return;
    urlCtrl.text = url;
    this.url.value = url;
  }

  void clearRecents() {
    recents.clear();
    _saveRecents();
  }

  // ── Azione: Stop ──────────────────────────────────────────────────
  Future<void> stop() async {
    if (isIdle || isOffline) return;
    loading.value = true;
    try {
      await ApiService.to.streamUrlStop();
      // Refresh immediato; il bridge ack arriverà al prossimo poll
      await _refreshStatus();
      RkToast.show('stream.toast.stopped'.tr);
    } on DioException catch (e) {
      localError.value = _extractErr(e);
    } finally {
      loading.value = false;
    }
  }

  String _extractErr(DioException e) {
    final d = e.response?.data;
    if (d is Map && d['message'] != null) return d['message'].toString();
    return e.message ?? 'error.network'.tr;
  }

  // Helper UI
  String fmtElapsed() {
    final s = elapsedSec;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${ss.toString().padLeft(2,'0')}';
  }

}

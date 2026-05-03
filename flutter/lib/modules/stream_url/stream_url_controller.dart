import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/services/api_service.dart';
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

  // ── Preset URL (caricati on-demand dal bridge) ─────────────────────
  // Format: [{url:String, label:String, primary:bool}]
  final presets = <Map<String, dynamic>>[].obs;
  final presetsLoading = false.obs;

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
    _refreshStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refreshStatus());
    // Carica i preset in background dopo il primo /status (non bloccante).
    Future.delayed(const Duration(seconds: 1), loadPresets);
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
      await ApiService.to.streamUrlStart({
        'url': url.value.trim(),
        'title': title.value.trim(),
        if (host.value.trim().isNotEmpty) 'host': host.value.trim(),
        if (dMin != null) 'duration_min': dMin,
        'start_mode': startMode.value.wireName,
        'auto_fallback': autoFallback.value,
      });

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

  // ── Preset URL: invia comando + polla esito ─────────────────────────
  Future<void> loadPresets({bool silent = true}) async {
    if (presetsLoading.value || isOffline) return;
    presetsLoading.value = true;
    try {
      final sent = await ApiService.to.cmdSend('monitor.streams_preset', const {});
      final cid = sent['command_id']?.toString();
      if (cid == null || cid.isEmpty) return;

      // Polling fino a done/failed (max 8s — bridge polla ogni 5s)
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
            presets.assignAll(list);
          }
          return;
        }
        if (st == 'failed') return;
      }
    } catch (_) {
      if (!silent) RkToast.show('error.network'.tr, kind: RkToastKind.error);
    } finally {
      presetsLoading.value = false;
    }
  }

  /// Tap su un preset → riempie il form URL.
  void applyPreset(String url) {
    if (formLocked) return;
    urlCtrl.text = url;
    this.url.value = url;
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

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/services/api_service.dart';
import '../../shared/widgets/rk_toast.dart';

/// Controller del tab On Air.
/// Tutti i comandi vanno via /api/regia/?action=cmd → bridge handlers
/// playlist.* (skip/prev/play/pause/stop/volume).
/// Lo stato now_playing arriva dal StatusService condiviso.
class OnAirController extends GetxController {
  static OnAirController get to => Get.find<OnAirController>();

  final volume = 80.obs;
  final sending = ''.obs; // nome dell'azione in invio (per disabilitare i bottoni)

  // Coda playlist: prossime N tracce parsate da playlist.next_tracks
  // Ogni item: {pos, title, artist, filename, duration, is_url}
  final queue = <Map<String, dynamic>>[].obs;
  final queueLoading = false.obs;

  Timer? _volumeDebounce;
  Timer? _queueTimer;

  @override
  void onInit() {
    super.onInit();
    loadQueue();
    // Refresh ogni 30s (era 20). Il polling singolo puo' durare fino a 20s,
    // serve margine per non sovrapporre chiamate.
    _queueTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadQueue(silent: true),
    );
  }

  @override
  void onClose() {
    _volumeDebounce?.cancel();
    _queueTimer?.cancel();
    super.onClose();
  }

  /// Carica le prossime 25 tracce in playlist da RB via bridge.
  /// Item: {pos, title, artist, filename, duration, is_url, category, color}
  Future<void> loadQueue({bool silent = false}) async {
    if (queueLoading.value) return;
    if (!silent) queueLoading.value = true;
    try {
      final sent = await ApiService.to.cmdSend(
          'playlist.next_tracks', {'cnt': 25});
      final cid = sent['command_id']?.toString();
      if (cid == null || cid.isEmpty) return;
      // Deadline 20s: il bridge sotto carico (queue ingorgata) puo'
      // impiegare 15-25s tra picked e ack. Era 6s e timeout-ava sempre,
      // app mostrava "coda vuota" anche se i tracks sarebbero arrivati.
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 700));
        final r = await ApiService.to.cmdResult(cid);
        final st = (r['status'] ?? '').toString();
        if (st == 'done') {
          final res = r['result'];
          if (res is Map && res['tracks'] is List) {
            queue.assignAll((res['tracks'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList());
          }
          return;
        }
        if (st == 'failed') return;
      }
    } catch (_) {} finally {
      if (!silent) queueLoading.value = false;
    }
  }

  /// Sposta una traccia dalla pos `from` alla pos `to`.
  /// L'utente trascina visivamente nella ReorderableListView, noi
  /// applichiamo subito sul bridge e ricarichiamo per conferma.
  Future<void> moveTrack(int from, int to) async {
    if (from == to) return;
    // Optimistic UI: riordino subito la lista locale
    if (from >= 0 && from < queue.length) {
      final item = queue.removeAt(from);
      final clampedTo = to.clamp(0, queue.length);
      queue.insert(clampedTo, item);
    }
    try {
      // RB usa pos 1-based: il pos del nostro item e' gia' 1-based (PT).
      await ApiService.to.cmdSend('playlist.move', {
        'from': from + 1,
        'to':   to   + 1,
      });
    } catch (_) {}
    // Ricarica per allineare con la realta' di RB
    Future.delayed(const Duration(milliseconds: 500), () => loadQueue(silent: true));
  }

  /// Elimina la traccia in posizione `index` (UI 0-based, RB 1-based).
  /// Optimistic update: rimuoviamo subito dalla lista locale e poi
  /// allineamo con il bridge. Se la chiamata fallisce, il loadQueue
  /// successivo ripristina lo stato vero di RadioBOSS.
  Future<void> deleteTrack(int index) async {
    if (index < 0 || index >= queue.length) return;
    queue.removeAt(index);
    try {
      await ApiService.to.cmdSend('playlist.delete', {
        'pos': index + 1,
      });
    } catch (_) {}
    Future.delayed(const Duration(milliseconds: 500), () => loadQueue(silent: true));
  }

  /// Manda comando + polla cmd_result finché 'done'/'failed' o timeout 8s.
  /// Il bottone resta in "in attesa…" fino al riscontro reale del bridge,
  /// non solo all'enqueue. Cosi' l'utente sa quando il comando e' davvero
  /// eseguito da RadioBOSS.
  Future<void> _send(String type, String label, [Map<String, dynamic>? payload]) async {
    if (sending.value.isNotEmpty) return;
    sending.value = label;
    try {
      final sent = await ApiService.to.cmdSend(type, payload);
      final cid = sent['command_id']?.toString();
      if (cid == null || cid.isEmpty) {
        // Niente command_id: ack immediato (legacy)
        RkToast.show('onair.toast.ack'.tr.replaceAll('@action', label).replaceAll('{action}', label));
        return;
      }
      // Polling esito: bridge picka ~ogni 1-3s + esegue + ack.
      // Timeout 8s e' sufficiente per la stragrande maggioranza dei comandi RB.
      final deadline = DateTime.now().add(const Duration(seconds: 8));
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 600));
        final r = await ApiService.to.cmdResult(cid);
        final st = (r['status'] ?? '').toString();
        if (st == 'done') {
          RkToast.show('onair.toast.ack'.tr.replaceAll('@action', label).replaceAll('{action}', label));
          return;
        }
        if (st == 'failed') {
          final err = (r['error'] ?? '').toString();
          RkToast.show(
            err.isEmpty ? 'onair.toast.fail'.tr : err,
            kind: RkToastKind.error);
          return;
        }
      }
      // Timeout senza risposta del bridge
      RkToast.show('onair.toast.fail'.tr, kind: RkToastKind.error);
    } on DioException {
      RkToast.show('onair.toast.fail'.tr, kind: RkToastKind.error);
    } catch (_) {
      RkToast.show('onair.toast.fail'.tr, kind: RkToastKind.error);
    } finally {
      sending.value = '';
    }
  }

  Future<void> skip()  => _send('playlist.skip',   'onair.skipNext'.tr);
  Future<void> prev()  => _send('playlist.prev',   'onair.prev'.tr);
  Future<void> play()  => _send('playlist.play',   'onair.play'.tr);
  Future<void> pause() => _send('playlist.pause',  'onair.pause'.tr);
  Future<void> stop()  => _send('playlist.stop',   'onair.stop'.tr);

  void onVolumeChanged(double v) {
    volume.value = v.round();
    _volumeDebounce?.cancel();
    _volumeDebounce = Timer(const Duration(milliseconds: 350), () {
      // fire-and-forget: il debounce evita di inondare il bridge mentre l'utente trascina
      ApiService.to.cmdSend('playlist.volume', {'volume': volume.value}).catchError((_) => <String, dynamic>{});
    });
  }
}

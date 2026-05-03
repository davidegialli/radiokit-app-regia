import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/services/api_service.dart';
import '../../shared/widgets/rk_toast.dart';

/// Controller del tab On Air.
/// Tutti i comandi vanno via /api/regia/?action=cmd → bridge handlers
/// playlist.* (skip/prev/play/pause/stop/volume/runevent).
/// Lo stato now_playing arriva dal StatusService condiviso.
class OnAirController extends GetxController {
  static OnAirController get to => Get.find<OnAirController>();

  final volume = 80.obs;
  final eventCtrl = TextEditingController();
  final eventName = ''.obs;
  final sending = ''.obs; // nome dell'azione in invio (per disabilitare i bottoni)

  Timer? _volumeDebounce;

  @override
  void onInit() {
    super.onInit();
    eventCtrl.addListener(() => eventName.value = eventCtrl.text);
  }

  @override
  void onClose() {
    _volumeDebounce?.cancel();
    eventCtrl.dispose();
    super.onClose();
  }

  Future<void> _send(String type, String label, [Map<String, dynamic>? payload]) async {
    if (sending.value.isNotEmpty) return;
    sending.value = label;
    try {
      await ApiService.to.cmdSend(type, payload);
      RkToast.show('onair.toast.ack'.tr.replaceAll('@action', label).replaceAll('{action}', label));
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

  Future<void> runEvent() async {
    final name = eventName.value.trim();
    if (name.isEmpty) return;
    await _send('playlist.jingle_eventname', '▶ $name', {'event': name});
  }
}

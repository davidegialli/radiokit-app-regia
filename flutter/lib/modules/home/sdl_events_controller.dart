import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/services/api_service.dart';
import '../../core/services/status_service.dart';

/// Controller per la card "Prossime dirette" della Home.
/// Polling cmd `monitor.sdl_events` ogni 60s (dati cambiano raramente,
/// non vale la pena pollarlo piu' spesso).
class SdlEventsController extends GetxController {
  static SdlEventsController get to => Get.find<SdlEventsController>();

  final events = <Map<String, dynamic>>[].obs;
  final loading = false.obs;
  final error = RxnString();

  static const _pollInterval = Duration(seconds: 60);
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    load();
    _timer = Timer.periodic(_pollInterval, (_) => load(silent: true));
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> load({bool silent = false}) async {
    if (loading.value) return;
    if (!StatusService.to.bridgeOnline) return;
    if (!silent) loading.value = true;
    error.value = null;

    try {
      final sent = await ApiService.to.cmdSend('monitor.sdl_events', const {
        'limit': 5,
        'only_future': true,
        'hours_window': 24,
      });
      final cid = sent['command_id']?.toString();
      if (cid == null || cid.isEmpty) return;

      final deadline = DateTime.now().add(const Duration(seconds: 8));
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 700));
        final r = await ApiService.to.cmdResult(cid);
        final st = (r['status'] ?? '').toString();
        if (st == 'done') {
          final result = r['result'];
          if (result is Map && result['events'] is List) {
            events.assignAll(
              (result['events'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
            );
          }
          return;
        }
        if (st == 'failed') {
          error.value = (r['error'] ?? '').toString();
          return;
        }
      }
    } on DioException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = e.toString();
    } finally {
      if (!silent) loading.value = false;
    }
  }
}

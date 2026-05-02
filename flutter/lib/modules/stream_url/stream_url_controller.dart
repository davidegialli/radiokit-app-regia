import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/ws_service.dart';
import '../../data/models/regia_command.dart';
import '../../data/models/stream_launch.dart';

class StreamUrlController extends GetxController {
  static StreamUrlController get to => Get.find<StreamUrlController>();

  // Text controllers (vivono come field nel GetXController, non vengono
  // ricreati a ogni Obx rebuild).
  final urlCtrl   = TextEditingController(text: 'https://encoder.miosito.com:8000/live');
  final titleCtrl = TextEditingController(text: 'Notte Italiana');
  final hostCtrl  = TextEditingController(text: 'Davide Gialli');

  // Form (mirror reattivo dei TextEditingController per validazione)
  final url        = 'https://encoder.miosito.com:8000/live'.obs;
  final title      = 'Notte Italiana'.obs;
  final host       = 'Davide Gialli'.obs;
  final duration   = '120'.obs;        // minuti, '0' = manuale
  final startMode  = StartMode.endtrack.obs;
  final autoFallback = true.obs;

  // Runtime
  final session = Rxn<StreamLaunchSession>();
  final probing = false.obs;

  // Telemetria
  final elapsedSec  = 0.obs;
  final bytesRcv    = 0.obs;
  final health      = StreamHealth.idle.obs;
  final srcCodec    = ''.obs;
  final srcBitrate  = ''.obs;

  Timer? _ticker;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  void _wireText() {
    urlCtrl.addListener(()   => url.value   = urlCtrl.text);
    titleCtrl.addListener(() => title.value = titleCtrl.text);
    hostCtrl.addListener(()  => host.value  = hostCtrl.text);
  }

  bool get isStreaming => session.value?.isLive ?? false;

  bool get canStart {
    if (isStreaming || probing.value) return false;
    final u = url.value.trim();
    if (!RegExp(r'^https?:\/\/[^\s]+', caseSensitive: false).hasMatch(u)) return false;
    return title.value.trim().isNotEmpty;
  }

  @override
  void onInit() {
    super.onInit();
    _wireText();
    _wsSub = WsService.to.events.listen(_onWsEvent);
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _wsSub?.cancel();
    urlCtrl.dispose();
    titleCtrl.dispose();
    hostCtrl.dispose();
    super.onClose();
  }

  void _onWsEvent(Map<String, dynamic> m) {
    if (m['type'] != 'stream_url.event') return;
    final p = (m['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    health.value = StreamHealthWire.fromWire(p['health'] as String? ?? 'idle');
    if (p['source_codec']   != null) srcCodec.value   = p['source_codec'].toString();
    if (p['source_bitrate'] != null) srcBitrate.value = '${p['source_bitrate']} kbps';
    if (p['bytes_received'] is int) bytesRcv.value = p['bytes_received'] as int;
  }

  Future<void> start() async {
    if (!canStart) return;
    probing.value = true;
    health.value = StreamHealth.probing;

    try {
      // 1. Probe URL sorgente — SOLO informativo, non bloccante.
      // Alcuni server bloccano HEAD requests ma servono lo stream regolarmente,
      // quindi l'unreachable può essere falso positivo. Proseguiamo sempre.
      try {
        final probe = await ApiService.to.probeStreamUrl(url.value.trim());
        if (probe['codec']   != null) srcCodec.value   = probe['codec'].toString();
        if (probe['bitrate'] != null) srcBitrate.value = '${probe['bitrate']} kbps';
      } catch (_) {
        // probe failed network — continua comunque
      }

      final radioId = StorageService.to.radioId ?? 'demo';
      final cmdId   = const Uuid().v4();
      final dMin    = duration.value == '0' ? null : int.tryParse(duration.value);

      // 2. POST REST per registrare il lancio (idempotente)
      await ApiService.to.streamUrlStart({
        'command_id': cmdId,
        'url': url.value.trim(),
        'title': title.value.trim(),
        if (host.value.trim().isNotEmpty) 'host': host.value.trim(),
        if (dMin != null) 'duration_min': dMin,
        'start_mode': startMode.value.wireName,
        'auto_fallback': autoFallback.value,
      });

      // 3. Inoltro su WSS al bridge Timer
      WsService.to.send(RegiaCommand.streamUrlStart(
        id: cmdId,
        radioId: radioId,
        url: url.value.trim(),
        title: title.value.trim(),
        host: host.value.trim().isEmpty ? null : host.value.trim(),
        durationMin: dMin,
        startMode: startMode.value,
        autoFallback: autoFallback.value,
      ));

      // 4. Avvia sessione locale + ticker telemetria
      session.value = StreamLaunchSession(
        id: cmdId,
        url: url.value.trim(),
        title: title.value.trim(),
        host: host.value.trim().isEmpty ? null : host.value.trim(),
        durationMin: dMin,
        startMode: startMode.value,
        autoFallback: autoFallback.value,
        startedAt: DateTime.now().toUtc(),
        health: StreamHealth.ok,
      );
      health.value = StreamHealth.ok;
      elapsedSec.value = 0;
      bytesRcv.value = 0;
      _startTicker();
    } finally {
      probing.value = false;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isStreaming) return;
      elapsedSec.value++;

      // Auto-stop a durata pianificata
      final dMin = session.value?.durationMin;
      if (dMin != null && elapsedSec.value >= dMin * 60) {
        stop();
      }
    });
  }

  Future<void> stop() async {
    _ticker?.cancel();
    final s = session.value;
    if (s == null) return;
    session.value = s.copyWith(endedAt: DateTime.now().toUtc());

    try {
      await ApiService.to.streamUrlStop();
    } catch (_) {}

    final radioId = StorageService.to.radioId ?? 'demo';
    WsService.to.send(RegiaCommand(
      id: const Uuid().v4(),
      radioId: radioId,
      type: CommandType.streamUrlStop,
    ));

    health.value = StreamHealth.idle;
    elapsedSec.value = 0;
  }

  String fmtElapsed() {
    final s = elapsedSec.value;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${ss.toString().padLeft(2,'0')}';
  }

  String fmtBytes() {
    final b = bytesRcv.value;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}

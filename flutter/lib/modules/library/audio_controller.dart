import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/api_service.dart';
import '../../core/services/status_service.dart';
import '../../shared/widgets/rk_toast.dart';

/// Tipo di audio gestito dalla tab.
enum AudioKind { voice, jingle }

/// Stato attuale della registrazione/picking.
enum AudioStage { idle, recording, ready, uploading, sent }

class AudioController extends GetxController {
  static AudioController get to => Get.find<AudioController>();

  // ── Sorgente attiva ─────────────────────────────────────────────────
  // L'utente sceglie kind in fase di "send", non al momento della cattura:
  // un parlato registrato puo' anche essere mandato come jingle se uno vuole.
  final kind = AudioKind.voice.obs;

  // Stage UX
  final stage = AudioStage.idle.obs;
  final recordingSec = 0.obs;
  final uploadProgress = 0.0.obs;
  final lastError = RxnString();

  // Audio file pronto da inviare (registrato o pickato)
  final filePath = RxnString();
  final fileName = RxnString();
  final fileSize = 0.obs;

  // Title (display name dato dall'utente — opzionale, fallback a fileName)
  final titleCtrl = TextEditingController();
  final title = ''.obs;

  // Settings
  final normalize = true.obs;

  // Storico ultimi invii (sessione corrente)
  // [{filename, kind, file_id, status, sent_at, error}]
  final history = <Map<String, dynamic>>[].obs;

  // Recorder (flutter_sound) + Player (audioplayers)
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderOpen = false;
  final AudioPlayer _player = AudioPlayer();
  Timer? _recTimer;
  StreamSubscription<RecordingDisposition>? _recProgress;

  // Livello audio in dB durante la registrazione (-60 = silenzio, 0 = clip)
  // Tipicamente la voce sta tra -30 e -6 dB.
  final recDb = (-60.0).obs;

  bool get hasFile => filePath.value != null;

  @override
  void onInit() {
    super.onInit();
    titleCtrl.addListener(() => title.value = titleCtrl.text);
  }

  @override
  void onClose() {
    _recTimer?.cancel();
    titleCtrl.dispose();
    _player.dispose();
    if (_recorderOpen) {
      _recorder.closeRecorder();
      _recorderOpen = false;
    }
    super.onClose();
  }

  // ── Registrazione mic via flutter_sound ────────────────────────────
  Future<void> _ensureRecorderOpen() async {
    if (_recorderOpen) return;
    await _recorder.openRecorder();
    // Subscription frequency = ogni quanto arrivano i sample dB (50ms = 20Hz).
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));
    _recorderOpen = true;
  }

  Future<void> startRecording() async {
    if (stage.value == AudioStage.recording) return;

    final perm = await Permission.microphone.request();
    if (!perm.isGranted) {
      lastError.value = 'audio.err.mic_perm'.tr;
      RkToast.show('audio.err.mic_perm'.tr, kind: RkToastKind.error);
      return;
    }

    try {
      await _ensureRecorderOpen();
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/voice_$ts.aac';

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );

      // Sottoscrivi al level meter dB
      _recProgress?.cancel();
      _recProgress = _recorder.onProgress?.listen((d) {
        // d.decibels è null se il device non lo supporta
        final db = d.decibels ?? -60.0;
        recDb.value = db.clamp(-60.0, 0.0);
      });

      filePath.value = path;
      fileName.value = 'voice_$ts.aac';
      stage.value = AudioStage.recording;
      recordingSec.value = 0;
      _recTimer?.cancel();
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingSec.value++;
        // Stop automatico a 5 minuti per evitare file enormi
        if (recordingSec.value >= 300) stopRecording();
      });
    } catch (e) {
      lastError.value = e.toString();
      RkToast.show('audio.err.rec_failed'.tr, kind: RkToastKind.error);
    }
  }

  Future<void> stopRecording() async {
    if (stage.value != AudioStage.recording) return;
    _recTimer?.cancel();
    _recProgress?.cancel();
    _recProgress = null;
    recDb.value = -60.0;
    try {
      final url = await _recorder.stopRecorder(); // url può essere il path
      final p = url ?? filePath.value;
      if (p != null) {
        filePath.value = p;
        final f = File(p);
        if (await f.exists()) fileSize.value = await f.length();
        stage.value = AudioStage.ready;
      } else {
        stage.value = AudioStage.idle;
      }
    } catch (e) {
      stage.value = AudioStage.idle;
      lastError.value = e.toString();
    }
  }

  Future<void> cancelRecording() async {
    _recTimer?.cancel();
    _recProgress?.cancel();
    _recProgress = null;
    recDb.value = -60.0;
    try {
      if (_recorder.isRecording) await _recorder.stopRecorder();
    } catch (_) {}
    final p = filePath.value;
    if (p != null) {
      try { await File(p).delete(); } catch (_) {}
    }
    filePath.value = null;
    fileName.value = null;
    fileSize.value = 0;
    recordingSec.value = 0;
    stage.value = AudioStage.idle;
  }

  // ── File picker ──────────────────────────────────────────────────────
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      if (f.path == null) return;
      // Limite app-side: 10MB (lo stesso limite del VPS)
      if (f.size > 10 * 1024 * 1024) {
        lastError.value = 'audio.err.too_large'.tr;
        RkToast.show('audio.err.too_large'.tr, kind: RkToastKind.error);
        return;
      }
      filePath.value = f.path;
      fileName.value = f.name;
      fileSize.value = f.size;
      stage.value = AudioStage.ready;
      // Pickando un file di solito si vuole jingle: switch automatico
      kind.value = AudioKind.jingle;
    } catch (e) {
      lastError.value = e.toString();
      RkToast.show('audio.err.pick_failed'.tr, kind: RkToastKind.error);
    }
  }

  // ── Preview ──────────────────────────────────────────────────────────
  Future<void> playPreview() async {
    final p = filePath.value;
    if (p == null) return;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(p));
    } catch (e) {
      lastError.value = e.toString();
    }
  }

  Future<void> stopPreview() async {
    try { await _player.stop(); } catch (_) {}
  }

  // ── Reset (dopo invio o annulla) ─────────────────────────────────────
  void reset() {
    final p = filePath.value;
    if (p != null) {
      // Best-effort delete locale (era nel temp dir o pickato)
      try { File(p).delete(); } catch (_) {}
    }
    filePath.value = null;
    fileName.value = null;
    fileSize.value = 0;
    recordingSec.value = 0;
    uploadProgress.value = 0;
    stage.value = AudioStage.idle;
    lastError.value = null;
    titleCtrl.clear();
    title.value = '';
  }

  // ── Send → upload VPS ────────────────────────────────────────────────
  /// Se [titleOverride] è null, usa `title.value` (textfield UI).
  Future<void> send({String? titleOverride}) async {
    final effectiveTitle = (titleOverride ?? title.value).trim();
    final p = filePath.value;
    final n = fileName.value;
    if (p == null || n == null) return;
    if (stage.value == AudioStage.uploading) return;

    if (!StatusService.to.bridgeOnline) {
      RkToast.show('audio.err.bridge_offline'.tr, kind: RkToastKind.error);
      return;
    }

    stage.value = AudioStage.uploading;
    uploadProgress.value = 0;
    lastError.value = null;

    final kindStr = kind.value == AudioKind.voice ? 'voice' : 'jingle';
    final entry = <String, dynamic>{
      'filename': n,
      'title': effectiveTitle.isEmpty ? null : effectiveTitle,
      'kind': kindStr,
      'sent_at': DateTime.now().toIso8601String(),
      'status': 'uploading',
    };
    history.insert(0, entry);

    try {
      final r = await ApiService.to.audioUpload(
        filePath: p,
        filename: n,
        kind: kindStr,
        mode: 'endtrack',
        normalize: normalize.value,
        title: effectiveTitle.isEmpty ? null : effectiveTitle,
        onProgress: (sent, total) {
          if (total > 0) uploadProgress.value = sent / total;
        },
      );

      entry['file_id'] = r['file_id'];
      entry['command_id'] = r['command_id'];
      entry['status'] = 'sent';
      history.refresh();

      stage.value = AudioStage.sent;

      // Toast con titolo brano corrente se disponibile
      final np = StatusService.to.status.value.nowPlaying;
      final ctx = (np != null && !np.isEmpty)
          ? '${np.artist} — ${np.title}'
          : 'audio.toast.queued_generic'.tr;
      RkToast.show(
        'audio.toast.queued'.tr.replaceAll('@track', ctx),
        kind: RkToastKind.success,
      );

      // Auto-reset dopo 2s
      Future.delayed(const Duration(seconds: 2), () {
        if (stage.value == AudioStage.sent) reset();
      });
    } on DioException catch (e) {
      entry['status'] = 'error';
      entry['error'] = _extractErr(e);
      history.refresh();
      lastError.value = entry['error'];
      stage.value = AudioStage.ready;
      RkToast.show('audio.toast.failed'.tr, kind: RkToastKind.error);
    } catch (e) {
      entry['status'] = 'error';
      entry['error'] = e.toString();
      history.refresh();
      lastError.value = e.toString();
      stage.value = AudioStage.ready;
      RkToast.show('audio.toast.failed'.tr, kind: RkToastKind.error);
    } finally {
      uploadProgress.value = 0;
    }
  }

  String _extractErr(DioException e) {
    final d = e.response?.data;
    if (d is Map) {
      final m = d['message'] ?? d['error'];
      if (m != null) return m.toString();
    }
    // Server può rispondere con string non-JSON (es. nginx 413, php fatal):
    // prova a estrarre json se è una stringa, altrimenti taglia a 80 char.
    if (d is String && d.isNotEmpty) {
      final trimmed = d.trim();
      if (trimmed.startsWith('{')) {
        try {
          final parsed = trimmed; // best-effort: non parsiamo, mostriamo trimmed
          return parsed.length > 120 ? '${parsed.substring(0, 120)}…' : parsed;
        } catch (_) {}
      }
      return trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed;
    }
    final code = e.response?.statusCode;
    if (code != null) return 'HTTP $code';
    return e.message ?? 'error.network'.tr;
  }

  // Helpers UI
  String fmtRecTime() {
    final s = recordingSec.value;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  String fmtSize() {
    final b = fileSize.value;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}

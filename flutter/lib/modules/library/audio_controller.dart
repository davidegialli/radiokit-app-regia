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
import 'voice_fx.dart';

/// Tipo di audio gestito dalla tab.
/// - voice  = parlato registrato dal mic (normalizzato lato server, serve nome)
/// - jingle = file audio pre-prodotto (file transfer puro)
/// - spot   = spot pubblicitario pre-prodotto (file transfer puro)
enum AudioKind { voice, jingle, spot }

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

  // Settings (solo voce). denoise/gain sono applicati ON-DEVICE (ffmpeg in app)
  // così l'anteprima riflette il risultato finale; normalize resta lato VPS
  // quando non ci sono altri effetti attivi.
  final normalize = true.obs;
  final denoise = false.obs;        // riduzione rumore di fondo (on-device)
  final gainDb = 0.0.obs;           // guadagno volume in dB, range -12..+12

  // Elaborazione on-device (riduzione rumore + volume) in corso
  final processing = false.obs;
  final _processedPath = RxnString();
  String _processedSig = '';

  // Preview playback state (per seek-bar)
  final previewPos = Duration.zero.obs;
  final previewDur = Duration.zero.obs;
  final previewPlaying = false.obs;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<PlayerState>? _stateSub;

  // Storico ultimi invii (sessione corrente)
  // [{filename, kind, file_id, status, sent_at, error}]
  final history = <Map<String, dynamic>>[].obs;

  // Recorder (flutter_sound) + Player (audioplayers)
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderOpen = false;
  final AudioPlayer _player = AudioPlayer();
  Timer? _recTimer;

  bool get hasFile => filePath.value != null;

  @override
  void onInit() {
    super.onInit();
    titleCtrl.addListener(() => title.value = titleCtrl.text);
    // Stream posizione/durata/stato del player per la seek-bar di preview.
    _posSub = _player.onPositionChanged.listen((d) => previewPos.value = d);
    _durSub = _player.onDurationChanged.listen((d) => previewDur.value = d);
    _stateSub = _player.onPlayerStateChanged
        .listen((s) => previewPlaying.value = s == PlayerState.playing);
    _completeSub = _player.onPlayerComplete.listen((_) {
      previewPlaying.value = false;
      previewPos.value = Duration.zero;
    });
  }

  @override
  void onClose() {
    _recTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _stateSub?.cancel();
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

  // ── Elaborazione on-device (riduzione rumore + volume) ───────────────
  /// True se ci sono effetti da applicare (solo sul parlato).
  bool get _fxActive =>
      kind.value == AudioKind.voice &&
      (denoise.value || gainDb.value.abs() >= 0.1);

  String _fxSig() =>
      '${filePath.value}|d=${denoise.value}|n=${normalize.value}|g=${gainDb.value.toStringAsFixed(1)}';

  /// Ritorna il path del file da riprodurre/inviare: quello elaborato se ci
  /// sono effetti attivi (con cache per firma), altrimenti il file originale.
  Future<String?> _ensureProcessed() async {
    final src = filePath.value;
    if (src == null) return null;
    if (!_fxActive) {
      _processedPath.value = null;
      _processedSig = '';
      return src;
    }
    final sig = _fxSig();
    if (_processedPath.value != null && _processedSig == sig) {
      return _processedPath.value;
    }
    processing.value = true;
    try {
      final tag = sig.hashCode.toUnsigned(32).toRadixString(16);
      final out = await VoiceFx.process(
        inputPath: src,
        denoise: denoise.value,
        normalize: normalize.value, // include loudnorm on-device se attivo
        gainDb: gainDb.value,
        tag: tag,
      );
      if (out != null) {
        _processedPath.value = out;
        _processedSig = sig;
        return out;
      }
      // Fallback al grezzo se ffmpeg fallisce
      lastError.value = 'audio.err.fx_failed'.tr;
      RkToast.show('audio.err.fx_failed'.tr, kind: RkToastKind.error);
      return src;
    } finally {
      processing.value = false;
    }
  }

  /// True se il file da inviare è già stato elaborato on-device (così il
  /// server NON deve ri-normalizzarlo).
  bool get processedOnDevice =>
      _fxActive && _processedPath.value != null;

  // ── Preview (play/pause/seek) ────────────────────────────────────────
  /// Toggle play/pausa. Riprende dalla posizione corrente se in pausa,
  /// altrimenti (ri)parte dall'inizio elaborando il file se servono effetti.
  Future<void> togglePreview() async {
    if (filePath.value == null) return;
    try {
      if (previewPlaying.value) {
        await _player.pause();
      } else if (previewPos.value > Duration.zero &&
                 previewPos.value < previewDur.value) {
        await _player.resume();
      } else {
        await playPreview();
      }
    } catch (e) {
      lastError.value = e.toString();
    }
  }

  Future<void> playPreview() async {
    final p = await _ensureProcessed(); // applica effetti on-device se attivi
    if (p == null) return;
    try {
      await _player.stop();
      previewPos.value = Duration.zero;
      await _player.play(DeviceFileSource(p));
    } catch (e) {
      lastError.value = e.toString();
    }
  }

  Future<void> stopPreview() async {
    try { await _player.stop(); } catch (_) {}
    previewPlaying.value = false;
    previewPos.value = Duration.zero;
  }

  Future<void> seekPreview(Duration to) async {
    try { await _player.seek(to); previewPos.value = to; } catch (_) {}
  }

  // ── Reset (dopo invio o annulla) ─────────────────────────────────────
  void reset() {
    final p = filePath.value;
    if (p != null) {
      // Best-effort delete locale (era nel temp dir o pickato)
      try { File(p).delete(); } catch (_) {}
    }
    final proc = _processedPath.value;
    if (proc != null && proc != p) {
      try { File(proc).delete(); } catch (_) {}
    }
    _processedPath.value = null;
    _processedSig = '';
    try { _player.stop(); } catch (_) {}
    filePath.value = null;
    fileName.value = null;
    fileSize.value = 0;
    recordingSec.value = 0;
    uploadProgress.value = 0;
    stage.value = AudioStage.idle;
    lastError.value = null;
    titleCtrl.clear();
    title.value = '';
    // Reset controlli audio + stato preview
    denoise.value = false;
    gainDb.value = 0.0;
    previewPos.value = Duration.zero;
    previewDur.value = Duration.zero;
    previewPlaying.value = false;
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

    final kindStr = switch (kind.value) {
      AudioKind.voice  => 'voice',
      AudioKind.jingle => 'jingle',
      AudioKind.spot   => 'spot',
    };

    // Elabora on-device (riduzione rumore + volume) se attivo; in caso di
    // errore ffmpeg si torna automaticamente al file grezzo.
    final sendPath = await _ensureProcessed() ?? p;
    final processedHere = processedOnDevice; // true → file mp3 già lavorato
    // Estensione reale del file inviato (mp3 se elaborato on-device).
    final sentExt = sendPath.contains('.')
        ? sendPath.substring(sendPath.lastIndexOf('.'))
        : (n.contains('.') ? n.substring(n.lastIndexOf('.')) : '');

    // Se l'utente ha dato un titolo, usalo anche come NOME FILE inviato: così
    // RadioBOSS lo mostra nella playlist (oltre al tag in onda gestito dal
    // bridge). Senza titolo resta il nome auto (voice_<ts> / file pickato),
    // ma con estensione coerente col file realmente inviato.
    final baseNoExt = n.contains('.') ? n.substring(0, n.lastIndexOf('.')) : n;
    String uploadName = processedHere ? '$baseNoExt$sentExt' : n;
    if (effectiveTitle.isNotEmpty) {
      final safe = effectiveTitle
          .replaceAll(RegExp(r'[^A-Za-z0-9 _\-.()À-ÿ]'), '_')
          .trim();
      if (safe.isNotEmpty) uploadName = '$safe$sentExt';
    }

    final entry = <String, dynamic>{
      'filename': uploadName,
      'title': effectiveTitle.isEmpty ? null : effectiveTitle,
      'kind': kindStr,
      'sent_at': DateTime.now().toIso8601String(),
      'status': 'uploading',
    };
    history.insert(0, entry);

    try {
      // Normalize SOLO per voce e SOLO se non già elaborato on-device
      // (riduzione rumore/volume includono il loudnorm quando attivi → il
      // server non deve ri-normalizzare). Jingle/spot: file transfer puro.
      final isVoice = kind.value == AudioKind.voice;
      final useNormalize = isVoice && normalize.value && !processedHere;
      final r = await ApiService.to.audioUpload(
        filePath: sendPath,
        filename: uploadName,
        kind: kindStr,
        mode: 'endtrack',
        normalize: useNormalize,
        denoise: false, // riduzione rumore applicata on-device
        gainDb: 0.0,    // volume applicato on-device
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

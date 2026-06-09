import 'dart:io';

import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Elaborazione audio ON-DEVICE del parlato registrato.
///
/// Applica (in quest'ordine) riduzione rumore → normalize → volume, così che
/// l'anteprima nell'app rifletta esattamente ciò che andrà in onda. Tutti i
/// filtri usati (highpass, afftdn, loudnorm, volume) sono core ffmpeg, presenti
/// anche nel build "minimal".
class VoiceFx {
  /// Elabora [inputPath] e ritorna il path del file mp3 risultante.
  /// - Ritorna [inputPath] se non c'è nulla da applicare.
  /// - Ritorna null se ffmpeg fallisce (il chiamante farà fallback al grezzo).
  static Future<String?> process({
    required String inputPath,
    required bool denoise,
    required bool normalize,
    required double gainDb,
    required String tag,
  }) async {
    final af = <String>[];
    if (denoise) {
      af.add('highpass=f=80');          // taglia rumble/sotto-soglia voce
      af.add('afftdn=nr=12:nf=-25');    // denoise FFT moderato
    }
    if (normalize) {
      af.add('loudnorm=I=-16:TP=-1.0:LRA=11');
    }
    if (gainDb.abs() >= 0.1) {
      af.add('volume=${gainDb.toStringAsFixed(1)}dB');
    }
    if (af.isEmpty) return inputPath; // nessun effetto attivo

    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/voicefx_$tag.mp3';
    try {
      final old = File(outPath);
      if (await old.exists()) await old.delete();
    } catch (_) {}

    final args = <String>[
      '-y', '-i', inputPath,
      '-af', af.join(','),
      '-c:a', 'libmp3lame', '-b:a', '192k', '-ar', '44100', '-ac', '2',
      '-id3v2_version', '3', '-write_xing', '1',
      outPath,
    ];

    try {
      final session = await FFmpegKit.executeWithArguments(args);
      final rc = await session.getReturnCode();
      final out = File(outPath);
      if (ReturnCode.isSuccess(rc) && await out.exists() && await out.length() > 0) {
        return outPath;
      }
    } catch (_) {}
    return null;
  }
}

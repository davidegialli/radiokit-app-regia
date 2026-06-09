import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_card.dart';
import 'audio_controller.dart';

/// Tab "Audio" — voice insert (parlato) + jingle.
///
/// Flow utente:
///   1. Registra dal mic OPPURE carica file da galleria
///   2. Preview audio
///   3. Sceglie tipo (Parlato/Jingle) — autodetect: pickato file = jingle
///   4. Toggle "Normalizza a 0 dB" (default ON)
///   5. Tap "Manda dopo questo brano" → upload VPS → bridge → RadioBOSS insert
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AudioController(), fenix: true);
    return Column(children: [
      PageHeader(title: 'tab.library'.tr, eyebrow: 'PARLATO · JINGLE'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
            _SourceCard(),
            SizedBox(height: 14),
            _PreviewCard(),
            SizedBox(height: 14),
            _SendCard(),
            SizedBox(height: 14),
            _HistoryCard(),
          ]),
        ),
      ),
    ]);
  }
}

// ─── 1. Sorgente: registra mic OR file picker ───────────────
class _SourceCard extends StatelessWidget {
  const _SourceCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = AudioController.to;
      final stage = c.stage.value;
      final hasFile = c.hasFile;

      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('audio.source.title'.tr,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const SizedBox(height: 14),
        if (stage == AudioStage.recording) ...[
          // Recording UI: puntino REC pulsante + cronometro.
          // (VU meter dB rimosso: flutter_sound non riporta dB affidabili
          //  su molti device Android, dava sempre full bar.)
          Row(children: [
            const _RecPulse(),
            const SizedBox(width: 8),
            Text('audio.recording'.tr,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const Spacer(),
            Text(c.fmtRecTime(),
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 18, color: AppColors.text, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          // Onda animata: comunica chiaramente "sta registrando" (decorativa,
          // affidabile su tutti i device — non dipende dai dB reali del mic).
          const _RecWave(),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _BigBtn(
              icon: Icons.stop, label: 'audio.stop_rec'.tr,
              onTap: c.stopRecording, primary: true,
            )),
            const SizedBox(width: 8),
            Expanded(child: _BigBtn(
              icon: Icons.close, label: 'common.cancel'.tr,
              onTap: c.cancelRecording,
            )),
          ]),
        ] else if (!hasFile) ...[
          // Idle: mostra 2 bottoni grandi
          Row(children: [
            Expanded(child: _BigBtn(
              icon: Icons.mic, label: 'audio.btn.record'.tr,
              onTap: c.startRecording, primary: true,
            )),
            const SizedBox(width: 10),
            Expanded(child: _BigBtn(
              icon: Icons.folder_open, label: 'audio.btn.pick'.tr,
              onTap: c.pickFile,
            )),
          ]),
          const SizedBox(height: 10),
          Text('audio.source.hint'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 0.5)),
        ] else ...[
          // File ready
          Row(children: [
            const Icon(Icons.audio_file, size: 22, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.fileName.value ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
              const SizedBox(height: 2),
              Text(c.fmtSize(),
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3)),
            ])),
            GestureDetector(
              onTap: c.reset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.hairlineSoft),
                ),
                child: Text('audio.discard'.tr,
                  style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text2, letterSpacing: 0.5)),
              ),
            ),
          ]),
        ],
      ]));
    });
  }
}

// ─── 2. Preview audio ───────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = AudioController.to;
      if (!c.hasFile || c.stage.value == AudioStage.recording) {
        return const SizedBox.shrink();
      }
      final durMs = c.previewDur.value.inMilliseconds;
      final maxMs = durMs > 0 ? durMs.toDouble() : 1.0;
      final posMs = c.previewPos.value.inMilliseconds
          .clamp(0, maxMs.toInt()).toDouble();
      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('audio.preview'.tr,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Row(children: [
          // Play/Pausa tondo
          GestureDetector(
            onTap: c.processing.value ? null : c.togglePreview,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.14),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: c.processing.value
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent),
                    )
                  : Icon(
                      c.previewPlaying.value ? Icons.pause : Icons.play_arrow,
                      size: 26, color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.surface2,
                thumbColor: AppColors.accent,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: posMs,
                max: maxMs,
                onChanged: durMs > 0
                    ? (v) => c.seekPreview(Duration(milliseconds: v.toInt()))
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_fmtDur(c.previewPos.value),
                  style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3)),
                Text(_fmtDur(c.previewDur.value),
                  style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3)),
              ]),
            ),
          ])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: c.stopPreview,
            child: const Icon(Icons.stop_circle_outlined, size: 26, color: AppColors.text3),
          ),
        ]),
      ]));
    });
  }
}

// ─── 3. Send: tipo + normalize + invia ──────────────────────
class _SendCard extends StatelessWidget {
  const _SendCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = AudioController.to;
      if (!c.hasFile || c.stage.value == AudioStage.recording) {
        return const SizedBox.shrink();
      }
      final uploading = c.stage.value == AudioStage.uploading;

      final isVoice = c.kind.value == AudioKind.voice;
      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('audio.send.title'.tr,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const SizedBox(height: 14),
        // Tipo: 3 categorie. Voce ha campo Nome + normalize. Jingle/Spot
        // sono file pre-prodotti — file transfer puro.
        Row(children: [
          Expanded(child: _KindBtn(
            label: 'audio.kind.voice'.tr,
            icon: Icons.mic_none,
            selected: c.kind.value == AudioKind.voice,
            onTap: uploading ? null : () => c.kind.value = AudioKind.voice,
          )),
          const SizedBox(width: 6),
          Expanded(child: _KindBtn(
            label: 'audio.kind.jingle'.tr,
            icon: Icons.music_note,
            selected: c.kind.value == AudioKind.jingle,
            onTap: uploading ? null : () => c.kind.value = AudioKind.jingle,
          )),
          const SizedBox(width: 6),
          Expanded(child: _KindBtn(
            label: 'audio.kind.spot'.tr,
            icon: Icons.campaign_outlined,
            selected: c.kind.value == AudioKind.spot,
            onTap: uploading ? null : () => c.kind.value = AudioKind.spot,
          )),
        ]),
        if (isVoice) ...[
          const SizedBox(height: 14),
          // Nome (titolo display) — solo per voce
          TextField(
            controller: c.titleCtrl,
            enabled: !uploading,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'audio.fieldTitle'.tr,
              hintText: 'audio.fieldTitle.hint'.tr,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 14),
          // Normalize toggle — solo per voce
          Row(children: [
            Switch(
              value: c.normalize.value,
              onChanged: uploading ? null : (v) => c.normalize.value = v,
              activeColor: AppColors.accent,
            ),
            const SizedBox(width: 4),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('audio.normalize'.tr,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
              const SizedBox(height: 1),
              Text('audio.normalize.hint'.tr,
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 0.05)),
            ])),
          ]),
          const SizedBox(height: 6),
          // Riduzione rumore — toggle (ffmpeg afftdn/highpass lato VPS)
          Row(children: [
            Switch(
              value: c.denoise.value,
              onChanged: uploading ? null : (v) => c.denoise.value = v,
              activeColor: AppColors.accent,
            ),
            const SizedBox(width: 4),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('audio.denoise'.tr,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
              const SizedBox(height: 1),
              Text('audio.denoise.hint'.tr,
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 0.05)),
            ])),
          ]),
          const SizedBox(height: 10),
          // Volume / guadagno — slider -12..+12 dB
          Row(children: [
            const Icon(Icons.volume_up, size: 18, color: AppColors.text3),
            const SizedBox(width: 8),
            Text('audio.gain'.tr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
            const Spacer(),
            Text(
              '${c.gainDb.value > 0 ? '+' : ''}${c.gainDb.value.toStringAsFixed(0)} dB',
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surface2,
              thumbColor: AppColors.accent,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: c.gainDb.value.clamp(-12.0, 12.0),
              min: -12, max: 12, divisions: 24,
              onChanged: uploading ? null : (v) => c.gainDb.value = v,
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          // Hint per jingle/spot: niente modifica
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              c.kind.value == AudioKind.spot ? 'audio.spot.hint'.tr : 'audio.jingle.hint'.tr,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3),
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Send button + progress
        if (uploading)
          Column(children: [
            LinearProgressIndicator(
              value: c.uploadProgress.value > 0 ? c.uploadProgress.value : null,
              backgroundColor: AppColors.surface2,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              c.uploadProgress.value > 0
                  ? '${(c.uploadProgress.value * 100).toStringAsFixed(0)}%'
                  : 'audio.sending'.tr,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 11, color: AppColors.accent),
            ),
          ])
        else
          GestureDetector(
            onTap: () => c.send(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('audio.send.btn'.tr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
      ]));
    });
  }
}

// ─── 4. History (ultimi invii) ──────────────────────────────
class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final h = AudioController.to.history;
      if (h.isEmpty) return const SizedBox.shrink();

      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('audio.history'.tr,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        for (var i = 0; i < h.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.hairlineSoft),
          _HistoryRow(entry: h[i]),
        ],
      ]));
    });
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final fn = (entry['filename'] ?? '').toString();
    final kind = (entry['kind'] ?? 'voice').toString();
    final status = (entry['status'] ?? '').toString();
    final err = (entry['error'] ?? '').toString();

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'sent':
        statusColor = AppColors.autoDj;
        statusLabel = 'audio.hist.sent'.tr;
        break;
      case 'uploading':
        statusColor = AppColors.accent;
        statusLabel = 'audio.hist.uploading'.tr;
        break;
      case 'error':
        statusColor = AppColors.warn;
        statusLabel = 'audio.hist.error'.tr;
        break;
      default:
        statusColor = AppColors.text3;
        statusLabel = status.toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(kind == 'jingle' ? Icons.music_note : Icons.mic_none,
          size: 14, color: AppColors.text3),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fn, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
          if (status == 'error' && err.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(err, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.warn)),
          ],
        ])),
        Text(statusLabel,
          style: TextStyle(fontFamily: 'GeistMono', fontSize: 9,
            color: statusColor, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      ]),
    );
  }
}

// ─── widget helpers ─────────────────────────────────────────
String _fmtDur(Duration d) {
  final s = d.inSeconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class _BigBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _BigBtn({required this.icon, required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary ? AppColors.accent.withOpacity(0.14) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary ? AppColors.accent.withOpacity(0.4) : AppColors.hairlineSoft),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 24, color: primary ? AppColors.accent : AppColors.text2),
          const SizedBox(height: 6),
          Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: primary ? AppColors.accent : AppColors.text)),
        ]),
      ),
    );
  }
}

class _KindBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _KindBtn({required this.icon, required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withOpacity(0.14) : AppColors.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.accent : AppColors.hairlineSoft),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? AppColors.accent : AppColors.text3),
            const SizedBox(width: 6),
            Text(label,
              style: TextStyle(
                fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.accent : AppColors.text2,
              )),
          ],
        ),
      ),
    );
  }
}

// ─── REC pulsante: puntino rosso che pulsa con opacità ────
class _RecPulse extends StatefulWidget {
  const _RecPulse();
  @override
  State<_RecPulse> createState() => _RecPulseState();
}

class _RecPulseState extends State<_RecPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.3 + 0.7 * _ctrl.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Onda animata in registrazione (decorativa, affidabile) ──
class _RecWave extends StatefulWidget {
  const _RecWave();
  @override
  State<_RecWave> createState() => _RecWaveState();
}

class _RecWaveState extends State<_RecWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // 28 barre con fasi/velocità diverse → moto organico (no random per build stabile).
  static const int _bars = 28;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value * 2 * math.pi;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_bars, (i) {
              // Combinazione di due seni a frequenze diverse per barra → onda viva.
              final phase = i * 0.55;
              final v = (math.sin(t + phase) * 0.5 +
                         math.sin(t * 1.7 + phase * 0.7) * 0.5);
              final h = 4.0 + (v.abs()) * 28.0;
              return Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.45 + 0.45 * v.abs()),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

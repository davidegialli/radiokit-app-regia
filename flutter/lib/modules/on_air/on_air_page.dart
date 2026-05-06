import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/status_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/regia_status.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_card.dart';
import '../../shared/widgets/waveform.dart';
import 'on_air_controller.dart';

class OnAirPage extends StatelessWidget {
  const OnAirPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lazy registrazione (l'AppShell non chiama il binding di OnAir all'init)
    Get.lazyPut(() => OnAirController(), fenix: true);
    return Column(children: [
      PageHeader(title: 'tab.onAir'.tr, eyebrow: 'PLAYBACK · RADIOBOSS'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
            _NowPlayingHero(),
            SizedBox(height: 14),
            _TransportCard(),
            SizedBox(height: 14),
            _VolumeCard(),
            SizedBox(height: 14),
            _QueueCard(),
          ]),
        ),
      ),
    ]);
  }
}

/// Quando il bridge non riporta un brano in riproduzione (title/artist
/// vuoti) cerchiamo di capire COSA sta facendo RadioBOSS in base ai
/// campi disponibili: state, filename, ecc. Cosi' l'utente vede sempre
/// qualcosa di significativo, non un generico "Nessuna traccia".
String _describeNoTrackState(NowPlaying? np, RegiaStatus s) {
  if (np == null) {
    if (!s.bridgesOnline.contains('timer')) return 'Studio non connesso';
    return 'In attesa…';
  }
  final state = np.state.toLowerCase();
  final fn = np.filename.trim();

  // RadioBOSS scheduler commands tipo 'getfile "..." /random.command'
  if (fn.startsWith('getfile')) {
    // Estraiamo il path tra virgolette per dare info sulla cartella
    final m = RegExp(r'"([^"]+)"').firstMatch(fn);
    final folder = m != null ? m.group(1)!.split(RegExp(r'[\\/]')).last : '';
    return folder.isNotEmpty ? '🎲 Random pick: $folder' : '🎲 Comando RB';
  }
  if (fn.startsWith('generate')) return '⚙ Genera playlist';
  if (fn.startsWith('runevent')) return '⚡ Evento scheduler';
  if (fn.toLowerCase().startsWith(RegExp(r'https?://'))) {
    final short = fn.length > 50 ? '${fn.substring(0, 50)}…' : fn;
    return '📡 Stream esterno: $short';
  }

  // Stato di transizione / RB silente
  switch (state) {
    case 'stop':
    case 'stopped': return '⏹ RadioBOSS fermo';
    case 'pause':
    case 'paused':  return '⏸ RadioBOSS in pausa';
    case 'play':
    case 'playing': return '▶ Transizione in corso…';
    default:        return '⏳ In attesa…';
  }
}

// ─── HERO Now Playing ────────────────────────────────────────
class _NowPlayingHero extends StatelessWidget {
  const _NowPlayingHero();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = StatusService.to.status.value;
      final np = s.nowPlaying;
      final state = (np?.state ?? '').toLowerCase();
      final stateLabel = switch (state) {
        'playing' => 'onair.statePlaying'.tr,
        'paused'  => 'onair.statePaused'.tr,
        'stopped' => 'onair.stateStopped'.tr,
        _         => 'onair.stateUnknown'.tr,
      };
      final accent = state == 'playing' ? AppColors.accent : AppColors.text3;
      final has = np != null && !np.isEmpty;

      return Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.bgElev,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(stateLabel,
              style: TextStyle(fontFamily: 'GeistMono', fontSize: 9, fontWeight: FontWeight.w600, color: accent, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          if (!has) ...[
            // Anche senza title/artist mostriamo info utili dal bridge state:
            // filename del current track (anche se e' un comando tipo getfile),
            // playlistpos, e label generica
            Text(_describeNoTrackState(np, s),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text)),
            if (np != null && np.duration.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(np.duration,
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 11, color: AppColors.text3)),
            ],
          ]
          else ...[
            Text(np.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(np.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.text2)),
            if (np.album.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(np.album, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3)),
            ],
            // Waveform animata + timestamp (solo se lenMs > 0)
            // Usiamo smoothedPosMs/smoothedTimeLeftS dal service per
            // avanzamento fluido tra un sample server e l'altro (250ms tick).
            if (np.lenMs > 0) ...[
              const SizedBox(height: 14),
              Obx(() {
                final smoothPos = StatusService.to.smoothedPosMs.value;
                final smoothProgress = (smoothPos / np.lenMs).clamp(0.0, 1.0);
                return Waveform(
                  progress: smoothProgress,
                  live: state == 'play',
                  height: 48,
                );
              }),
              const SizedBox(height: 6),
              Obx(() {
                final smoothPos = StatusService.to.smoothedPosMs.value;
                final smoothTL = StatusService.to.smoothedTimeLeftS.value;
                final fmtSmoothPos = NowPlaying.fmtMs(smoothPos);
                return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(fmtSmoothPos,
                    style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text2, fontWeight: FontWeight.w600)),
                  if (smoothTL > 0)
                    Text('-${(smoothTL ~/ 60).toString().padLeft(2,'0')}:${(smoothTL % 60).toString().padLeft(2,'0')}',
                      style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3)),
                  Text(np.fmtLen(),
                    style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3)),
                ]);
              }),
            ],
          ],
          if (s.appState == RegiaAppState.offline) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warn.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('stream.state.offline'.tr.toUpperCase(),
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.warn, letterSpacing: 1.0, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      );
    });
  }
}

// ─── Transport buttons ───────────────────────────────────────
class _TransportCard extends StatelessWidget {
  const _TransportCard();

  @override
  Widget build(BuildContext context) {
    final c = OnAirController.to;
    return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('onair.transport'.tr,
        style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
      const SizedBox(height: 14),
      Obx(() {
        final disabled = c.sending.value.isNotEmpty || !StatusService.to.bridgeOnline;
        // Stato corrente da RadioBOSS — il bottone attivo si evidenzia.
        // RB ritorna 'play' (non 'playing'!) in alcune versioni — accettiamo entrambi.
        final s = StatusService.to.status.value.nowPlaying?.state.toLowerCase() ?? '';
        final isPlaying = s == 'play' || s == 'playing';
        final isPaused  = s == 'pause' || s == 'paused';
        final isStopped = s == 'stop' || s == 'stopped' || s.isEmpty;
        return Row(children: [
          Expanded(child: _TBtn(icon: Icons.skip_previous, label: 'onair.prev'.tr,    disabled: disabled, onTap: c.prev)),
          const SizedBox(width: 8),
          Expanded(child: _TBtn(icon: Icons.play_arrow,    label: 'onair.play'.tr,    disabled: disabled, onTap: c.play,   accent: isPlaying)),
          const SizedBox(width: 8),
          Expanded(child: _TBtn(icon: Icons.pause,         label: 'onair.pause'.tr,   disabled: disabled, onTap: c.pause,  accent: isPaused)),
          const SizedBox(width: 8),
          Expanded(child: _TBtn(icon: Icons.skip_next,     label: 'onair.skipNext'.tr,disabled: disabled, onTap: c.skip)),
          const SizedBox(width: 8),
          Expanded(child: _TBtn(icon: Icons.stop,          label: 'onair.stop'.tr,    disabled: disabled, onTap: c.stop,   danger: isStopped)),
        ]);
      }),
    ]));
  }
}

class _TBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  final bool accent;
  final bool danger;
  const _TBtn({
    required this.icon, required this.label, required this.onTap,
    this.disabled = false, this.accent = false, this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = disabled ? AppColors.text4
             : danger ? AppColors.warn
             : accent ? AppColors.accent
             : AppColors.text;
    final bg = disabled ? AppColors.surface.withOpacity(0.4)
             : accent ? AppColors.accent.withOpacity(0.14)
             : AppColors.surface;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent ? AppColors.accent.withOpacity(0.4) : AppColors.hairlineSoft),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: fg),
          const SizedBox(height: 4),
          Text(label,
            style: TextStyle(fontFamily: 'GeistMono', fontSize: 8, color: fg, letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}

// ─── Volume slider ───────────────────────────────────────────
class _VolumeCard extends StatelessWidget {
  const _VolumeCard();

  @override
  Widget build(BuildContext context) {
    final c = OnAirController.to;
    return RkCard(child: Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('onair.volume'.tr,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const Spacer(),
        Text('${c.volume.value}%',
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.accent,
          inactiveTrackColor: AppColors.surface2,
          thumbColor: AppColors.accent,
          overlayColor: AppColors.accent.withOpacity(0.18),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
        child: Slider(
          value: c.volume.value.toDouble(),
          min: 0, max: 100, divisions: 100,
          onChanged: StatusService.to.bridgeOnline ? c.onVolumeChanged : null,
        ),
      ),
    ])));
  }
}


// ─── Coda playlist (next 10) con drag & drop reorder ──────────
class _QueueCard extends StatelessWidget {
  const _QueueCard();

  @override
  Widget build(BuildContext context) {
    final c = OnAirController.to;
    return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('onair.queue.title'.tr,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        Obx(() => GestureDetector(
          onTap: c.queueLoading.value ? null : c.loadQueue,
          child: Text(c.queueLoading.value ? '…' : '↻',
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12, color: AppColors.text3)),
        )),
      ]),
      const SizedBox(height: 10),
      Obx(() {
        final list = c.queue;
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(child: Text(
              c.queueLoading.value ? 'common.loading'.tr : 'onair.queue.empty'.tr,
              style: const TextStyle(fontSize: 12, color: AppColors.text3))),
          );
        }
        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: list.length,
          onReorder: (oldIdx, newIdx) {
            // Flutter passa newIdx come "indice di destinazione AFTER move".
            // Se ti sposti più in basso, devi -1 perché la lista cambia.
            if (newIdx > oldIdx) newIdx -= 1;
            c.moveTrack(oldIdx, newIdx);
          },
          itemBuilder: (ctx, i) {
            final t = list[i];
            return _QueueRow(
              key: ValueKey('queue-${t['pos']}-$i'),
              index: i,
              track: t,
            );
          },
        );
      }),
      const SizedBox(height: 4),
      Text('onair.queue.hint'.tr,
        style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3)),
    ]));
  }
}

class _QueueRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> track;
  const _QueueRow({super.key, required this.index, required this.track});

  @override
  Widget build(BuildContext context) {
    final title  = (track['title']  ?? '').toString();
    final artist = (track['artist'] ?? '').toString();
    final dur    = (track['duration'] ?? '').toString();
    final isUrl  = track['is_url'] == true;
    final fn     = (track['filename'] ?? '').toString();
    // Display: se title vuoto, usa basename del filename
    final display = title.isNotEmpty
        ? (artist.isNotEmpty ? '$artist — $title' : title)
        : (fn.split(RegExp(r'[\/]')).last);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 22, child: Text('${index + 1}',
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600))),
        const SizedBox(width: 6),
        if (isUrl)
          const Icon(Icons.podcasts, size: 12, color: AppColors.accent)
        else
          const Icon(Icons.music_note, size: 12, color: AppColors.text3),
        const SizedBox(width: 8),
        Expanded(child: Text(display, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.text))),
        if (dur.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(dur, style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3)),
        ],
        const SizedBox(width: 4),
        ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.drag_handle, size: 16, color: AppColors.text3),
          ),
        ),
      ]),
    );
  }
}

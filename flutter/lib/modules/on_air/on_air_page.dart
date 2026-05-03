import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/status_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/regia_status.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_card.dart';
import '../../shared/widgets/rk_field_row.dart';
import 'on_air_controller.dart';

class OnAirPage extends StatelessWidget {
  const OnAirPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lazy registrazione (l'AppShell non chiama il binding di OnAir all'init)
    Get.lazyPut(() => OnAirController(), fenix: true);
    return Column(children: [
      PageHeader(title: 'tab.onAir'.tr, eyebrow: 'header.live'.tr),
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
            _RunEventCard(),
          ]),
        ),
      ),
    ]);
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
          if (!has)
            Text('home.noTrack'.tr, style: const TextStyle(fontSize: 16, color: AppColors.text3))
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
        return Row(children: [
          Expanded(child: _TBtn(icon: Icons.skip_previous, label: 'onair.prev'.tr,    disabled: disabled, onTap: c.prev)),
          const SizedBox(width: 8),
          Expanded(child: _TBtn(icon: Icons.play_arrow,    label: 'onair.play'.tr,    disabled: disabled, onTap: c.play, accent: true)),
          const SizedBox(width: 8),
          Expanded(child: _TBtn(icon: Icons.pause,         label: 'onair.pause'.tr,   disabled: disabled, onTap: c.pause)),
          const SizedBox(width: 8),
          Expanded(child: _TBtn(icon: Icons.skip_next,     label: 'onair.skipNext'.tr,disabled: disabled, onTap: c.skip)),
          const SizedBox(width: 8),
          Expanded(child: _TBtn(icon: Icons.stop,          label: 'onair.stop'.tr,    disabled: disabled, onTap: c.stop, danger: true)),
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

// ─── Run event ────────────────────────────────────────────────
class _RunEventCard extends StatelessWidget {
  const _RunEventCard();

  @override
  Widget build(BuildContext context) {
    final c = OnAirController.to;
    return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('onair.runEvent'.tr,
        style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      RkFieldRow(
        label: 'onair.eventName'.tr,
        hint: 'onair.eventHint'.tr,
        child: Obx(() => TextField(
          controller: c.eventCtrl,
          enabled: c.sending.value.isEmpty,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12),
          decoration: const InputDecoration(hintText: 'jingle_news'),
        )),
      ),
      const SizedBox(height: 10),
      Obx(() {
        final canRun = c.eventName.value.trim().isNotEmpty
                     && c.sending.value.isEmpty
                     && StatusService.to.bridgeOnline;
        return GestureDetector(
          onTap: canRun ? c.runEvent : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: canRun ? AppColors.accent : AppColors.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('onair.runBtn'.tr,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: canRun ? Colors.white : AppColors.text4,
              )),
          ),
        );
      }),
    ]));
  }
}

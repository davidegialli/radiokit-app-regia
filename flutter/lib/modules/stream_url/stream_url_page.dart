import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/regia_command.dart';
import '../../data/models/regia_status.dart';
import '../../data/models/stream_launch.dart' show StreamHealth;
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_button.dart';
import '../../shared/widgets/rk_card.dart';
import '../../shared/widgets/rk_field_row.dart';
import '../../shared/widgets/rk_pill.dart';
import '../../shared/widgets/rk_seg_radio.dart';
import '../../shared/widgets/rk_status_chip.dart';
import '../../shared/widgets/rk_toggle.dart';
import 'stream_url_controller.dart';
import 'widgets/broadcast_halo.dart';
import 'widgets/route_diagram.dart';

class StreamUrlPage extends GetView<StreamUrlController> {
  const StreamUrlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(
        title: 'stream.title'.tr,
        eyebrow: 'INVIO ALLA REGIA',
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _nowPlaying(),
            const SizedBox(height: 14),
            _hero(),
            const SizedBox(height: 14),
            Obx(() => controller.isLive ? _liveTelemetry() : const SizedBox.shrink()),
            Obx(() => controller.isLive ? const SizedBox(height: 14) : const SizedBox.shrink()),
            _sourceForm(),
            const SizedBox(height: 14),
            _routing(),
          ]),
        ),
      ),
    ]);
  }

  // ─── NOW PLAYING ─────────────────────────────────
  // Card sempre visibile in alto: titolo + artista reali da RadioBOSS.
  Widget _nowPlaying() {
    return Obx(() {
      final s = controller.status.value;
      final np = s.nowPlaying;
      final hasTrack = np != null && !np.isEmpty;
      final age = s.bridgeAgeSec;

      return RkCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('stream.now.title'.tr,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
            if (s.appState != RegiaAppState.unknown)
              _bridgeDot(s.appState, age),
          ]),
          const SizedBox(height: 10),
          if (!hasTrack)
            Text('stream.now.empty'.tr,
              style: const TextStyle(fontSize: 14, color: AppColors.text3))
          else ...[
            Text(np.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.1)),
            const SizedBox(height: 2),
            Text(np.artist,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.text3)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            if (s.listeners != null) ...[
              const Icon(Icons.headphones_outlined, size: 12, color: AppColors.text3),
              const SizedBox(width: 4),
              Text(
                'stream.now.listeners'.tr.replaceAll('@n', s.listeners.toString()),
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3),
              ),
            ],
            if (s.relayActive) ...[
              const SizedBox(width: 4),
              Text('stream.now.relayOn'.tr,
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.accent)),
            ],
            const Spacer(),
            if (age != null && age >= 0)
              Text('stream.now.bridgeAge'.tr.replaceAll('@sec', age.toString()),
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text4)),
          ]),
        ]),
      );
    });
  }

  Widget _bridgeDot(RegiaAppState st, int? age) {
    final stale = age == null || age > 30;
    Color c;
    String label;
    if (st == RegiaAppState.offline || stale) {
      c = AppColors.text3;
      label = 'OFFLINE';
    } else if (st == RegiaAppState.live) {
      c = AppColors.accent;
      label = 'LIVE';
    } else {
      c = AppColors.autoDj;
      label = 'ONLINE';
    }
    return Row(children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontFamily: 'GeistMono', fontSize: 9, fontWeight: FontWeight.w600, color: c, letterSpacing: 1.0)),
    ]);
  }

  // ─── HERO ────────────────────────────────────────
  // Card grande con: status chip, halo, titolo stato, hint, CTA.
  Widget _hero() {
    return Obx(() {
      final st = controller.appState;
      final isLive = st == RegiaAppState.live;
      final isWaiting = st == RegiaAppState.requested || st == RegiaAppState.scheduled;
      final highlight = isLive || isWaiting;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: highlight
              ? RadialGradient(
                  center: const Alignment(0, -1),
                  radius: 1.2,
                  colors: [AppColors.accent.withOpacity(0.18), AppColors.surface, AppColors.bgElev],
                  stops: const [0, 0.55, 1],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppColors.surface, AppColors.bgElev],
                ),
          border: Border.all(color: highlight ? AppColors.accent.withOpacity(0.4) : AppColors.hairlineSoft),
        ),
        child: Column(children: [
          RkStatusChip(text: _chipFor(st), active: isLive),
          const SizedBox(height: 14),
          BroadcastHalo(streaming: highlight, health: StreamHealth.ok),
          const SizedBox(height: 14),
          SizedBox(
            height: 70,
            child: Column(children: [
              Text(
                _stateLabel(st),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.1),
              ),
              const SizedBox(height: 6),
              Text(
                _stateSubtitle(st),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.text3, height: 1.4),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          _ctaFor(st),
        ]),
      );
    });
  }

  String _chipFor(RegiaAppState st) {
    switch (st) {
      case RegiaAppState.live:      return 'stream.status.live'.tr;
      case RegiaAppState.scheduled: return 'stream.state.scheduled'.tr.toUpperCase();
      case RegiaAppState.requested: return 'stream.state.requested'.tr.toUpperCase();
      case RegiaAppState.offline:   return 'stream.state.offline'.tr.toUpperCase();
      case RegiaAppState.error:     return 'stream.state.error'.tr.toUpperCase();
      case RegiaAppState.unknown:   return 'stream.state.unknown'.tr.toUpperCase();
      case RegiaAppState.idle:      return 'stream.status.ready'.tr;
    }
  }

  String _stateLabel(RegiaAppState st) {
    if (st == RegiaAppState.live && controller.sessionTitle != null) {
      return controller.sessionTitle!;
    }
    return 'stream.state.${st.name}'.tr;
  }

  String _stateSubtitle(RegiaAppState st) {
    switch (st) {
      case RegiaAppState.offline:   return 'stream.state.offlineHint'.tr;
      case RegiaAppState.idle:      return 'stream.subtitle'.tr;
      case RegiaAppState.requested: return 'stream.state.requestedHint'.tr;
      case RegiaAppState.scheduled:
        final np = controller.status.value.nowPlaying;
        if (np != null && !np.isEmpty) {
          return '${'stream.state.scheduledHint'.tr}: ${np.title}';
        }
        return 'stream.state.scheduledHint'.tr;
      case RegiaAppState.live:      return 'stream.state.liveHint'.tr;
      case RegiaAppState.error:     return controller.localError.value ?? '';
      case RegiaAppState.unknown:   return '';
    }
  }

  Widget _ctaFor(RegiaAppState st) {
    final loading = controller.loading.value;
    if (st == RegiaAppState.offline || st == RegiaAppState.unknown) {
      return RkButton(
        fullWidth: true, size: RkBtnSize.lg,
        icon: Icons.cloud_off,
        onPressed: null,
        child: Text('stream.cta.go'.tr),
      );
    }
    if (st == RegiaAppState.idle) {
      return RkButton(
        fullWidth: true, size: RkBtnSize.lg,
        icon: Icons.podcasts,
        onPressed: controller.canStart ? controller.start : null,
        child: Text(loading ? 'stream.cta.probing'.tr : 'stream.cta.go'.tr),
      );
    }
    // requested | scheduled | live | error → STOP
    return RkButton(
      fullWidth: true, size: RkBtnSize.lg,
      icon: Icons.stop,
      onPressed: loading ? null : controller.stop,
      child: Text('stream.cta.stop'.tr),
    );
  }

  // ─── LIVE TELEMETRY (semplificato: solo elapsed + duration bar) ──
  Widget _liveTelemetry() {
    return RkCard(
      child: Obx(() {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('stream.telem.title'.tr,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
            Text(controller.fmtElapsed(),
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
          ]),
          if (controller.sessionDurationMin != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _durationBar(),
          ],
        ]);
      }),
    );
  }

  Widget _durationBar() {
    return Obx(() {
      final dMin = controller.sessionDurationMin ?? 0;
      final progress = dMin > 0 ? (controller.elapsedSec / (dMin * 60)).clamp(0.0, 1.0) : 0.0;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('stream.telem.duration'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3)),
          Text('${controller.fmtElapsed()} / ${dMin}m',
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text2)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surface2,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ]);
    });
  }

  // ─── SOURCE FORM ─────────────────────────────────
  Widget _sourceForm() {
    return RkCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('stream.sourceTitle'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
          Obx(() => controller.recents.isEmpty
              ? const SizedBox.shrink()
              : GestureDetector(
                  onTap: controller.formLocked ? null : controller.clearRecents,
                  child: Text('stream.recents.clear'.tr,
                    style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 0.5)),
                )),
        ]),
        const SizedBox(height: 10),
        _recentsChips(),
        RkFieldRow(
          label: 'stream.urlLabel'.tr,
          hint: 'stream.urlHint'.tr,
          child: Obx(() => TextField(
            controller: controller.urlCtrl,
            enabled: !controller.formLocked,
            keyboardType: TextInputType.url,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12),
            decoration: const InputDecoration(hintText: 'https://encoder.miosito.com:8000/live'),
          )),
        ),
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
        RkFieldRow(
          label: 'stream.titleLabel'.tr,
          hint: 'stream.titleHint'.tr,
          child: Obx(() => TextField(
            controller: controller.titleCtrl,
            enabled: !controller.formLocked,
            maxLength: 60,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(counterText: '', hintText: 'stream.titleLabel'.tr),
          )),
        ),
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
        RkFieldRow(
          label: 'stream.hostLabel'.tr,
          hint: 'stream.hostHint'.tr,
          child: Obx(() => TextField(
            controller: controller.hostCtrl,
            enabled: !controller.formLocked,
            maxLength: 40,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(counterText: ''),
          )),
        ),
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
        Obx(() {
          final m = controller.startMode.value;
          final hint = m == StartMode.now      ? 'stream.startModeNowHint'.tr
                     : m == StartMode.endtrack ? 'stream.startModeEndHint'.tr
                                               : 'stream.startModeFadeHint'.tr;
          return RkSettingRow(
            label: 'stream.startMode'.tr,
            hint: hint,
            child: RkSegRadio<StartMode>(
              value: m,
              disabled: controller.formLocked,
              onChanged: (v) => controller.startMode.value = v,
              options: [
                RkSegOption(StartMode.now,      'stream.startModeNow'.tr),
                RkSegOption(StartMode.endtrack, 'stream.startModeEnd'.tr),
                RkSegOption(StartMode.fade,     'stream.startModeFade'.tr),
              ],
            ),
          );
        }),
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
        Obx(() {
          final d = controller.duration.value;
          final hint = d == '0'
              ? 'stream.durationManual'.tr
              : 'stream.durationAuto'.tr.replaceAll('@min', d);
          return RkSettingRow(
            label: 'stream.duration'.tr,
            hint: hint,
            child: RkSegRadio<String>(
              value: d,
              disabled: controller.formLocked,
              onChanged: (v) => controller.duration.value = v,
              options: const [
                RkSegOption('30',  '30m'),
                RkSegOption('60',  '1h'),
                RkSegOption('120', '2h'),
                RkSegOption('240', '4h'),
                RkSegOption('0',   '∞'),
              ],
            ),
          );
        }),
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
        Obx(() => RkSettingRow(
          label: 'stream.fallback'.tr,
          hint: 'stream.fallbackHint'.tr,
          child: RkToggle(
            value: controller.autoFallback.value,
            disabled: controller.formLocked,
            onChanged: (v) => controller.autoFallback.value = v,
          ),
        )),
      ]),
    );
  }

  // ─── ROUTING ─────────────────────────────────────
  Widget _routing() {
    return RkCard(
      child: Obx(() {
        final s = controller.isLive || controller.isWaiting;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('stream.routing.title'.tr,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
            const RkPill(text: 'PLAYURL', icon: Icons.podcasts),
          ]),
          const SizedBox(height: 10),
          RouteHop(label: 'stream.routing.urlSource'.tr, sub: _shortUrl(controller.url.value), icon: Icons.cloud_outlined, active: s),
          RouteLine(active: s),
          RouteHop(label: 'stream.routing.vps'.tr, sub: 'stream.routing.vpsSub'.tr, icon: Icons.dns_outlined, active: s),
          RouteLine(active: s),
          RouteHop(
            label: 'stream.routing.radioboss'.tr,
            sub: 'stream.routing.radiobossSub'.tr.replaceAll('@title', controller.title.value),
            icon: Icons.library_music_outlined, active: s, last: true,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text('stream.routing.note'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 0.5)),
        ]);
      }),
    );
  }

  // Recents = ultimi URL SORGENTE lanciati con successo (encoder remoti,
  // eventi esterni, radio partner). Diversi dagli stream OUTPUT
  // (icecast/shoutcast) che vivono nella tab Streaming.
  Widget _recentsChips() {
    return Obx(() {
      if (controller.recents.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Wrap(
          spacing: 6, runSpacing: 6,
          children: controller.recents.map((url) {
            final selected = url == controller.url.value;
            final short = _shortUrl(url);
            return GestureDetector(
              onTap: controller.formLocked ? null : () => controller.applyRecent(url),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent.withOpacity(0.15) : AppColors.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.hairlineSoft,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.history, size: 11, color: AppColors.text3),
                  const SizedBox(width: 5),
                  Text(
                    short.length > 28 ? '${short.substring(0, 26)}…' : short,
                    style: TextStyle(
                      fontFamily: 'GeistMono',
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.accent : AppColors.text2,
                    ),
                  ),
                ]),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  String _shortUrl(String u) {
    try {
      final x = Uri.parse(u);
      return '${x.host}${x.path.length > 1 ? x.path : ''}';
    } catch (_) {
      return u.isEmpty ? '—' : u;
    }
  }
}

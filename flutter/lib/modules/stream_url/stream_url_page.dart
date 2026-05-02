import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/regia_command.dart';
import '../../data/models/stream_launch.dart';
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
import 'widgets/telem_tile.dart';

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
            _hero(),
            const SizedBox(height: 14),
            Obx(() => controller.isStreaming ? _telemetry() : const SizedBox.shrink()),
            Obx(() => controller.isStreaming ? const SizedBox(height: 14) : const SizedBox.shrink()),
            _sourceForm(),
            const SizedBox(height: 14),
            _routing(),
            const SizedBox(height: 14),
            _recent(),
          ]),
        ),
      ),
    ]);
  }

  // ─── HERO ────────────────────────────────────────
  Widget _hero() {
    return Obx(() {
      final streaming = controller.isStreaming;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: streaming
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
          border: Border.all(color: streaming ? AppColors.accent.withOpacity(0.4) : AppColors.hairlineSoft),
        ),
        child: Column(children: [
          RkStatusChip(
            text: streaming ? 'stream.status.live'.tr : 'stream.status.ready'.tr,
            active: streaming,
          ),
          const SizedBox(height: 14),
          BroadcastHalo(streaming: streaming, health: controller.health.value),
          const SizedBox(height: 14),
          SizedBox(
            height: 60,
            child: Column(children: [
              Text(
                streaming ? controller.title.value : 'stream.title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.1),
              ),
              const SizedBox(height: 4),
              Text(
                streaming
                    ? '${'stream.hostLabel'.tr.toLowerCase()}: ${controller.host.value}'
                    : 'stream.subtitle'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.text3, height: 1.4),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          if (!streaming)
            RkButton(
              fullWidth: true,
              size: RkBtnSize.lg,
              icon: Icons.podcasts,
              onPressed: controller.canStart ? controller.start : null,
              child: Text(controller.probing.value ? 'stream.cta.probing'.tr : 'stream.cta.go'.tr),
            )
          else
            RkButton(
              fullWidth: true,
              size: RkBtnSize.lg,
              icon: Icons.stop,
              onPressed: controller.stop,
              child: Text('stream.cta.stop'.tr),
            ),
        ]),
      );
    });
  }

  // ─── TELEMETRY ───────────────────────────────────
  Widget _telemetry() {
    return RkCard(
      child: Obx(() {
        final h = controller.health.value;
        final hLabel = h == StreamHealth.ok ? 'stream.health.ok'.tr
                     : h == StreamHealth.buffering ? 'stream.health.buffering'.tr
                     : 'stream.health.down'.tr;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('stream.telem.title'.tr,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
            Text(controller.fmtElapsed(),
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TelemTile(
              label: 'stream.telem.source'.tr,
              value: hLabel,
              unit: controller.srcCodec.value.isEmpty ? '—' : controller.srcCodec.value,
              good: h == StreamHealth.ok,
              warn: h == StreamHealth.buffering,
            )),
            const SizedBox(width: 8),
            Expanded(child: TelemTile(
              label: 'stream.telem.bitrate'.tr,
              value: controller.srcBitrate.value.replaceAll(' kbps', '').isEmpty
                  ? '—' : controller.srcBitrate.value.replaceAll(' kbps', ''),
              unit: 'kbps',
            )),
            const SizedBox(width: 8),
            Expanded(child: TelemTile(
              label: 'stream.telem.received'.tr,
              value: controller.fmtBytes(),
              unit: 'tot',
            )),
          ]),
          if (controller.duration.value != '0' && controller.session.value?.durationMin != null) ...[
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
      final dMin = controller.session.value?.durationMin ?? 0;
      final progress = dMin > 0 ? (controller.elapsedSec.value / (dMin * 60)).clamp(0.0, 1.0) : 0.0;
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
        Text('Sorgente stream',
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        RkFieldRow(
          label: 'stream.urlLabel'.tr,
          hint: 'stream.urlHint'.tr,
          child: Obx(() => TextField(
            controller: controller.urlCtrl,
            enabled: !controller.isStreaming,
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
            enabled: !controller.isStreaming,
            maxLength: 60,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(counterText: '', hintText: 'Es. Notte Italiana'),
          )),
        ),
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
        RkFieldRow(
          label: 'stream.hostLabel'.tr,
          hint: 'stream.hostHint'.tr,
          child: Obx(() => TextField(
            controller: controller.hostCtrl,
            enabled: !controller.isStreaming,
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
              disabled: controller.isStreaming,
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
              disabled: controller.isStreaming,
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
            disabled: controller.isStreaming,
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
        final s = controller.isStreaming;
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

  // ─── RECENT ──────────────────────────────────────
  Widget _recent() {
    return RkCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('stream.recent'.tr,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        _LaunchRow(t: '22:14', dur: '00:18:42', title: 'Drive Time',     host: 'Federico R.',     ok: true),
        const Divider(height: 1),
        _LaunchRow(t: 'ieri',  dur: '01:02:11', title: 'Notte Italiana', host: 'Davide Gialli',   ok: true),
        const Divider(height: 1),
        _LaunchRow(t: 'ieri',  dur: '00:04:09', title: 'Eventi LIVE',    host: 'evento esterno',  ok: false, warn: 'sorgente cadde · fallback'),
        const Divider(height: 1),
        _LaunchRow(t: 'lun',   dur: '00:42:18', title: 'Mattina RK',     host: 'Sara Bonetti',    ok: true),
      ]),
    );
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

class _LaunchRow extends StatelessWidget {
  final String t, dur, title, host;
  final bool ok;
  final String? warn;
  const _LaunchRow({required this.t, required this.dur, required this.title, required this.host, required this.ok, this.warn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(width: 36,
          child: Text(t, style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
            const SizedBox(height: 2),
            Text('$dur · $host${warn != null ? ' · $warn' : ''}',
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 0.05)),
          ]),
        ),
        Text(ok ? 'OK' : 'WARN',
          style: TextStyle(fontFamily: 'GeistMono', fontSize: 9, letterSpacing: 1.0,
            color: ok ? AppColors.autoDj : AppColors.warn)),
      ]),
    );
  }
}

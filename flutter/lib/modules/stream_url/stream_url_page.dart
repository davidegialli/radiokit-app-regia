import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/regia_command.dart';
import '../../data/models/regia_status.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_button.dart';
import '../../shared/widgets/rk_card.dart';
import '../../shared/widgets/rk_field_row.dart';
import '../../shared/widgets/rk_seg_radio.dart';
import '../../shared/widgets/rk_status_chip.dart';
import 'stream_url_controller.dart';

/// Tab Diretta — versione semplificata.
/// Solo gli elementi essenziali per: inserire URL → titolo → lanciare →
/// vedere stato (idle / in coda / live) → stop.
/// Niente telemetria, niente routing diagram, niente halo: l'utente vuole
/// solo confermare che la diretta è partita o in coda.
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
            _statusCard(),
            const SizedBox(height: 14),
            _form(),
            const SizedBox(height: 14),
            _actionButton(),
          ]),
        ),
      ),
    ]);
  }

  // ── STATUS CARD: stato corrente + messaggio chiaro ──────────────
  Widget _statusCard() {
    return Obx(() {
      final st = controller.appState;
      final isLive    = st == RegiaAppState.live;
      final isWaiting = st == RegiaAppState.requested || st == RegiaAppState.scheduled;

      String label;
      String hint;
      Color accent;
      IconData icon;

      switch (st) {
        case RegiaAppState.live:
          label = 'stream.status.live'.tr;
          hint  = controller.sessionTitle != null
              ? '"${controller.sessionTitle}" ${'stream.state.liveHint'.tr.toLowerCase()}'
              : 'stream.state.liveHint'.tr;
          accent = AppColors.accent;
          icon = Icons.podcasts;
          break;
        case RegiaAppState.scheduled:
          label = 'stream.state.scheduled'.tr.toUpperCase();
          hint  = 'stream.state.scheduledHint'.tr;
          accent = AppColors.autoDj;
          icon = Icons.schedule;
          break;
        case RegiaAppState.requested:
          label = 'stream.state.requested'.tr.toUpperCase();
          hint  = 'stream.state.requestedHint'.tr;
          accent = AppColors.autoDj;
          icon = Icons.hourglass_top;
          break;
        case RegiaAppState.offline:
          label = 'stream.state.offline'.tr.toUpperCase();
          hint  = 'stream.state.offlineHint'.tr;
          accent = AppColors.text3;
          icon = Icons.cloud_off;
          break;
        case RegiaAppState.error:
          label = 'stream.state.error'.tr.toUpperCase();
          hint  = controller.localError.value ?? 'stream.state.error'.tr;
          accent = AppColors.accent;
          icon = Icons.error_outline;
          break;
        case RegiaAppState.idle:
        case RegiaAppState.unknown:
          label = 'stream.status.ready'.tr;
          hint  = 'stream.subtitle'.tr;
          accent = AppColors.text2;
          icon = Icons.radio;
          break;
      }

      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(child: RkStatusChip(text: label, active: isLive)),
        ]),
        const SizedBox(height: 12),
        Text(hint,
          style: const TextStyle(fontSize: 13, color: AppColors.text2, height: 1.4)),
        if (isWaiting) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.autoDj.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.autoDj.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, size: 16, color: AppColors.autoDj),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'stream.confirm.queued'.tr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.autoDj),
              )),
            ]),
          ),
        ],
      ]));
    });
  }

  // ── FORM: URL + titolo + start mode (essenziale) ────────────────
  Widget _form() {
    return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('stream.sourceTitle'.tr,
        style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
      const SizedBox(height: 12),
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
    ]));
  }

  // ── ACTION BUTTON: Lancia o Stop ────────────────────────────────
  Widget _actionButton() {
    return Obx(() {
      final st = controller.appState;
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
    });
  }
}

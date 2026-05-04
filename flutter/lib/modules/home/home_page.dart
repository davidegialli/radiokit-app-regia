import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/status_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/regia_status.dart';
import '../../shared/widgets/app_shell.dart' show shellTabIndex;
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_card.dart';
import '../../shared/widgets/rk_status_chip.dart';
import 'sdl_events_controller.dart';

/// Home / Dashboard — single-glance overview della radio.
/// Tutti i dati vengono dal StatusService condiviso (polling /status ogni 4s).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(
        title: 'tab.home'.tr,
        eyebrow: 'header.regia'.tr,
        actions: [
          HeaderIconButton(icon: Icons.notifications_none, onTap: () => Get.toNamed(AppRoutes.push), dot: true),
          HeaderIconButton(icon: Icons.person_outline,     onTap: () => Get.toNamed(AppRoutes.account)),
        ],
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
            _StatusHero(),
            SizedBox(height: 14),
            _NowPlayingCard(),
            SizedBox(height: 14),
            _KpiGrid(),
            SizedBox(height: 14),
            _UpcomingEventsCard(),
            SizedBox(height: 14),
            _QuickActions(),
          ]),
        ),
      ),
    ]);
  }
}

// ─── HERO: focus su titolo della radio + alert solo se reale problema ──
class _StatusHero extends StatelessWidget {
  const _StatusHero();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = StatusService.to.status.value;
      final isLive = s.appState == RegiaAppState.live;
      final problem = s.appState == RegiaAppState.offline
                   || s.appState == RegiaAppState.error;

      // Banner d'allarme rosso se c'e' un problema reale (offline persistente
      // o errore). Histeresi gestita lato StatusService.
      if (problem) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.warn.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warn.withOpacity(0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warn, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                s.appState == RegiaAppState.offline
                    ? 'home.bridgeOffline'.tr
                    : 'stream.state.error'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              const SizedBox(height: 2),
              Text('stream.state.offlineHint'.tr,
                style: const TextStyle(fontSize: 12, color: AppColors.text3, height: 1.4)),
            ])),
          ]),
        );
      }

      // Caso normale: mostra IN ONDA se live, altrimenti niente chrome di stato.
      // Il NowPlaying card sotto fa il resto.
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isLive
              ? RadialGradient(
                  center: const Alignment(0, -1), radius: 1.2,
                  colors: [AppColors.accent.withOpacity(0.18), AppColors.surface, AppColors.bgElev],
                  stops: const [0, 0.55, 1],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppColors.surface, AppColors.bgElev]),
          border: Border.all(color: isLive ? AppColors.accent.withOpacity(0.4) : AppColors.hairlineSoft),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isLive) ...[
            RkStatusChip(text: 'home.statusOnAir'.tr, active: true),
            const SizedBox(height: 14),
          ],
          Text(
            isLive ? 'home.statusOnAir'.tr : 'app.name'.tr,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Text(
            isLive ? 'stream.state.liveHint'.tr : ' ',
            style: const TextStyle(fontSize: 12, color: AppColors.text3, height: 1.4),
          ),
        ]),
      );
    });
  }
}

// ─── Now playing real-time ──────────────────────────────────
class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final np = StatusService.to.status.value.nowPlaying;
      final has = np != null && !np.isEmpty;
      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('home.nowPlaying'.tr,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        if (!has)
          Text('home.noTrack'.tr, style: const TextStyle(fontSize: 14, color: AppColors.text3))
        else ...[
          Text(np.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.1)),
          const SizedBox(height: 2),
          Text(np.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.text3)),
        ],
      ]));
    });
  }
}

// ─── KPI Grid: 4 mini-tile ──────────────────────────────────
class _KpiGrid extends StatelessWidget {
  const _KpiGrid();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = StatusService.to.status.value;
      final svc = StatusService.to;
      final listeners = s.listeners;
      final peak = svc.listenerPeak;
      final trend = svc.listenerTrend;

      String trendStr = 'home.dataMissing'.tr;
      Color trendColor = AppColors.text3;
      if (trend != null) {
        if (trend > 0)      { trendStr = '↑'; trendColor = AppColors.autoDj; }
        else if (trend < 0) { trendStr = '↓'; trendColor = AppColors.warn; }
        else                { trendStr = '→'; trendColor = AppColors.text2; }
      }

      // Niente KPI Bridge: alarm-only banner gestisce il caso problematico.
      return Row(children: [
        Expanded(child: _Kpi(label: 'home.kpiListeners'.tr, value: listeners?.toString() ?? '—')),
        const SizedBox(width: 8),
        Expanded(child: _Kpi(label: 'home.kpiPeak'.tr,      value: peak?.toString() ?? '—')),
        const SizedBox(width: 8),
        Expanded(child: _Kpi(label: 'home.kpiTrend'.tr,     value: trendStr, valueColor: trendColor)),
      ]);
    });
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Kpi({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(children: [
        Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Text(value, textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'GeistMono', fontSize: 18, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.text, letterSpacing: -0.1)),
      ]),
    );
  }
}

// ─── Prossime dirette (da .sdl scheduler RadioBOSS) ──────────
class _UpcomingEventsCard extends StatelessWidget {
  const _UpcomingEventsCard();

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => SdlEventsController(), fenix: true);
    return Obx(() {
      final c = SdlEventsController.to;
      if (c.events.isEmpty && !c.loading.value) {
        return const SizedBox.shrink();
      }
      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('home.upcoming'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
          if (c.loading.value)
            const SizedBox(width: 10, height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.text3)),
        ]),
        const SizedBox(height: 10),
        for (var i = 0; i < c.events.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.hairlineSoft),
          _EventRow(event: c.events[i]),
        ],
      ]));
    });
  }
}

class _EventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final time = (event['time'] ?? '').toString();
    final title = (event['title'] ?? '').toString();
    final isLive = event['is_live'] == true;
    final imm = event['imm'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 42,
          child: Text(time,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent))),
        const SizedBox(width: 10),
        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text))),
        if (isLive) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('LIVE',
              style: TextStyle(fontFamily: 'GeistMono', fontSize: 8, color: AppColors.accent, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          ),
        ],
        if (imm) ...[
          const SizedBox(width: 4),
          const Icon(Icons.flash_on, size: 11, color: AppColors.warn),
        ],
      ]),
    );
  }
}

// ─── Quick actions ──────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => shellTabIndex.value = 2, // Stream tab
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.podcasts, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('home.quickGoLive'.tr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
            const SizedBox(height: 2),
            Text('home.quickGoLiveSub'.tr,
              style: const TextStyle(fontSize: 11, color: AppColors.text3)),
          ])),
          const Icon(Icons.arrow_forward_ios, color: AppColors.text3, size: 14),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/status_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_card.dart';
import 'listeners_controller.dart';

/// Tab Streaming — versione minimal.
/// Per la radio interessa UN solo numero: quante persone stanno ascoltando
/// in questo momento (somma deduplicata di tutti gli stream pubblici).
/// Niente lista mount individuali, niente dettagli tecnici.
class ListenersPage extends StatelessWidget {
  const ListenersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'tab.listeners'.tr, eyebrow: 'STATISTICHE ASCOLTI'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
            _AggregateKpiCard(),
            SizedBox(height: 14),
            _HistoryCard(),
          ]),
        ),
      ),
    ]);
  }
}

// ─── KPI principale: numero grande + peak ─────────────────────
class _AggregateKpiCard extends StatelessWidget {
  const _AggregateKpiCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = StatusService.to.status.value;
      final svc = StatusService.to;
      // Totale ascolti REALE (somma deduplicata via API stats_streams).
      // Fallback al listener del bridge se API VPS non risponde.
      final fromApi = ListenersController.to.totalListeners.value;
      final n = fromApi ?? s.listeners;
      final peak = svc.listenerPeak;
      final age = s.bridgeAgeSec;
      final loading = ListenersController.to.loading.value;

      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('listeners.aggregate'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
          GestureDetector(
            onTap: loading ? null : ListenersController.to.loadStreams,
            child: Text(loading ? '…' : '↻',
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 14, color: AppColors.text3)),
          ),
        ]),
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(n?.toString() ?? '—',
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 64, fontWeight: FontWeight.w600, color: AppColors.accent, letterSpacing: -2.0, height: 1.0)),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('home.kpiListeners'.tr.toLowerCase(),
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 11, color: AppColors.text3, letterSpacing: 0.5)),
          ),
          const Spacer(),
          if (peak != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('listeners.peak'.tr,
                  style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 1.0)),
                const SizedBox(height: 2),
                Text(peak.toString(),
                  style: const TextStyle(fontFamily: 'GeistMono', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text2)),
              ]),
            ),
        ]),
        if (age != null && age >= 0) ...[
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.hairlineSoft),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: age <= 30 ? AppColors.autoDj : AppColors.text4,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'listeners.upd'.tr.replaceAll('@sec', age.toString()),
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text4, letterSpacing: 0.5),
            ),
          ]),
        ],
      ]));
    });
  }
}

// ─── History card (sparkline aggregato totale) ──────────────────────
class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final h = StatusService.to.listenerHistory;
      if (h.isEmpty) {
        return RkCard(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('listeners.empty'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.text3))),
        ));
      }
      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('listeners.history'.tr.replaceAll('@n', h.length.toString()),
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: CustomPaint(
            size: Size.infinite,
            painter: _SparklinePainter(samples: h.toList()),
          ),
        ),
      ]));
    });
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> samples;
  _SparklinePainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    final maxV = samples.reduce((a, b) => a > b ? a : b).toDouble();
    final minV = samples.reduce((a, b) => a < b ? a : b).toDouble();
    final range = (maxV - minV).clamp(1.0, double.infinity);

    final stepX = samples.length > 1 ? size.width / (samples.length - 1) : size.width;

    final pathLine = Path();
    final pathFill = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = i * stepX;
      final y = size.height - ((samples[i] - minV) / range) * size.height;
      if (i == 0) {
        pathLine.moveTo(x, y);
        pathFill.moveTo(x, size.height);
        pathFill.lineTo(x, y);
      } else {
        pathLine.lineTo(x, y);
        pathFill.lineTo(x, y);
      }
    }
    pathFill.lineTo((samples.length - 1) * stepX, size.height);
    pathFill.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppColors.accent.withOpacity(0.35), AppColors.accent.withOpacity(0.0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(pathFill, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pathLine, linePaint);

    final lastX = (samples.length - 1) * stepX;
    final lastY = size.height - ((samples.last - minV) / range) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 3.0, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.samples.length != samples.length || old.samples.last != samples.last;
}

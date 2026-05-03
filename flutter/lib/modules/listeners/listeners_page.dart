import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/status_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_card.dart';

class ListenersPage extends StatelessWidget {
  const ListenersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'tab.listeners'.tr, eyebrow: 'STREAM · LIVE'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
            _MainKpiCard(),
            SizedBox(height: 14),
            _HistoryCard(),
          ]),
        ),
      ),
    ]);
  }
}

class _MainKpiCard extends StatelessWidget {
  const _MainKpiCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = StatusService.to.status.value;
      final svc = StatusService.to;
      final n = s.listeners;
      final peak = svc.listenerPeak;
      final age = s.bridgeAgeSec;

      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('listeners.subtitle'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
          if (age != null && age >= 0)
            Text('listeners.upd'.tr.replaceAll('@sec', age.toString()),
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text4)),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(n?.toString() ?? '—',
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 56, fontWeight: FontWeight.w600, color: AppColors.accent, letterSpacing: -1.5)),
          const SizedBox(width: 8),
          Text('home.kpiListeners'.tr.toLowerCase(),
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 11, color: AppColors.text3, letterSpacing: 0.5)),
          const Spacer(),
          if (peak != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('listeners.peak'.tr,
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 1.0)),
              const SizedBox(height: 2),
              Text(peak.toString(),
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text2)),
            ]),
        ]),
      ]));
    });
  }
}

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
          height: 100,
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

    // ultimo punto highlight
    final lastX = (samples.length - 1) * stepX;
    final lastY = size.height - ((samples.last - minV) / range) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 3.0, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.samples.length != samples.length || old.samples.last != samples.last;
}

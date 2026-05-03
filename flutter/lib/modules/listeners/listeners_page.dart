import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/status_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_card.dart';
import 'listeners_controller.dart';

/// Tab Streaming (ex Listeners) — dominio "Stream output":
/// - Aggregato listener corrente + peak + sparkline (da /status)
/// - Lista degli URL pubblici configurati nel Timer (tab Trasmissione)
/// - Stats per-stream coming soon (richiede bridge handler)
class ListenersPage extends StatelessWidget {
  const ListenersPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => ListenersController(), fenix: true);
    return Column(children: [
      PageHeader(title: 'tab.listeners'.tr, eyebrow: 'STREAM OUTPUT'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
            _AggregateKpiCard(),
            SizedBox(height: 14),
            _StreamsListCard(),
            SizedBox(height: 14),
            _HistoryCard(),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Aggregate KPI: numero grande + peak ─────────────────────
class _AggregateKpiCard extends StatelessWidget {
  const _AggregateKpiCard();

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
          Text('listeners.aggregate'.tr,
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

// ─── Lista stream output (da Timer tab Trasmissione) ─────────
class _StreamsListCard extends StatelessWidget {
  const _StreamsListCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = ListenersController.to;
      final list = c.streams;

      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('listeners.streams'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
          GestureDetector(
            onTap: c.loading.value ? null : c.loadStreams,
            child: Text(c.loading.value ? '…' : '↻',
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12, color: AppColors.text3)),
          ),
        ]),
        const SizedBox(height: 12),
        if (list.isEmpty && c.loading.value)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(child: Text('common.loading'.tr,
              style: const TextStyle(fontSize: 12, color: AppColors.text3))),
          )
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(children: [
              Text('listeners.streamsEmpty'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.text3)),
              const SizedBox(height: 6),
              Text('listeners.streamsEmptyHint'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text4)),
            ]),
          )
        else
          Column(children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.hairlineSoft),
              _StreamRow(stream: list[i]),
            ],
          ]),
        const SizedBox(height: 8),
        // Disclaimer per-stream stats coming soon
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: AppColors.surface2.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 14, color: AppColors.text3),
            const SizedBox(width: 8),
            Expanded(child: Text('listeners.statsSoon'.tr,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, height: 1.4))),
          ]),
        ),
      ]));
    });
  }
}

class _StreamRow extends StatelessWidget {
  final Map<String, dynamic> stream;
  const _StreamRow({required this.stream});

  @override
  Widget build(BuildContext context) {
    final url = (stream['url'] ?? '').toString();
    final label = (stream['label'] ?? url).toString();
    final type = (stream['type'] ?? 'auto').toString();
    final primary = stream['primary'] == true;

    final shortUrl = _formatUrl(url);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Star primary
        SizedBox(
          width: 18,
          child: primary
              ? const Icon(Icons.star, size: 14, color: AppColors.accent)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 6),
        // Label + URL
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 2),
          Text(shortUrl, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text3, letterSpacing: 0.05)),
        ])),
        const SizedBox(width: 10),
        // Type pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.hairlineSoft),
          ),
          child: Text(type.toUpperCase(),
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 8, color: AppColors.text2, letterSpacing: 0.6, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        // Placeholder count (sarà sostituito da count realtime quando bridge supporta listener_stats)
        const Text('—',
          style: TextStyle(fontFamily: 'GeistMono', fontSize: 11, color: AppColors.text4)),
      ]),
    );
  }

  String _formatUrl(String u) {
    try {
      final x = Uri.parse(u);
      return '${x.host}${x.path.length > 1 ? x.path : ''}';
    } catch (_) {
      return u;
    }
  }
}

// ─── History card (sparkline aggregato) ──────────────────────
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

    final lastX = (samples.length - 1) * stepX;
    final lastY = size.height - ((samples.last - minV) / range) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 3.0, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.samples.length != samples.length || old.samples.last != samples.last;
}

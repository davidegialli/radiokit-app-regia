import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/status_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_card.dart';
import 'listeners_controller.dart';

/// Tab Statistiche — versione completa.
/// Layout:
///  1. KPI grid (now / avg 24h / peak 24h / avg 7d / peak 7d)
///  2. Realtime chart (ultimi 60 min)
///  3. History switcher 24h / 7d / 30d + grafico aggregato
///  4. Per-stream breakdown (mount/codec/listeners/online)
class ListenersPage extends StatelessWidget {
  const ListenersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'tab.listeners'.tr, eyebrow: 'stats.eyebrow'.tr),
      Expanded(
        // ListView (anziché SingleChildScrollView+RefreshIndicator) si
        // auto-bounda all'altezza del contenuto: niente over-scroll
        // "grigio infinito" sotto l'ultima card.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 48),
          children: const [
            _SummaryGrid(),
            SizedBox(height: 14),
            _RealtimeCard(),
            SizedBox(height: 14),
            _HistoryCard(),
            SizedBox(height: 14),
            _PerStreamCard(),
          ],
        ),
      ),
    ]);
  }
}

// ─── KPI GRID ───────────────────────────────────────────────
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = ListenersController.to;
      final s = c.summary.value;
      final live = c.totalListeners.value ?? StatusService.to.status.value.listeners;
      final age = StatusService.to.status.value.bridgeAgeSec;

      return Column(children: [
        // Big "live now" card a tutta larghezza
        RkCard(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('stats.liveNow'.tr,
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
              GestureDetector(
                onTap: c.loading.value ? null : () => c.refreshAll(),
                child: Text(c.loading.value ? '…' : '↻',
                  style: const TextStyle(fontFamily: 'GeistMono', fontSize: 14, color: AppColors.text3)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(live?.toString() ?? '—',
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 64, fontWeight: FontWeight.w600, color: AppColors.accent, letterSpacing: -2.0, height: 1.0)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('stats.listeners'.tr,
                  style: const TextStyle(fontFamily: 'GeistMono', fontSize: 11, color: AppColors.text3, letterSpacing: 0.5)),
              ),
              const Spacer(),
              if (age != null && age >= 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: age <= 30 ? AppColors.autoDj : AppColors.text4,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${age}s',
                      style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, color: AppColors.text4)),
                  ]),
                ),
            ]),
          ]),
        )),
        const SizedBox(height: 10),
        // Mini-KPI 4 colonne
        if (s != null) Row(children: [
          Expanded(child: _MiniKpi(label: 'stats.avg24h'.tr, value: s['avg_24h']?.toString() ?? '—')),
          const SizedBox(width: 8),
          Expanded(child: _MiniKpi(label: 'stats.peak24h'.tr, value: s['peak_24h']?.toString() ?? '—', highlight: true)),
          const SizedBox(width: 8),
          Expanded(child: _MiniKpi(label: 'stats.avg7d'.tr, value: s['avg_7d']?.toString() ?? '—')),
          const SizedBox(width: 8),
          Expanded(child: _MiniKpi(label: 'stats.peak7d'.tr, value: s['peak_7d']?.toString() ?? '—', highlight: true)),
        ]),
      ]);
    });
  }
}

class _MiniKpi extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _MiniKpi({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return RkCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 8.5, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Text(value,
          style: TextStyle(
            fontFamily: 'GeistMono',
            fontSize: 20, fontWeight: FontWeight.w600,
            color: highlight ? AppColors.accent : AppColors.text2,
            letterSpacing: -0.6,
          )),
      ]),
    );
  }
}

// ─── REALTIME CHART (ultimi 60 min) ─────────────────────────
class _RealtimeCard extends StatelessWidget {
  const _RealtimeCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pts = ListenersController.to.realtimeSeries;
      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('stats.realtime'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
          Text('stats.last60min'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text4, letterSpacing: 0.6)),
        ]),
        const SizedBox(height: 12),
        if (pts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(child: Text('stats.noData'.tr,
              style: const TextStyle(fontSize: 11, color: AppColors.text3))),
          )
        else
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SparklinePainter(
                samples: pts.map((p) => (p['l'] as num?)?.toInt() ?? 0).toList(),
              ),
            ),
          ),
      ]));
    });
  }
}

// ─── HISTORY (24h / 7d / 30d) ───────────────────────────────
class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = ListenersController.to;
      // Aggrego i punti history per bucket (sommando i listeners di tutti gli stream
      // dello stesso istante temporale).
      final byBucket = <String, double>{};
      final byBucketPeak = <String, double>{};
      for (final p in c.historySeries) {
        final b = (p['bucket'] ?? '').toString();
        final avg = (p['avg_listeners'] as num?)?.toDouble() ?? 0;
        final peak = (p['peak_listeners'] as num?)?.toDouble() ?? 0;
        byBucket[b] = (byBucket[b] ?? 0) + avg;
        byBucketPeak[b] = (byBucketPeak[b] ?? 0) < peak ? peak : (byBucketPeak[b] ?? 0);
      }
      final buckets = byBucket.keys.toList()..sort();
      final values = buckets.map((b) => byBucket[b] ?? 0).toList();
      final peaks  = buckets.map((b) => byBucketPeak[b] ?? 0).toList();
      final isHourly = c.selectedRange.value != '30d';

      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('stats.history'.tr,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
          Row(children: [
            _RangeChip(value: '24h', label: '24H'),
            const SizedBox(width: 4),
            _RangeChip(value: '7d',  label: '7G'),
            const SizedBox(width: 4),
            _RangeChip(value: '30d', label: '30G'),
          ]),
        ]),
        const SizedBox(height: 14),
        if (c.historyLoading.value)
          const Padding(padding: EdgeInsets.symmetric(vertical: 38),
            child: Center(child: SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))))
        else if (values.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(child: Text('stats.noData'.tr,
              style: const TextStyle(fontSize: 11, color: AppColors.text3))))
        else ...[
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(
                values: values, peaks: peaks, hourly: isHourly,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _LegendDot(color: AppColors.accent, label: 'stats.avg'.tr),
            const SizedBox(width: 14),
            _LegendDot(color: AppColors.text4, label: 'stats.peak'.tr, line: true),
          ]),
        ],
      ]));
    });
  }
}

class _RangeChip extends StatelessWidget {
  final String value, label;
  const _RangeChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = ListenersController.to.selectedRange.value == value;
      return GestureDetector(
        onTap: () => ListenersController.to.setRange(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
            border: Border.all(color: active ? AppColors.accent : AppColors.hairlineSoft, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
            style: TextStyle(
              fontFamily: 'GeistMono', fontSize: 9.5, fontWeight: FontWeight.w600,
              color: active ? AppColors.accent : AppColors.text3, letterSpacing: 0.5,
            )),
        ),
      );
    });
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool line;
  const _LegendDot({required this.color, required this.label, this.line = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (line)
        Container(width: 10, height: 2, color: color)
      else
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9.5, color: AppColors.text3, letterSpacing: 0.5)),
    ]);
  }
}

// ─── PER-STREAM BREAKDOWN ───────────────────────────────────
class _PerStreamCard extends StatelessWidget {
  const _PerStreamCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final streams = ListenersController.to.streams;
      if (streams.isEmpty) {
        return RkCard(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(children: [
            Text('listeners.streamsEmpty'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text3)),
            const SizedBox(height: 6),
            Text('listeners.streamsEmptyHint'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.text4)),
          ]),
        ));
      }
      return RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('stats.perStream'.tr,
          style: const TextStyle(fontFamily: 'GeistMono', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1.2)),
        const SizedBox(height: 14),
        ...streams.map((s) => _StreamRow(stream: s)),
      ]));
    });
  }
}

class _StreamRow extends StatelessWidget {
  final Map<String, dynamic> stream;
  const _StreamRow({required this.stream});

  @override
  Widget build(BuildContext context) {
    final name = (stream['name'] ?? stream['label'] ?? stream['url'] ?? '').toString();
    final listeners = stream['listeners'] ?? 0;
    final online = stream['online'] == true;
    final isAlias = stream['is_alias'] == true;
    final type = (stream['type'] ?? '').toString().toUpperCase();
    final url = (stream['url'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: online ? AppColors.autoDj : AppColors.text4,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
            ),
            if (type.isNotEmpty) ...[
              const SizedBox(width: 6),
              _Badge(label: type, color: AppColors.text3),
            ],
            if (isAlias) ...[
              const SizedBox(width: 4),
              _Badge(label: 'ALIAS', color: AppColors.text4),
            ],
          ]),
          const SizedBox(height: 2),
          Text(url,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text4)),
        ])),
        const SizedBox(width: 8),
        Text(listeners.toString(),
          style: TextStyle(
            fontFamily: 'GeistMono', fontSize: 18, fontWeight: FontWeight.w600,
            color: online ? AppColors.accent : AppColors.text3, letterSpacing: -0.5,
          )),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.4), width: 0.6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label,
        style: TextStyle(
          fontFamily: 'GeistMono', fontSize: 7.5, fontWeight: FontWeight.w600,
          color: color, letterSpacing: 0.6,
        )),
    );
  }
}

// ─── PAINTERS ───────────────────────────────────────────────
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
      old.samples.length != samples.length ||
      (samples.isNotEmpty && old.samples.last != samples.last);
}

/// Bar chart con linea peak sovrapposta — usato per history 24h/7d/30d.
class _BarChartPainter extends CustomPainter {
  final List<double> values;  // medie
  final List<double> peaks;   // picchi (linea sovrapposta)
  final bool hourly;
  _BarChartPainter({required this.values, required this.peaks, required this.hourly});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = [...values, ...peaks].reduce((a, b) => a > b ? a : b);
    final scale = maxV > 0 ? size.height * 0.92 / maxV : 0.0;
    final barW = size.width / values.length;
    final padX = barW * 0.18;

    // Barre medie
    final barPaint = Paint()..color = AppColors.accent.withOpacity(0.55);
    for (var i = 0; i < values.length; i++) {
      final h = values[i] * scale;
      canvas.drawRect(
        Rect.fromLTWH(i * barW + padX, size.height - h, barW - padX * 2, h),
        barPaint,
      );
    }

    // Linea peak (tratteggiata in pratica = punteggiata con puntini)
    final peakPaint = Paint()
      ..color = AppColors.text3
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final peakPath = Path();
    for (var i = 0; i < peaks.length; i++) {
      final x = i * barW + barW / 2;
      final y = size.height - peaks[i] * scale;
      if (i == 0) peakPath.moveTo(x, y); else peakPath.lineTo(x, y);
    }
    canvas.drawPath(peakPath, peakPaint);

    // Asse Y semplice: label max in alto
    final tp = TextPainter(
      text: TextSpan(text: maxV.toInt().toString(),
        style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text4)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(2, 0));
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.values.length != values.length || old.hourly != hourly;
}

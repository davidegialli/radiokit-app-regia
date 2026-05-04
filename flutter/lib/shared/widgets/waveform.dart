import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Visualizzazione waveform pseudo-random animata.
///
/// Replica del design `components.jsx → Waveform`:
/// - N barre verticali (default 56, 80 in modalita' dense)
/// - Altezze deterministiche da formula sin/cos (no peak tracking reale)
/// - Wobble live: ogni 110ms le barre oscillano leggermente per dare
///   l'illusione di "respirare" col brano
/// - Barre prima del playhead (past) → colore accent, dopo → grigie chiare
///
/// `progress` 0..1 = posizione corrente del brano.
/// `live` = true → wobble attivo (animazione). false → statico.
class Waveform extends StatefulWidget {
  final double progress;
  final bool live;
  final bool dense;
  final double height;
  final Color color;
  final Color futureColor;

  const Waveform({
    super.key,
    required this.progress,
    this.live = true,
    this.dense = false,
    this.height = 56,
    this.color = AppColors.accent,
    this.futureColor = AppColors.text4,
  });

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> {
  Timer? _ticker;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _restartIfNeeded();
  }

  @override
  void didUpdateWidget(covariant Waveform old) {
    super.didUpdateWidget(old);
    if (old.live != widget.live) _restartIfNeeded();
  }

  void _restartIfNeeded() {
    _ticker?.cancel();
    if (widget.live) {
      _ticker = Timer.periodic(const Duration(milliseconds: 110), (_) {
        if (!mounted) return;
        setState(() => _tick++);
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          progress: widget.progress.clamp(0.0, 1.0),
          tick: _tick,
          live: widget.live,
          dense: widget.dense,
          color: widget.color,
          futureColor: widget.futureColor,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final int tick;
  final bool live;
  final bool dense;
  final Color color;
  final Color futureColor;

  _WaveformPainter({
    required this.progress,
    required this.tick,
    required this.live,
    required this.dense,
    required this.color,
    required this.futureColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = dense ? 80 : 56;
    final gap = 2.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final cx = size.height / 2;

    final playIdx = (barCount * progress).floor();

    final paintPast = Paint()..color = color;
    final paintFuture = Paint()..color = futureColor.withOpacity(0.5);

    for (var i = 0; i < barCount; i++) {
      // Altezza base deterministica (formula del design React originale)
      final a = math.sin(i * 0.32) * 0.35 +
                math.sin(i * 0.13) * 0.40 +
                math.sin(i * 0.81) * 0.20;
      final base = 0.5 + a * 0.5;

      // Wobble live: oscillazione leggera in funzione di (i + tick)
      final wobble = live
          ? math.sin((i + tick) * 0.7) * 0.08 + math.cos((i + tick) * 0.2) * 0.06
          : 0.0;
      final h = (base + wobble).clamp(0.08, 1.0);

      final barH = h * size.height;
      final x = i * (barWidth + gap);
      final rect = Rect.fromLTWH(x, cx - barH / 2, barWidth, barH);
      final paint = i < playIdx ? paintPast : paintFuture;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.tick != tick ||
      old.progress != progress ||
      old.live != live ||
      old.dense != dense ||
      old.color != color;
}

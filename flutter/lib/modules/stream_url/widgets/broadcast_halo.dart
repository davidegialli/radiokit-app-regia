import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/stream_launch.dart';

/// Disco circolare grande con anelli concentrici pulsanti.
/// Equivalente Flutter di `BroadcastHalo` del prototipo React.
class BroadcastHalo extends StatefulWidget {
  final bool streaming;
  final StreamHealth health;

  const BroadcastHalo({super.key, required this.streaming, required this.health});

  @override
  State<BroadcastHalo> createState() => _BroadcastHaloState();
}

class _BroadcastHaloState extends State<BroadcastHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const size = 132.0;
    final accent = AppColors.accent;

    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        if (widget.streaming) ...[
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = (_ctrl.value);
              return Opacity(
                opacity: 0.55 * (1 - t) * 0.7,
                child: Transform.scale(
                  scale: 1 + 0.30 * t,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 1.5),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = ((_ctrl.value + 0.3) % 1.0);
              return Opacity(
                opacity: 0.55 * (1 - t),
                child: Transform.scale(
                  scale: 1 + 0.20 * t,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 1.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ],

        // Disco solido
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.streaming
                ? RadialGradient(
                    center: const Alignment(-0.4, -0.5),
                    colors: [
                      accent.withRed(255).withGreen(140),
                      accent,
                      accent.withOpacity(0.7),
                    ],
                    stops: const [0, 0.7, 1],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.surface2, AppColors.surface],
                  ),
            border: widget.streaming ? null : Border.all(color: AppColors.hairline),
            boxShadow: widget.streaming
                ? [BoxShadow(color: accent.withOpacity(0.45), blurRadius: 32)]
                : null,
          ),
          child: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.podcasts, size: 42, color: Colors.white),
            if (widget.streaming && widget.health == StreamHealth.buffering)
              Positioned(
                bottom: -2, right: -2,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.warn,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgElev, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Text('!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.black)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

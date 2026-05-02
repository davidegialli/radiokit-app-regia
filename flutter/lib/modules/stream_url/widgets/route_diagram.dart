import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RouteHop extends StatefulWidget {
  final String label;
  final String sub;
  final IconData icon;
  final bool active;
  final bool last;

  const RouteHop({
    super.key,
    required this.label,
    required this.sub,
    required this.icon,
    this.active = false,
    this.last = false,
  });

  @override
  State<RouteHop> createState() => _RouteHopState();
}

class _RouteHopState extends State<RouteHop> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent;
    final active = widget.active;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: active ? accent.withOpacity(0.18) : AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? accent.withOpacity(0.4) : AppColors.hairlineSoft),
          ),
          child: Icon(widget.icon, size: 18, color: active ? accent : AppColors.text3),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
              const SizedBox(height: 1),
              Text(widget.sub,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 0.05)),
            ],
          ),
        ),
        if (active)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.55 + 0.45 * (1 - _ctrl.value)),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ]),
    );
  }
}

class RouteLine extends StatelessWidget {
  final bool active;
  const RouteLine({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: SizedBox(
        height: 18,
        child: Container(width: 1,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [AppColors.accent, AppColors.accent.withOpacity(0.3)])
                : null,
            color: active ? null : AppColors.hairline,
          ),
        ),
      ),
    );
  }
}

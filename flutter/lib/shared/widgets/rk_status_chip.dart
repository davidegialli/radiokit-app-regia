import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RkStatusChip extends StatefulWidget {
  final String text;
  final bool active;          // true = pulse + accent
  final Color? activeColor;

  const RkStatusChip({
    super.key,
    required this.text,
    this.active = false,
    this.activeColor,
  });

  @override
  State<RkStatusChip> createState() => _RkStatusChipState();
}

class _RkStatusChipState extends State<RkStatusChip> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.activeColor ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.active ? c : AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final v = widget.active ? (0.55 + 0.45 * (1 - _ctrl.value)) : 1.0;
              return Container(
                width: 5, height: 5,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: widget.active ? Colors.white.withOpacity(v) : AppColors.text3,
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'GeistMono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: widget.active ? Colors.white : AppColors.text3,
            ),
          ),
        ],
      ),
    );
  }
}

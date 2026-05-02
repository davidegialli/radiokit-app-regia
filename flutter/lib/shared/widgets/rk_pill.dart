import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RkPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final Color? bgColor;

  const RkPill({super.key, required this.text, this.icon, this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor ?? c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'GeistMono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

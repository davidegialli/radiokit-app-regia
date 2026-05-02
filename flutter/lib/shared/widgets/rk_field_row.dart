import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Riga "label sopra → input/widget sotto → hint mono".
class RkFieldRow extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const RkFieldRow({super.key, required this.label, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
        const SizedBox(height: 6),
        child,
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint!, style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 0.05)),
        ],
      ],
    );
  }
}

/// Riga "label sx → control dx" usata per impostazioni (toggle, segmented).
class RkSettingRow extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const RkSettingRow({super.key, required this.label, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(hint!, style: const TextStyle(fontFamily: 'GeistMono', fontSize: 9, color: AppColors.text3, letterSpacing: 0.05)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        child,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TelemTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool good;
  final bool warn;

  const TelemTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.good = false,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = good ? AppColors.autoDj : warn ? AppColors.warn : AppColors.text;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'GeistMono',
              fontSize: 9,
              color: AppColors.text3,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'GeistMono',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontFamily: 'GeistMono',
                    fontSize: 9,
                    color: AppColors.text3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RkSegOption<T> {
  final T value;
  final String label;
  const RkSegOption(this.value, this.label);
}

/// Segmented radio (es. Subito / Fine brano / Cross-fade).
class RkSegRadio<T> extends StatelessWidget {
  final T value;
  final List<RkSegOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool disabled;

  const RkSegRadio({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: IgnorePointer(
        ignoring: disabled,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.hairlineSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: options.map((o) {
              final selected = o.value == value;
              return GestureDetector(
                onTap: () => onChanged(o.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    o.label,
                    style: TextStyle(
                      fontFamily: 'GeistMono',
                      fontSize: 11,
                      letterSpacing: 0.05,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : AppColors.text2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

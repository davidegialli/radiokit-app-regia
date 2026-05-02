import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RkToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool disabled;

  const RkToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40, height: 22,
          decoration: BoxDecoration(
            color: value ? AppColors.accent : AppColors.surface2,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: value ? Colors.transparent : AppColors.hairline),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                top: 1, left: value ? 19 : 1,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1))],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
